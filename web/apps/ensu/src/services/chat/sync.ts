import { savedLocalUser } from "ente-accounts/services/accounts-db";
import {
    authenticatedRequestHeaders,
    ensureOk,
    HTTPError,
} from "ente-base/http";
import log from "ente-base/log";
import { apiOrigin, apiURL } from "ente-base/origins";
import { savedAuthToken } from "ente-base/token";
import { masterKeyFromSession } from "../session";
import { decryptAttachmentBytes, encryptAttachmentBytes } from "./attachments";
import { cachedLocalChatKey } from "./chatKey";
import {
    decryptChatField,
    decryptChatPayload,
    encryptChatField,
    encryptChatPayload,
} from "./crypto";
import { computeMd5Base64 } from "./md5";
import {
    attachmentBytesExists,
    getPendingDeletions,
    getSessionRecord,
    hardDeleteEntity,
    insertMessageFromRemote,
    listMessageRemoteMap,
    listMessagesForSessionSync,
    listSessionRemoteMap,
    listSessionsForSync,
    markAttachmentUploaded,
    markMessageDeletedAt,
    markMessageSynced,
    markSessionDeletedAt,
    markSessionSynced,
    readAttachmentBytes,
    upsertSessionRecord,
    writeAttachmentBytes,
    type ChatAttachment,
    type LocalMessageRecord,
    type LocalSessionRecord,
} from "./store";

const isTauriRuntime = () =>
    typeof window !== "undefined" &&
    ("__TAURI__" in window || "__TAURI_IPC__" in window);

type DiffCursor = {
    base_since_time: number;
    since_time: number;
    max_time: number;
    since_type: string;
    since_id: string;
};

const DEFAULT_CURSOR: DiffCursor = {
    base_since_time: 0,
    since_time: 0,
    max_time: 0,
    since_type: "sessions",
    since_id: "00000000-0000-0000-0000-000000000000",
};

const ZERO_UUID = "00000000-0000-0000-0000-000000000000";

const DEDUPE_WINDOW_US = 2_000_000;
const DIFF_PAGE_LIMIT = 500;
const RETRY_DELAYS_MS = [2000, 5000, 10000];

export class ChatSyncLimitError extends Error {
    code: string;

    constructor(code: string, message: string) {
        super(message);
        this.code = code;
        this.name = "ChatSyncLimitError";
    }
}

const sleep = (ms: number) =>
    new Promise<void>((resolve) => {
        setTimeout(resolve, ms);
    });

const extractErrorCode = (error: unknown) => {
    if (!error || typeof error !== "object") return undefined;
    const code = (error as { code?: unknown }).code;
    return typeof code === "string" ? code : undefined;
};

const normalizeUuid = (value?: string | null) => {
    if (!value) return undefined;
    const trimmed = value.trim();
    if (!trimmed || trimmed === ZERO_UUID) return undefined;
    return trimmed;
};

const decodeClientId = (metadata?: string | null) => {
    if (!metadata) return undefined;
    try {
        const parsed = JSON.parse(metadata) as { clientId?: unknown };
        if (typeof parsed.clientId === "string" && parsed.clientId.trim()) {
            return parsed.clientId;
        }
    } catch {
        return undefined;
    }
    return undefined;
};

const encodeClientMetadata = async (
    clientId: string,
    createdAt: number,
    chatKey: string,
) => {
    const payload: { clientId: string; createdAt?: string } = { clientId };
    if (createdAt > 0) {
        payload.createdAt = await encryptChatField(String(createdAt), chatKey);
    }
    return JSON.stringify(payload);
};

const extractErrorMessage = (error: unknown) => {
    if (!error || typeof error !== "object") return undefined;
    const message = (error as { message?: unknown }).message;
    return typeof message === "string" ? message : undefined;
};

const isRetryableError = (error: unknown) => {
    if (error instanceof ChatSyncLimitError) {
        return (
            error.code === "LLMCHAT_RATE_LIMIT_REACHED" ||
            error.code === "LLMCHAT_TEMPORARY_LIMIT"
        );
    }
    if (error instanceof HTTPError) {
        return error.res.status === 429 || error.res.status >= 500;
    }
    return error instanceof TypeError;
};

const withRetry = async (fn: () => Promise<void>) => {
    let attempt = 0;
    while (true) {
        try {
            await fn();
            return;
        } catch (error) {
            if (!isRetryableError(error) || attempt >= RETRY_DELAYS_MS.length) {
                throw error;
            }
            const delay = RETRY_DELAYS_MS[attempt] ?? 0;
            attempt += 1;
            await sleep(delay);
        }
    }
};

let syncPromise: Promise<void> | null = null;

const syncChatNative = async (chatKey: string, token: string) => {
    const masterKey = await masterKeyFromSession();
    if (!masterKey) return;

    const { invoke } = await import("@tauri-apps/api/tauri");
    const { getName, getVersion } = await import("@tauri-apps/api/app");

    const [baseUrl, clientPackage, clientVersion] = await Promise.all([
        apiOrigin(),
        getName(),
        getVersion(),
    ]);

    try {
        await invoke("chat_sync", {
            keyB64: chatKey,
            baseUrl,
            authToken: token,
            masterKeyB64: masterKey,
            userAgent: "EnteTauri",
            clientPackage,
            clientVersion,
        });
    } catch (error) {
        const code = extractErrorCode(error);
        if (
            code === "LLMCHAT_RATE_LIMIT_REACHED" ||
            code === "LLMCHAT_TEMPORARY_LIMIT"
        ) {
            throw new ChatSyncLimitError(
                code,
                extractErrorMessage(error) ?? "Sync limit reached",
            );
        }
        throw error;
    }
};

export const syncChat = async (chatKey: string) => {
    if (!chatKey) return;
    const token = await savedAuthToken();
    if (!token) return;

    if (syncPromise) {
        return syncPromise;
    }

    syncPromise = (async () => {
        try {
            if (isTauriRuntime()) {
                await withRetry(() => syncChatNative(chatKey, token));
                return;
            }

            await withRetry(async () => {
                await pullChat(chatKey);
                await pushChat(chatKey);
            });
        } finally {
            syncPromise = null;
        }
    })();

    return syncPromise;
};

export const downloadAttachment = async (attachmentId: string) => {
    if (!isTauriRuntime()) return;

    const token = await savedAuthToken();
    if (!token) return;

    if (await attachmentBytesExists(attachmentId)) return;

    const res = await fetch(
        await apiURL(`/llmchat/chat/attachment/${attachmentId}`),
        { headers: await authenticatedRequestHeaders(), redirect: "follow" },
    );
    ensureOk(res);
    const buffer = await res.arrayBuffer();
    await writeAttachmentBytes(attachmentId, new Uint8Array(buffer));
};

const cursorStorageKey = () => {
    if (typeof localStorage === "undefined") {
        return "ensu.chat.sync.cursor.anon";
    }
    const userId = savedLocalUser()?.id ?? "anon";
    return `ensu.chat.sync.cursor.${userId}`;
};

const loadCursor = (): DiffCursor => {
    if (typeof localStorage === "undefined") return { ...DEFAULT_CURSOR };
    const raw = localStorage.getItem(cursorStorageKey());
    if (!raw) return { ...DEFAULT_CURSOR };
    try {
        const parsed = JSON.parse(raw) as Partial<DiffCursor>;
        return { ...DEFAULT_CURSOR, ...parsed };
    } catch (error) {
        log.error("Failed to parse chat sync cursor", error);
        return { ...DEFAULT_CURSOR };
    }
};

const saveCursor = (cursor: DiffCursor) => {
    if (typeof localStorage === "undefined") return;
    localStorage.setItem(cursorStorageKey(), JSON.stringify(cursor));
};

const pullChat = async (chatKey: string) => {
    let cursor = loadCursor();
    let previousCursor = "";
    let iterations = 0;

    while (iterations < 200) {
        const response = await fetchDiff(cursor);
        await applyDiff(response, chatKey);

        const nextCursor = normalizeCursor(response);
        saveCursor(nextCursor);
        const serialized = JSON.stringify(nextCursor);
        if (serialized === previousCursor) {
            log.warn("Chat sync cursor stalled; stopping pull loop");
            break;
        }

        const completed =
            nextCursor.since_type === "sessions" &&
            nextCursor.since_time === nextCursor.base_since_time &&
            nextCursor.since_time === nextCursor.max_time;
        if (completed) break;

        previousCursor = serialized;
        cursor = nextCursor;
        iterations += 1;
    }
};

const pushChat = async (chatKey: string) => {
    await pushDeletions(chatKey);

    const sessions = await listSessionsForSync(chatKey);
    for (const session of sessions) {
        if (session.deletedAt) continue;

        try {
            const messages = await listMessagesForSessionSync(
                session.sessionUuid,
                chatKey,
            );

            await reencryptPendingAttachments(messages, chatKey);
            try {
                await uploadPendingAttachments(messages, chatKey);
            } catch (error) {
                if (error instanceof ChatSyncLimitError) {
                    log.warn(
                        `Attachment limit reached for session ${session.sessionUuid}; some messages might be blocked`,
                    );
                } else {
                    throw error;
                }
            }

            const refreshedMessages = await listMessagesForSessionSync(
                session.sessionUuid,
                chatKey,
            );

            const blocked = buildBlockedMessages(refreshedMessages);
            const ordered = orderMessagesForSync(refreshedMessages).filter(
                (message) =>
                    !message.deletedAt && !blocked.has(message.messageUuid),
            );

            const sessionRemoteId = await upsertRemoteSession(session, chatKey);
            const remoteIdsByLocal = new Map<string, string>();
            for (const message of refreshedMessages) {
                if (message.remoteId) {
                    remoteIdsByLocal.set(message.messageUuid, message.remoteId);
                }
            }

            let sessionError: Error | null = null;
            for (const message of ordered) {
                try {
                    const parentRemoteId = message.parentMessageUuid
                        ? remoteIdsByLocal.get(message.parentMessageUuid)
                        : undefined;
                    if (message.parentMessageUuid && !parentRemoteId) {
                        sessionError = new Error(
                            `Missing parent remote id for ${message.messageUuid}`,
                        );
                        break;
                    }
                    const messageRemoteId = await upsertRemoteMessage(
                        message,
                        sessionRemoteId,
                        parentRemoteId,
                        chatKey,
                    );
                    if (messageRemoteId) {
                        remoteIdsByLocal.set(
                            message.messageUuid,
                            messageRemoteId,
                        );
                        await markMessageSynced(
                            message.messageUuid,
                            messageRemoteId,
                        );
                    }
                } catch (error) {
                    if (error instanceof ChatSyncLimitError) {
                        log.error(
                            `Message-specific limit reached for ${message.messageUuid}`,
                            error,
                        );
                        sessionError = error as Error;
                        // For limit errors, we stop pushing further messages in this session
                        // to maintain causal consistency on the server.
                        break;
                    }
                    throw error;
                }
            }

            if (blocked.size === 0 && !sessionError) {
                await markSessionSynced(
                    session.sessionUuid,
                    sessionRemoteId,
                    chatKey,
                );
            } else {
                const existing = await getSessionRecord(
                    session.sessionUuid,
                    chatKey,
                );
                if (existing) {
                    await upsertSessionRecord(
                        {
                            ...existing,
                            remoteId: existing.remoteId ?? sessionRemoteId,
                            needsSync: true,
                        },
                        chatKey,
                    );
                }
            }
        } catch (error) {
            log.error(`Failed to push session ${session.sessionUuid}`, error);
            // If it's a transient limit, we stop the whole push to respect backoff
            if (
                error instanceof ChatSyncLimitError &&
                isRetryableError(error)
            ) {
                throw error;
            }
            // Otherwise we continue with other sessions
        }
    }
};

const pushDeletions = async (chatKey: string) => {
    const deletions = await getPendingDeletions(chatKey);
    for (const deletion of deletions) {
        const remoteId = normalizeUuid(deletion.remoteId);
        if (!remoteId) {
            await hardDeleteEntity(deletion, chatKey);
            continue;
        }
        const endpoint =
            deletion.type === "session"
                ? `/llmchat/chat/session?id=${encodeURIComponent(remoteId)}`
                : `/llmchat/chat/message?id=${encodeURIComponent(remoteId)}`;
        const res = await fetch(await apiURL(endpoint), {
            method: "DELETE",
            headers: await authenticatedRequestHeaders(),
        });
        if (res.ok || res.status === 404) {
            await hardDeleteEntity(deletion, chatKey);
            continue;
        }
        ensureOk(res);
    }
};

const fetchDiff = async (cursor: DiffCursor) => {
    const query = new URLSearchParams({
        sinceTime: String(cursor.since_time),
        sinceType: cursor.since_type,
        sinceId: cursor.since_id,
        limit: String(DIFF_PAGE_LIMIT),
    });
    const res = await fetch(
        await apiURL(`/llmchat/chat/diff?${query.toString()}`),
        { headers: await authenticatedRequestHeaders() },
    );
    await handleChatLimitError(res);
    ensureOk(res);
    return (await res.json()) as DiffResponse;
};

const normalizeCursor = (response: DiffResponse): DiffCursor => {
    if (response.cursor) {
        const baseSinceTime =
            response.cursor.base_since_time ??
            (response.cursor as { baseSinceTime?: number }).baseSinceTime ??
            0;
        const sinceTime =
            response.cursor.since_time ??
            (response.cursor as { sinceTime?: number }).sinceTime ??
            baseSinceTime;
        const maxTime =
            response.cursor.max_time ??
            (response.cursor as { maxTime?: number }).maxTime ??
            sinceTime;
        const sinceType =
            response.cursor.since_type ??
            (response.cursor as { sinceType?: string }).sinceType ??
            "sessions";
        const sinceId =
            response.cursor.since_id ??
            (response.cursor as { sinceId?: string }).sinceId ??
            "00000000-0000-0000-0000-000000000000";
        return {
            base_since_time: baseSinceTime,
            since_time: sinceTime,
            max_time: maxTime,
            since_type: sinceType,
            since_id: sinceId,
        };
    }

    const timestamp = response.timestamp ?? 0;
    return {
        base_since_time: timestamp,
        since_time: timestamp,
        max_time: timestamp,
        since_type: "sessions",
        since_id: "00000000-0000-0000-0000-000000000000",
    };
};

const handleChatLimitError = async (res: Response) => {
    if (res.ok) return;
    try {
        const payload = (await res.clone().json()) as {
            code?: string;
            message?: string;
        };
        const code = payload.code;
        if (code && code.startsWith("LLMCHAT_")) {
            throw new ChatSyncLimitError(
                code,
                chatLimitMessage(code, payload.message),
            );
        }
    } catch (error) {
        if (error instanceof ChatSyncLimitError) {
            throw error;
        }
    }
};

const chatLimitMessage = (code: string, fallback?: string) => {
    switch (code) {
        case "LLMCHAT_MESSAGE_LIMIT_REACHED":
            return "Message limit reached. Please shorten the message.";
        case "LLMCHAT_ATTACHMENT_LIMIT_REACHED":
            return "Attachment limit reached. Please remove some attachments.";
        case "LLMCHAT_PAYLOAD_TOO_LARGE":
            return "Payload too large. Please reduce message or attachment size.";
        case "LLMCHAT_RATE_LIMIT_REACHED":
            return "Rate limit reached. Please try again later.";
        default:
            return fallback ?? "Sync failed due to server limits.";
    }
};

const applyDiff = async (response: DiffResponse, chatKey: string) => {
    const sessionRemoteMap = await listSessionRemoteMap();

    const sessions = response.sessions ?? [];
    for (const session of sessions) {
        const remoteSessionId = normalizeUuid(
            session.session_uuid ?? session.sessionUuid,
        );
        if (!remoteSessionId) continue;

        const clientId = decodeClientId(
            session.client_metadata ?? session.clientMetadata,
        );
        const existingByClient = clientId
            ? await getSessionRecord(clientId, chatKey)
            : null;
        const localSessionId =
            existingByClient?.sessionUuid ??
            sessionRemoteMap.get(remoteSessionId) ??
            remoteSessionId;

        if (session.is_deleted) {
            const deletedAt =
                session.updated_at ?? session.created_at ?? Date.now() * 1000;
            await markSessionDeletedAt(localSessionId, deletedAt, chatKey);
            sessionRemoteMap.set(remoteSessionId, localSessionId);
            continue;
        }

        let decrypted: { title?: string } = {};
        try {
            decrypted = (await decryptChatPayload(
                {
                    encryptedData:
                        session.encrypted_data ?? session.encryptedData ?? "",
                    header: session.header,
                },
                chatKey,
            )) as { title?: string };
        } catch (error) {
            log.error(
                `Failed to decrypt session ${remoteSessionId}; skipping`,
                error,
            );
            continue;
        }

        const existing = await getSessionRecord(localSessionId, chatKey);
        const needsSync = existing?.needsSync ?? false;
        const createdAt = Math.min(
            existing?.createdAt ?? session.created_at ?? 0,
            session.created_at ?? existing?.createdAt ?? 0,
        );
        const updatedAt = Math.max(
            existing?.updatedAt ?? session.updated_at ?? 0,
            session.updated_at ?? existing?.updatedAt ?? 0,
        );
        const remoteTitle = decrypted.title ?? "New chat";
        const title = needsSync
            ? (existing?.title ?? remoteTitle)
            : remoteTitle;

        await upsertSessionRecord(
            {
                sessionUuid: localSessionId,
                title,
                createdAt,
                updatedAt,
                remoteId: remoteSessionId,
                needsSync,
                deletedAt: existing?.deletedAt ?? null,
            },
            chatKey,
        );
        sessionRemoteMap.set(remoteSessionId, localSessionId);
    }

    const messages = response.messages ?? [];
    const grouped = new Map<string, RemoteMessage[]>();
    for (const message of messages) {
        const remoteSessionId = normalizeUuid(
            message.session_uuid ?? message.sessionUuid,
        );
        if (!remoteSessionId) continue;
        const list = grouped.get(remoteSessionId) ?? [];
        list.push(message);
        grouped.set(remoteSessionId, list);
    }

    for (const [remoteSessionId, remoteMessages] of grouped.entries()) {
        const localSessionId =
            sessionRemoteMap.get(remoteSessionId) ?? remoteSessionId;
        const localMessages = await listMessagesForSessionSync(
            localSessionId,
            chatKey,
            { includeDeleted: true },
        );
        const localById = new Map(
            localMessages.map((msg) => [msg.messageUuid, msg]),
        );
        const localByRemoteId = new Map(
            localMessages
                .filter((msg) => msg.remoteId)
                .map((msg) => [msg.remoteId as string, msg]),
        );
        const remoteToLocal = new Map<string, string>();
        for (const msg of localMessages) {
            if (msg.remoteId) {
                remoteToLocal.set(msg.remoteId, msg.messageUuid);
            } else {
                remoteToLocal.set(msg.messageUuid, msg.messageUuid);
            }
        }
        const signatureMap = buildSignatureMap(localMessages);

        for (const remote of remoteMessages) {
            const remoteMessageId = normalizeUuid(
                remote.message_uuid ?? remote.messageUuid,
            );
            if (!remoteMessageId) continue;

            const clientId = decodeClientId(
                remote.client_metadata ?? remote.clientMetadata,
            );
            const existingByClient = clientId ? localById.get(clientId) : null;
            const existingByRemote =
                localByRemoteId.get(remoteMessageId) ?? null;
            const localMessageId =
                existingByClient?.messageUuid ??
                existingByRemote?.messageUuid ??
                remoteMessageId;

            const parentRemoteId = normalizeUuid(
                remote.parent_message_uuid ?? remote.parentMessageUuid,
            );
            const parentLocalId = parentRemoteId
                ? (remoteToLocal.get(parentRemoteId) ?? parentRemoteId)
                : null;

            if (remote.is_deleted) {
                const deletedAt =
                    remote.updated_at ?? remote.created_at ?? Date.now() * 1000;
                await markMessageDeletedAt(localMessageId, deletedAt, chatKey);
                continue;
            }

            const existing = localById.get(localMessageId);
            if (existing) {
                if (remoteMessageId && existing.remoteId !== remoteMessageId) {
                    await markMessageSynced(localMessageId, remoteMessageId);
                    existing.remoteId = remoteMessageId;
                    localByRemoteId.set(remoteMessageId, existing);
                    remoteToLocal.set(remoteMessageId, localMessageId);
                }
                for (const attachment of remote.attachments ?? []) {
                    try {
                        await markAttachmentUploaded(
                            localMessageId,
                            attachment.id,
                            chatKey,
                        );
                    } catch (error) {
                        log.error(
                            "Failed to reconcile attachment state",
                            error,
                        );
                    }
                }
                continue;
            }

            const payload = (await decryptChatPayload(
                {
                    encryptedData:
                        remote.encrypted_data ?? remote.encryptedData ?? "",
                    header: remote.header,
                },
                chatKey,
            )) as { text?: string };
            const text = payload.text ?? "";

            const attachments = await normalizeRemoteAttachments(
                remote.attachments ?? [],
                chatKey,
                remote.created_at ?? 0,
            );

            const sender = normalizeSender(remote.sender);
            const signature = buildSignature(sender, text, attachments);
            const possible = signatureMap.get(signature) ?? [];
            const isDuplicate = possible.some(
                (candidate) =>
                    Math.abs(candidate.createdAt - (remote.created_at ?? 0)) <=
                    DEDUPE_WINDOW_US,
            );

            if (isDuplicate) continue;

            const localMessage: LocalMessageRecord = {
                messageUuid: localMessageId,
                sessionUuid: localSessionId,
                parentMessageUuid: parentLocalId,
                sender,
                text,
                createdAt: remote.created_at ?? 0,
                attachments,
                remoteId: remoteMessageId,
                deletedAt: null,
            };

            await insertMessageFromRemote(localMessage, chatKey);
            const updatedList = signatureMap.get(signature) ?? [];
            updatedList.push(localMessage);
            signatureMap.set(signature, updatedList);

            localById.set(localMessageId, localMessage);
            localByRemoteId.set(remoteMessageId, localMessage);
            remoteToLocal.set(remoteMessageId, localMessageId);
        }
    }

    const tombstones = response.tombstones;
    if (tombstones) {
        for (const session of tombstones.sessions ?? []) {
            const remoteSessionId = normalizeUuid(
                session.session_uuid ?? session.sessionUuid,
            );
            if (!remoteSessionId) continue;
            const deletedAt = session.deleted_at ?? session.deletedAt ?? 0;
            const localSessionId =
                sessionRemoteMap.get(remoteSessionId) ?? remoteSessionId;
            await markSessionDeletedAt(localSessionId, deletedAt, chatKey);
        }

        const messageTombstones = tombstones.messages ?? [];
        if (messageTombstones.length) {
            const messageRemoteMap = await listMessageRemoteMap();
            for (const message of messageTombstones) {
                const remoteMessageId = normalizeUuid(
                    message.message_uuid ?? message.messageUuid,
                );
                if (!remoteMessageId) continue;
                const deletedAt = message.deleted_at ?? message.deletedAt ?? 0;
                const localMessageId =
                    messageRemoteMap.get(remoteMessageId) ?? remoteMessageId;
                await markMessageDeletedAt(localMessageId, deletedAt, chatKey);
            }
        }
    }
};

const normalizeRemoteAttachments = async (
    attachments: RemoteAttachment[],
    chatKey: string,
    uploadedAt: number,
): Promise<ChatAttachment[]> => {
    if (!attachments.length || !isTauriRuntime()) return [];
    return Promise.all(
        attachments.map(async (attachment) => {
            const encryptedName =
                attachment.encrypted_name ?? attachment.encryptedName ?? "";
            let name = "Attachment";
            if (encryptedName) {
                try {
                    name = await decryptChatField(encryptedName, chatKey);
                } catch (error) {
                    log.error("Failed to decrypt attachment name", error);
                }
            }
            return {
                id: attachment.id,
                kind: "document",
                name,
                size: attachment.size,
                encryptedName,
                uploadedAt,
            } satisfies ChatAttachment;
        }),
    );
};

const reencryptPendingAttachments = async (
    messages: LocalMessageRecord[],
    chatKey: string,
) => {
    const localKey = cachedLocalChatKey();
    if (!localKey || localKey === chatKey) return;

    const seen = new Set<string>();
    for (const message of messages) {
        for (const attachment of message.attachments ?? []) {
            if (seen.has(attachment.id)) continue;
            seen.add(attachment.id);

            try {
                const bytes = await readAttachmentBytes(attachment.id);
                try {
                    await decryptAttachmentBytes(
                        bytes,
                        chatKey,
                        message.sessionUuid,
                    );
                    continue;
                } catch {
                    // fall through to local key
                }

                const plaintext = await decryptAttachmentBytes(
                    bytes,
                    localKey,
                    message.sessionUuid,
                );
                const reencrypted = await encryptAttachmentBytes(
                    plaintext,
                    chatKey,
                    message.sessionUuid,
                );
                await writeAttachmentBytes(attachment.id, reencrypted);
            } catch (error) {
                log.error("Failed to re-encrypt attachment", error);
            }
        }
    }
};

const uploadPendingAttachments = async (
    messages: LocalMessageRecord[],
    chatKey: string,
) => {
    const pending = new Map<
        string,
        {
            sessionUuid: string;
            attachment: ChatAttachment;
            messageUuids: Set<string>;
        }
    >();

    for (const message of messages) {
        if (message.deletedAt) continue;
        for (const attachment of message.attachments ?? []) {
            if (attachment.uploadedAt) continue;
            const existing = pending.get(attachment.id);
            if (existing) {
                existing.messageUuids.add(message.messageUuid);
                continue;
            }
            pending.set(attachment.id, {
                sessionUuid: message.sessionUuid,
                attachment,
                messageUuids: new Set([message.messageUuid]),
            });
        }
    }

    for (const pendingItem of pending.values()) {
        const { attachment, sessionUuid, messageUuids } = pendingItem;
        const markUploaded = async () => {
            await Promise.all(
                [...messageUuids].map((messageUuid) =>
                    markAttachmentUploaded(messageUuid, attachment.id, chatKey),
                ),
            );
        };

        try {
            const bytes = await ensureAttachmentEncryptedForUpload(
                attachment.id,
                sessionUuid,
                chatKey,
            );
            const contentMd5 = computeMd5Base64(bytes);
            const res = await fetch(
                await apiURL(
                    `/llmchat/chat/attachment/${attachment.id}/upload-url`,
                ),
                {
                    method: "POST",
                    headers: {
                        ...(await authenticatedRequestHeaders()),
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                        content_length: bytes.length,
                        content_md5: contentMd5,
                    }),
                },
            );

            if (res.status === 409) {
                await markUploaded();
                continue;
            }

            if (res.status === 501 || res.status === 404) {
                log.warn("Attachment API unavailable; skipping upload");
                continue;
            }

            await handleChatLimitError(res);
            ensureOk(res);
            const { url } = (await res.json()) as { url?: string };
            if (!url) {
                throw new Error("Invalid attachment upload response");
            }

            const uploadRes = await fetch(url, {
                method: "PUT",
                headers: {
                    "Content-Length": String(bytes.length),
                    "Content-MD5": contentMd5,
                },
                body: bytes,
            });
            ensureOk(uploadRes);

            await markUploaded();
        } catch (error) {
            if (error instanceof ChatSyncLimitError) {
                throw error;
            }
            log.error("Attachment upload failed", error);
        }
    }
};

const ensureAttachmentEncryptedForUpload = async (
    attachmentId: string,
    sessionUuid: string,
    chatKey: string,
): Promise<Uint8Array> => {
    const bytes = await readAttachmentBytes(attachmentId);

    try {
        await decryptAttachmentBytes(bytes, chatKey, sessionUuid);
        return bytes;
    } catch (error) {
        const localKey = cachedLocalChatKey();
        if (!localKey || localKey === chatKey) {
            throw error;
        }

        const plaintext = await decryptAttachmentBytes(
            bytes,
            localKey,
            sessionUuid,
        );
        const reencrypted = await encryptAttachmentBytes(
            plaintext,
            chatKey,
            sessionUuid,
        );
        await writeAttachmentBytes(attachmentId, reencrypted);
        return reencrypted;
    }
};

const upsertRemoteSession = async (
    session: LocalSessionRecord,
    chatKey: string,
): Promise<string> => {
    const encrypted = await encryptChatPayload(
        { title: session.title },
        chatKey,
    );
    const clientMetadata = await encodeClientMetadata(
        session.sessionUuid,
        session.createdAt,
        chatKey,
    );
    const sessionUuid = normalizeUuid(session.remoteId) ?? "";
    const res = await fetch(await apiURL("/llmchat/chat/session"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            session_uuid: sessionUuid,
            encrypted_data: encrypted.encryptedData,
            header: encrypted.header,
            client_metadata: clientMetadata,
        }),
    });
    await handleChatLimitError(res);
    ensureOk(res);
    const payload = (await res.json()) as {
        session_uuid?: string;
        sessionUuid?: string;
    };
    return (
        normalizeUuid(payload.session_uuid ?? payload.sessionUuid) ??
        sessionUuid
    );
};

const upsertRemoteMessage = async (
    message: LocalMessageRecord,
    sessionRemoteId: string,
    parentRemoteId: string | undefined,
    chatKey: string,
): Promise<string> => {
    const sanitizedText = message.attachments?.length
        ? stripDocumentBlocks(message.text)
        : message.text;
    const encrypted = await encryptChatPayload(
        { text: sanitizedText },
        chatKey,
    );
    const attachments = await Promise.all(
        (message.attachments ?? []).map(async (attachment) => ({
            id: attachment.id,
            size: attachment.size,
            encrypted_name:
                attachment.encryptedName ??
                (await encryptChatField(attachment.name, chatKey)),
        })),
    );

    const clientMetadata = await encodeClientMetadata(
        message.messageUuid,
        message.createdAt,
        chatKey,
    );
    const messageUuid = normalizeUuid(message.remoteId) ?? "";
    const parentMessageUuid = normalizeUuid(parentRemoteId);

    const res = await fetch(await apiURL("/llmchat/chat/message"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            message_uuid: messageUuid,
            session_uuid: sessionRemoteId,
            parent_message_uuid: parentMessageUuid ?? null,
            sender: message.sender === "assistant" ? "other" : "self",
            attachments,
            encrypted_data: encrypted.encryptedData,
            header: encrypted.header,
            client_metadata: clientMetadata,
        }),
    });
    await handleChatLimitError(res);
    ensureOk(res);
    const payload = (await res.json()) as {
        message_uuid?: string;
        messageUuid?: string;
    };
    return (
        normalizeUuid(payload.message_uuid ?? payload.messageUuid) ??
        messageUuid
    );
};

const stripDocumentBlocks = (text: string) =>
    text
        .replace(
            /----- BEGIN DOCUMENT: ([^\n]+) -----\n([\s\S]*?)\n----- END DOCUMENT: \1 -----/g,
            "",
        )
        .replace(/\n{3,}/g, "\n\n")
        .trim();

const buildBlockedMessages = (messages: LocalMessageRecord[]) => {
    const blocked = new Set<string>();
    for (const message of messages) {
        if (message.deletedAt) continue;
        const pending = (message.attachments ?? []).some(
            (attachment) => !attachment.uploadedAt,
        );
        if (pending) {
            blocked.add(message.messageUuid);
        }
    }

    if (blocked.size === 0) return blocked;

    const children = new Map<string | null, LocalMessageRecord[]>();
    for (const message of messages) {
        const parent = message.parentMessageUuid ?? null;
        const list = children.get(parent) ?? [];
        list.push(message);
        children.set(parent, list);
    }

    const queue = Array.from(blocked);
    while (queue.length) {
        const current = queue.shift();
        if (!current) continue;
        const kids = children.get(current) ?? [];
        for (const kid of kids) {
            if (!blocked.has(kid.messageUuid)) {
                blocked.add(kid.messageUuid);
                queue.push(kid.messageUuid);
            }
        }
    }

    return blocked;
};

const orderMessagesForSync = (messages: LocalMessageRecord[]) => {
    const children = new Map<string | null, LocalMessageRecord[]>();
    for (const message of messages) {
        const parent = message.parentMessageUuid ?? null;
        const list = children.get(parent) ?? [];
        list.push(message);
        children.set(parent, list);
    }

    for (const list of children.values()) {
        list.sort((a, b) => {
            if (a.createdAt !== b.createdAt) {
                return a.createdAt - b.createdAt;
            }
            return a.messageUuid.localeCompare(b.messageUuid);
        });
    }

    const ordered: LocalMessageRecord[] = [];
    const visited = new Set<string>();
    const visit = (message: LocalMessageRecord) => {
        if (visited.has(message.messageUuid)) return;
        visited.add(message.messageUuid);
        ordered.push(message);
        const kids = children.get(message.messageUuid) ?? [];
        for (const kid of kids) {
            visit(kid);
        }
    };

    const roots = children.get(null) ?? [];
    for (const root of roots) {
        visit(root);
    }

    for (const message of messages) {
        if (!visited.has(message.messageUuid)) {
            visit(message);
        }
    }

    return ordered;
};

const buildSignatureMap = (messages: LocalMessageRecord[]) => {
    const map = new Map<string, LocalMessageRecord[]>();
    for (const message of messages) {
        if (message.deletedAt) continue;
        const signature = buildSignature(
            message.sender,
            message.text,
            message.attachments ?? [],
        );
        const list = map.get(signature) ?? [];
        list.push(message);
        map.set(signature, list);
    }
    return map;
};

const buildSignature = (
    sender: string,
    text: string,
    attachments: ChatAttachment[],
) => {
    const attachmentKey = [...attachments]
        .sort((a, b) => a.id.localeCompare(b.id))
        .map((attachment) =>
            [attachment.id, attachment.size, attachment.name].join(":"),
        )
        .join("|");
    return `${sender}:${text}:${attachmentKey}`;
};

const normalizeSender = (sender?: string) => {
    if (sender === "other" || sender === "assistant") return "assistant";
    return "self";
};

type DiffResponse = {
    sessions?: RemoteSession[];
    messages?: RemoteMessage[];
    tombstones?: { sessions?: RemoteTombstone[]; messages?: RemoteTombstone[] };
    cursor?: {
        base_since_time?: number;
        since_time?: number;
        max_time?: number;
        since_type?: string;
        since_id?: string;
    };
    timestamp?: number;
};

type RemoteSession = {
    session_uuid?: string;
    sessionUuid?: string;
    encrypted_data?: string;
    encryptedData?: string;
    client_metadata?: string;
    clientMetadata?: string;
    header: string;
    created_at?: number;
    updated_at?: number;
    is_deleted?: boolean;
};

type RemoteMessage = {
    message_uuid?: string;
    messageUuid?: string;
    session_uuid?: string;
    sessionUuid?: string;
    parent_message_uuid?: string | null;
    parentMessageUuid?: string | null;
    sender?: string;
    attachments?: RemoteAttachment[];
    encrypted_data?: string;
    encryptedData?: string;
    client_metadata?: string;
    clientMetadata?: string;
    header: string;
    created_at?: number;
    updated_at?: number;
    is_deleted?: boolean;
};

type RemoteAttachment = {
    id: string;
    size: number;
    encrypted_name?: string;
    encryptedName?: string;
};

type RemoteTombstone = {
    session_uuid?: string;
    sessionUuid?: string;
    message_uuid?: string;
    messageUuid?: string;
    deleted_at?: number;
    deletedAt?: number;
};
