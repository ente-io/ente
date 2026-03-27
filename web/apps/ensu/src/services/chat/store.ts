import { getKV, removeKV, setKV } from "ente-base/kv";
import log from "ente-base/log";
import { deleteDB, openDB, type DBSchema, type IDBPDatabase } from "idb";
import { base64ToBytes } from "services/base64";
import { decryptAttachmentBytes, encryptAttachmentBytes } from "./attachments";
import { cachedLocalChatKey } from "./chatKey";
import {
    decryptChatField,
    decryptChatPayload,
    encryptChatField,
    encryptChatPayload,
} from "./crypto";

const STORAGE_KEY = "ensu.chat.store.v1";
const NATIVE_MIGRATION_KEY = "ensu.chat.nativeMigration.v1";
const CHAT_DB_NAME = "ensu-chat";
const LEGACY_WEB_CHAT_DB_NAME = "ensu.chat.db";

export type AttachmentKind = "image" | "document";

export interface ChatAttachment {
    id: string;
    kind: AttachmentKind;
    name: string;
    size: number;
    encryptedName?: string;
    uploadedAt?: number;
}

interface StoredAttachment {
    id: string;
    kind: AttachmentKind;
    size: number;
    encryptedName: string;
    uploadedAt?: number | null;
}

interface StoredSession {
    sessionUuid: string;
    createdAt: number;
    updatedAt: number;
    encryptedData: string;
    header: string;
    remoteId?: string | null;
    needsSync?: boolean;
    deletedAt?: number | null;
    isDeleted?: boolean;
}

interface StoredMessage {
    messageUuid: string;
    sessionUuid: string;
    parentMessageUuid?: string;
    sender: "self" | "assistant";
    createdAt: number;
    encryptedData: string;
    header: string;
    attachments?: StoredAttachment[];
    remoteId?: string | null;
    deletedAt?: number | null;
    isDeleted?: boolean;
}

interface StoredAttachmentBytes {
    id: string;
    data: Uint8Array;
}

interface ChatDbSchema {
    sessions: StoredSession;
    messages: StoredMessage;
    attachmentBytes: StoredAttachmentBytes;
}

type ChatStoreName = keyof ChatDbSchema;

type PersistedAttachmentBytes = { id: string; data: string };

type PersistedChatStore = {
    sessions: StoredSession[];
    messages: StoredMessage[];
    attachmentBytes: PersistedAttachmentBytes[];
};

type ChatStoreState = {
    sessions: StoredSession[];
    messages: StoredMessage[];
    attachmentBytes: StoredAttachmentBytes[];
};

interface IndexedChatDBSchema extends DBSchema {
    sessions: { key: string; value: StoredSession };
    messages: { key: string; value: StoredMessage };
    attachmentBytes: { key: string; value: StoredAttachmentBytes };
}

interface ChatObjectStore<K extends ChatStoreName> {
    get: (key: string) => Promise<ChatDbSchema[K] | undefined>;
    getAll: () => Promise<ChatDbSchema[K][]>;
    put: (value: ChatDbSchema[K]) => Promise<void>;
    delete: (key: string) => Promise<void>;
}

interface ChatTransaction {
    objectStore: <K extends ChatStoreName>(name: K) => ChatObjectStore<K>;
    done: Promise<void>;
}

interface ChatDbLike {
    get: <K extends ChatStoreName>(
        name: K,
        key: string,
    ) => Promise<ChatDbSchema[K] | undefined>;
    getAll: <K extends ChatStoreName>(name: K) => Promise<ChatDbSchema[K][]>;
    put: <K extends ChatStoreName>(
        name: K,
        value: ChatDbSchema[K],
    ) => Promise<void>;
    delete: (name: ChatStoreName, key: string) => Promise<void>;
    transaction: (names: ChatStoreName[], mode: "readwrite") => ChatTransaction;
    close: () => void;
}

export interface ChatSession {
    sessionUuid: string;
    rootSessionUuid: string;
    branchFromMessageUuid?: string;
    title: string;
    createdAt: number;
    updatedAt: number;
    lastMessagePreview?: string;
}

export interface ChatMessage {
    messageUuid: string;
    sessionUuid: string;
    parentMessageUuid?: string;
    sender: "self" | "assistant";
    text: string;
    createdAt: number;
    attachments?: ChatAttachment[];
    isSynthetic?: boolean;
}

export interface LocalSessionRecord {
    sessionUuid: string;
    title: string;
    createdAt: number;
    updatedAt: number;
    remoteId?: string | null;
    needsSync: boolean;
    deletedAt?: number | null;
}

export interface LocalMessageRecord {
    messageUuid: string;
    sessionUuid: string;
    parentMessageUuid?: string | null;
    sender: "self" | "assistant";
    text: string;
    createdAt: number;
    attachments?: ChatAttachment[];
    remoteId?: string | null;
    deletedAt?: number | null;
}

export type SyncDeletion = {
    type: "session" | "message";
    uuid: string;
    remoteId?: string | null;
};

interface NativeSession {
    sessionUuid: string;
    title: string;
    createdAt: number;
    updatedAt: number;
    remoteId?: string | null;
    needsSync?: boolean;
    deletedAt?: number | null;
    lastMessagePreview?: string | null;
}

interface NativeAttachment {
    id: string;
    kind: AttachmentKind;
    name: string;
    size: number;
    uploadedAt?: number | null;
}

interface NativeMessage {
    messageUuid: string;
    sessionUuid: string;
    parentMessageUuid?: string | null;
    sender: "self" | "assistant";
    text: string;
    createdAt: number;
    attachments?: NativeAttachment[];
    remoteId?: string | null;
    deletedAt?: number | null;
}

const nowMicros = () => Date.now() * 1000;

const isTauriRuntime = () =>
    typeof window !== "undefined" &&
    ("__TAURI__" in window || "__TAURI_IPC__" in window);

const formatLogError = (error: unknown) => {
    if (error instanceof Error) {
        const message = error.message || error.name;
        return error.stack ? `${message}\n${error.stack}` : message;
    }
    if (typeof error === "string") return error;
    try {
        return JSON.stringify(error);
    } catch {
        return String(error);
    }
};

const getErrorMessage = (error: unknown) => {
    if (error instanceof Error) return error.message || error.name;
    if (typeof error === "string") return error;
    if (error && typeof error === "object") {
        const maybeMessage = (error as { message?: unknown }).message;
        if (typeof maybeMessage === "string" && maybeMessage.trim()) {
            return maybeMessage;
        }
    }
    try {
        return JSON.stringify(error);
    } catch {
        return String(error);
    }
};

const getErrorCode = (error: unknown) => {
    if (!error || typeof error !== "object") return undefined;
    const code = (error as { code?: unknown }).code;
    return typeof code === "string" ? code : undefined;
};

const shouldResetDbError = (error: unknown) => {
    const code = getErrorCode(error);
    if (
        code === "db_crypto" ||
        code === "db_invalid_blob_length" ||
        code === "db_invalid_encrypted_field"
    ) {
        return true;
    }
    const message = getErrorMessage(error).toLowerCase();
    return (
        message.includes("stream pull failed") ||
        message.includes("invalid blob") ||
        message.includes("invalid encrypted")
    );
};

let lastDbResetAt = 0;

const withNativeDbRecovery = async <T>(
    label: string,
    operation: () => Promise<T>,
): Promise<T> => {
    try {
        return await operation();
    } catch (error) {
        if (!shouldResetDbError(error)) {
            throw error;
        }
        const now = Date.now();
        if (now - lastDbResetAt < 1000) {
            throw error;
        }
        lastDbResetAt = now;
        log.warn(
            `Chat DB error while ${label}, resetting local store: ${formatLogError(error)}`,
        );
        try {
            await resetChatStore();
        } catch (resetError) {
            log.error("Failed to reset chat store after DB error", resetError);
            throw error;
        }
        return await operation();
    }
};

const loadChatStoreState = (): ChatStoreState => {
    if (typeof localStorage === "undefined") {
        return { sessions: [], messages: [], attachmentBytes: [] };
    }

    const json = localStorage.getItem(STORAGE_KEY);
    if (!json) {
        return { sessions: [], messages: [], attachmentBytes: [] };
    }

    try {
        const parsed = JSON.parse(json) as Partial<PersistedChatStore>;
        return {
            sessions: (parsed.sessions ?? []).map((session) => ({
                ...session,
                remoteId: session.remoteId ?? null,
                needsSync: session.needsSync ?? true,
                deletedAt:
                    session.deletedAt ??
                    (session.isDeleted ? session.updatedAt : null),
            })),
            messages: (parsed.messages ?? []).map((message) => ({
                ...message,
                attachments: message.attachments ?? [],
                remoteId: message.remoteId ?? null,
                deletedAt:
                    message.deletedAt ??
                    (message.isDeleted ? message.createdAt : null),
            })),
            attachmentBytes: (parsed.attachmentBytes ?? []).map(
                (attachment) => ({
                    id: attachment.id,
                    data: base64ToBytes(attachment.data),
                }),
            ),
        };
    } catch (error) {
        log.error("Failed to parse chat store", error);
        return { sessions: [], messages: [], attachmentBytes: [] };
    }
};

const cloneStoreEntry = <K extends ChatStoreName>(
    name: K,
    value: ChatDbSchema[K],
): ChatDbSchema[K] => {
    if (name === "attachmentBytes") {
        const attachment = value as StoredAttachmentBytes;
        return {
            ...attachment,
            data: new Uint8Array(attachment.data),
        } as ChatDbSchema[K];
    }

    const cloned = { ...value };
    if (name === "messages") {
        const message = cloned as StoredMessage;
        message.attachments = message.attachments?.map((attachment) => ({
            ...attachment,
        }));
    }
    return cloned;
};

let _chatDb: Promise<ChatDbLike> | undefined;
let _chatPersistenceInitPromise: Promise<void> | undefined;
let _chatPersistenceInitKey: string | undefined;

const normalizeStoredSession = (session: StoredSession): StoredSession => ({
    ...session,
    remoteId: session.remoteId ?? null,
    needsSync: session.needsSync ?? true,
    deletedAt:
        session.deletedAt ?? (session.isDeleted ? session.updatedAt : null),
});

const normalizeStoredMessage = (message: StoredMessage): StoredMessage => ({
    ...message,
    attachments: message.attachments ?? [],
    remoteId: message.remoteId ?? null,
    deletedAt:
        message.deletedAt ?? (message.isDeleted ? message.createdAt : null),
});

const normalizeStoreEntry = <K extends ChatStoreName>(
    name: K,
    value: ChatDbSchema[K],
): ChatDbSchema[K] => {
    if (name === "sessions") {
        return normalizeStoredSession(
            value as StoredSession,
        ) as ChatDbSchema[K];
    }
    if (name === "messages") {
        return normalizeStoredMessage(
            value as StoredMessage,
        ) as ChatDbSchema[K];
    }
    return value;
};

const createIndexedDbChatDb = (
    db: IDBPDatabase<IndexedChatDBSchema>,
): ChatDbLike => ({
    get: async (name, key) => {
        const entry = (await db.get(name, key)) as
            | ChatDbSchema[typeof name]
            | undefined;
        if (!entry) return undefined;
        return cloneStoreEntry(name, normalizeStoreEntry(name, entry));
    },
    getAll: async (name) => {
        const entries = (await db.getAll(name)) as ChatDbSchema[typeof name][];
        return entries.map((entry) =>
            cloneStoreEntry(name, normalizeStoreEntry(name, entry)),
        );
    },
    put: async (name, value) => {
        await db.put(name, cloneStoreEntry(name, value));
    },
    delete: async (name, key) => {
        await db.delete(name, key);
    },
    transaction: (names, mode) => {
        const tx = db.transaction(names, mode);
        return {
            objectStore: <K extends ChatStoreName>(
                name: K,
            ): ChatObjectStore<K> => ({
                get: async (key) => {
                    const entry = (await tx.objectStore(name).get(key)) as
                        | ChatDbSchema[K]
                        | undefined;
                    if (!entry) return undefined;
                    return cloneStoreEntry(
                        name,
                        normalizeStoreEntry(name, entry),
                    );
                },
                getAll: async () => {
                    const entries = (await tx
                        .objectStore(name)
                        .getAll()) as ChatDbSchema[K][];
                    return entries.map((entry) =>
                        cloneStoreEntry(name, normalizeStoreEntry(name, entry)),
                    );
                },
                put: async (value: ChatDbSchema[K]) => {
                    await tx
                        .objectStore(name)
                        .put(cloneStoreEntry(name, value));
                },
                delete: async (key: string) => {
                    await tx.objectStore(name).delete(key);
                },
            }),
            done: tx.done,
        };
    },
    close: () => db.close(),
});

const openChatDb = async () => {
    const db = await openDB<IndexedChatDBSchema>(CHAT_DB_NAME, 1, {
        upgrade(db) {
            if (!db.objectStoreNames.contains("sessions")) {
                db.createObjectStore("sessions", { keyPath: "sessionUuid" });
            }
            if (!db.objectStoreNames.contains("messages")) {
                db.createObjectStore("messages", { keyPath: "messageUuid" });
            }
            if (!db.objectStoreNames.contains("attachmentBytes")) {
                db.createObjectStore("attachmentBytes", { keyPath: "id" });
            }
        },
    });

    return createIndexedDbChatDb(db);
};

const chatDb = () => (_chatDb ??= openChatDb());

const normalizeTitleText = (value: string) => value.replace(/\s+/g, " ").trim();

export const sessionTitleFromText = (value: string, fallback = "New chat") => {
    const normalized = normalizeTitleText(value);
    if (!normalized) return fallback;
    if (normalized.length <= 40) return normalized;
    return `${normalized.slice(0, 39)}…`;
};

const safeTitle = (value: unknown) =>
    typeof value === "string"
        ? sessionTitleFromText(value, "New chat")
        : "New chat";

const decryptSessionTitle = async (session: StoredSession, chatKey: string) => {
    try {
        const payload = (await decryptChatPayload(
            { encryptedData: session.encryptedData, header: session.header },
            chatKey,
        )) as { title?: string };
        return safeTitle(payload.title);
    } catch (error) {
        log.error("Failed to decrypt session payload", error);
        return "New chat";
    }
};

const decryptMessageText = async (message: StoredMessage, chatKey: string) => {
    try {
        const payload = (await decryptChatPayload(
            { encryptedData: message.encryptedData, header: message.header },
            chatKey,
        )) as { text?: string };
        return typeof payload.text === "string" ? payload.text : "";
    } catch (error) {
        log.error("Failed to decrypt message payload", error);
        return "";
    }
};

const serializeAttachments = async (
    attachments: ChatAttachment[] = [],
    chatKey: string,
): Promise<StoredAttachment[]> => {
    if (!attachments.length) return [];
    if (!isTauriRuntime()) {
        log.warn(
            "Chat attachments are only supported in the desktop app; ignoring attachments on web.",
        );
        return [];
    }
    return Promise.all(
        attachments.map(async (attachment) => ({
            id: attachment.id,
            kind: attachment.kind,
            size: attachment.size,
            encryptedName:
                attachment.encryptedName ??
                (await encryptChatField(attachment.name, chatKey)),
            uploadedAt: attachment.uploadedAt ?? null,
        })),
    );
};

const deserializeAttachments = async (
    attachments: StoredAttachment[] | undefined,
    chatKey: string,
): Promise<ChatAttachment[]> => {
    if (!attachments?.length || !isTauriRuntime()) return [];

    const localKey = cachedLocalChatKey();

    return Promise.all(
        attachments.map(async (attachment) => {
            try {
                const name = await decryptChatField(
                    attachment.encryptedName,
                    chatKey,
                );
                return {
                    id: attachment.id,
                    kind: attachment.kind,
                    size: attachment.size,
                    name,
                    encryptedName: attachment.encryptedName,
                    uploadedAt: attachment.uploadedAt ?? undefined,
                } satisfies ChatAttachment;
            } catch (error) {
                if (localKey && localKey !== chatKey) {
                    try {
                        const name = await decryptChatField(
                            attachment.encryptedName,
                            localKey,
                        );
                        return {
                            id: attachment.id,
                            kind: attachment.kind,
                            size: attachment.size,
                            name,
                            encryptedName: undefined,
                            uploadedAt: attachment.uploadedAt ?? undefined,
                        } satisfies ChatAttachment;
                    } catch (innerError) {
                        log.error(
                            "Failed to decrypt attachment name with local key",
                            innerError,
                        );
                    }
                }

                log.error("Failed to decrypt attachment name", error);
                return {
                    id: attachment.id,
                    kind: attachment.kind,
                    size: attachment.size,
                    name: "Attachment",
                    encryptedName: attachment.encryptedName,
                    uploadedAt: attachment.uploadedAt ?? undefined,
                } satisfies ChatAttachment;
            }
        }),
    );
};

const hasLegacyChatStore = () =>
    typeof localStorage !== "undefined" && !!localStorage.getItem(STORAGE_KEY);

const hasIndexedDbDatabase = async (name: string) => {
    if (typeof indexedDB === "undefined") return false;

    if ("databases" in indexedDB && typeof indexedDB.databases === "function") {
        const databases = await indexedDB.databases();
        return databases.some((database) => database.name === name);
    }

    return new Promise<boolean>((resolve, reject) => {
        let created = false;
        const request = indexedDB.open(name);

        request.onupgradeneeded = () => {
            created = true;
        };

        request.onsuccess = () => {
            const db = request.result;
            db.close();

            if (!created) {
                resolve(true);
                return;
            }

            const deleteRequest = indexedDB.deleteDatabase(name);
            deleteRequest.onsuccess = () => resolve(false);
            deleteRequest.onerror = () => reject(deleteRequest.error);
            deleteRequest.onblocked = () => resolve(false);
        };

        request.onerror = () => reject(request.error);
    });
};

const isNativeMigrationDone = () =>
    typeof localStorage !== "undefined" &&
    localStorage.getItem(NATIVE_MIGRATION_KEY) === "1";

const markNativeMigrationDone = () => {
    if (typeof localStorage === "undefined") return;
    localStorage.setItem(NATIVE_MIGRATION_KEY, "1");
};

const migrateLegacyLocalChatStoreToIndexedDb = async () => {
    if (typeof localStorage === "undefined") return;

    const legacy = loadChatStoreState();
    if (
        !legacy.sessions.length &&
        !legacy.messages.length &&
        !legacy.attachmentBytes.length
    ) {
        localStorage.removeItem(STORAGE_KEY);
        return;
    }

    log.info("Migrating legacy local chat store to IndexedDB", {
        sessions: legacy.sessions.length,
        messages: legacy.messages.length,
        attachmentBytes: legacy.attachmentBytes.length,
    });

    const db = await chatDb();
    const tx = db.transaction(
        ["sessions", "messages", "attachmentBytes"],
        "readwrite",
    );

    for (const session of legacy.sessions) {
        await tx.objectStore("sessions").put(normalizeStoredSession(session));
    }

    for (const message of legacy.messages) {
        await tx.objectStore("messages").put(normalizeStoredMessage(message));
    }

    for (const attachment of legacy.attachmentBytes) {
        await tx
            .objectStore("attachmentBytes")
            .put({ id: attachment.id, data: new Uint8Array(attachment.data) });
    }

    await tx.done;
    localStorage.removeItem(STORAGE_KEY);
    log.info("Finished migrating legacy local chat store to IndexedDB");
};

const migrateLegacyIndexedDbChatStore = async () => {
    if (typeof indexedDB === "undefined") return;
    if (!(await hasIndexedDbDatabase(LEGACY_WEB_CHAT_DB_NAME))) return;

    log.info("Migrating legacy IndexedDB chat store", {
        from: LEGACY_WEB_CHAT_DB_NAME,
        to: CHAT_DB_NAME,
    });

    const [legacyDb, db] = await Promise.all([
        openDB<IndexedChatDBSchema>(LEGACY_WEB_CHAT_DB_NAME),
        chatDb(),
    ]);

    let migratedAnyEntries = false;
    try {
        const [sessions, messages, attachmentBytes] = await Promise.all([
            legacyDb.getAll("sessions"),
            legacyDb.getAll("messages"),
            legacyDb.getAll("attachmentBytes"),
        ]);
        migratedAnyEntries =
            sessions.length > 0 ||
            messages.length > 0 ||
            attachmentBytes.length > 0;

        const tx = db.transaction(
            ["sessions", "messages", "attachmentBytes"],
            "readwrite",
        );

        for (const session of sessions) {
            await tx
                .objectStore("sessions")
                .put(normalizeStoredSession(session));
        }

        for (const message of messages) {
            await tx
                .objectStore("messages")
                .put(normalizeStoredMessage(message));
        }

        for (const attachment of attachmentBytes) {
            await tx
                .objectStore("attachmentBytes")
                .put({
                    id: attachment.id,
                    data: new Uint8Array(attachment.data),
                });
        }

        await tx.done;
    } finally {
        legacyDb.close();
    }

    await deleteDB(LEGACY_WEB_CHAT_DB_NAME, {
        blocked() {
            log.warn(
                "Waiting for an existing client to close the legacy chat DB",
            );
        },
    });

    log.info(
        migratedAnyEntries
            ? "Finished migrating legacy IndexedDB chat store"
            : "Removed empty legacy IndexedDB chat store",
    );
};

const migrateLegacyChatStoreToNative = async (chatKey: string) => {
    if (!isTauriRuntime() || typeof localStorage === "undefined") return;

    const legacy = loadChatStoreState();
    if (
        !legacy.sessions.length &&
        !legacy.messages.length &&
        !legacy.attachmentBytes.length
    ) {
        localStorage.removeItem(STORAGE_KEY);
        markNativeMigrationDone();
        return;
    }

    log.info("Migrating legacy local chat store to native DB", {
        sessions: legacy.sessions.length,
        messages: legacy.messages.length,
        attachmentBytes: legacy.attachmentBytes.length,
    });

    const sessions = [...legacy.sessions].sort(
        (left, right) => left.createdAt - right.createdAt,
    );
    for (const session of sessions) {
        const title = await decryptSessionTitle(session, chatKey);
        await invokeChat("chat_db_upsert_session", {
            keyB64: chatKey,
            input: {
                sessionUuid: session.sessionUuid,
                title,
                createdAt: session.createdAt,
                updatedAt: session.updatedAt,
                remoteId: session.remoteId ?? null,
                needsSync: session.needsSync ?? false,
                deletedAt: session.deletedAt ?? null,
            },
        });
    }

    const messages = [...legacy.messages].sort(
        (left, right) => left.createdAt - right.createdAt,
    );
    for (const message of messages) {
        const attachments = await deserializeAttachments(
            message.attachments,
            chatKey,
        );

        if (!message.remoteId) {
            const existing = await invokeChat<NativeMessage | null>(
                "chat_db_get_message",
                { keyB64: chatKey, messageUuid: message.messageUuid },
            );
            if (existing) {
                continue;
            }
        }

        await invokeChat("chat_db_insert_message_with_uuid", {
            keyB64: chatKey,
            input: {
                messageUuid: message.messageUuid,
                sessionUuid: message.sessionUuid,
                parentMessageUuid: message.parentMessageUuid ?? null,
                sender: message.sender,
                text: await decryptMessageText(message, chatKey),
                createdAt: message.createdAt,
                remoteId: message.remoteId ?? null,
                deletedAt: message.deletedAt ?? null,
                attachments: attachments.map((attachment) => ({
                    id: attachment.id,
                    kind: attachment.kind,
                    name: attachment.name,
                    size: attachment.size,
                    uploadedAt: attachment.uploadedAt ?? null,
                })),
            },
        });
    }

    for (const attachment of legacy.attachmentBytes) {
        await writeAttachmentBytes(attachment.id, attachment.data);
    }

    localStorage.removeItem(STORAGE_KEY);
    markNativeMigrationDone();
    log.info("Finished migrating legacy local chat store to native DB");
};

export const initializeChatStorePersistence = async (chatKey: string) => {
    if (_chatPersistenceInitKey === chatKey && _chatPersistenceInitPromise) {
        return _chatPersistenceInitPromise;
    }

    _chatPersistenceInitKey = chatKey;
    const initPromise = (async () => {
        if (isTauriRuntime()) {
            if (!hasLegacyChatStore() && isNativeMigrationDone()) return;
            await migrateLegacyChatStoreToNative(chatKey);
            return;
        }

        if (hasLegacyChatStore()) {
            await migrateLegacyLocalChatStoreToIndexedDb();
            return;
        }

        await migrateLegacyIndexedDbChatStore();
    })().catch((error: unknown) => {
        if (_chatPersistenceInitPromise === initPromise) {
            _chatPersistenceInitPromise = undefined;
            _chatPersistenceInitKey = undefined;
        }
        log.error("Failed to initialize chat persistence", error);
        throw error;
    });

    _chatPersistenceInitPromise = initPromise;
    return initPromise;
};

const fetchStore = async () => {
    const db = await chatDb();
    const [sessions, messages] = await Promise.all([
        db.getAll("sessions"),
        db.getAll("messages"),
    ]);
    return { sessions, messages };
};

const invokeChat = async <T>(
    command: string,
    args?: Record<string, unknown>,
) => {
    const { invoke } = await import("@tauri-apps/api/tauri");
    return invoke<T>(command, args);
};

const listSessionsNative = async (chatKey: string): Promise<ChatSession[]> => {
    return withNativeDbRecovery("listing sessions", async () => {
        const sessions = await invokeChat<NativeSession[]>(
            "chat_db_list_sessions_with_preview",
            { keyB64: chatKey },
        );

        const activeSessions = sessions.filter((session) => !session.deletedAt);

        return activeSessions.map((session) => ({
            sessionUuid: session.sessionUuid,
            rootSessionUuid: session.sessionUuid,
            branchFromMessageUuid: undefined,
            title: safeTitle(session.title),
            createdAt: session.createdAt,
            updatedAt: session.updatedAt,
            lastMessagePreview: session.lastMessagePreview ?? undefined,
        }));
    });
};

const listMessagesNative = async (
    sessionUuid: string,
    chatKey: string,
): Promise<ChatMessage[]> => {
    return withNativeDbRecovery("listing messages", async () => {
        const messages = await invokeChat<NativeMessage[]>(
            "chat_db_get_messages",
            { keyB64: chatKey, sessionUuid },
        );

        return messages
            .filter((message) => !message.deletedAt)
            .map((message) => ({
                messageUuid: message.messageUuid,
                sessionUuid: message.sessionUuid,
                parentMessageUuid: message.parentMessageUuid ?? undefined,
                sender: message.sender,
                text: message.text,
                createdAt: message.createdAt,
                attachments: message.attachments?.map((attachment) => ({
                    id: attachment.id,
                    kind: attachment.kind,
                    name: attachment.name,
                    size: attachment.size,
                    uploadedAt: attachment.uploadedAt ?? undefined,
                })),
            }));
    });
};

const createSessionNative = async (chatKey: string) => {
    return withNativeDbRecovery("creating session", async () => {
        const session = await invokeChat<NativeSession>(
            "chat_db_create_session",
            { keyB64: chatKey, title: "New chat" },
        );
        return session.sessionUuid;
    });
};

const updateSessionTitleNative = async (
    chatKey: string,
    sessionUuid: string,
    title: string,
) => {
    await withNativeDbRecovery("updating session title", async () => {
        await invokeChat("chat_db_update_session_title", {
            keyB64: chatKey,
            sessionUuid,
            title,
        });
    });
};

const addMessageNative = async (
    sessionUuid: string,
    sender: "self" | "assistant",
    text: string,
    chatKey: string,
    parentMessageUuid?: string,
    attachments: ChatAttachment[] = [],
): Promise<ChatMessage> => {
    return withNativeDbRecovery("adding message", async () => {
        const message = await invokeChat<NativeMessage>(
            "chat_db_insert_message",
            {
                keyB64: chatKey,
                input: {
                    sessionUuid,
                    sender,
                    text,
                    parentMessageUuid,
                    attachments: attachments.map((attachment) => ({
                        id: attachment.id,
                        kind: attachment.kind,
                        name: attachment.name,
                        size: attachment.size,
                        uploadedAt: attachment.uploadedAt ?? null,
                    })),
                },
            },
        );

        if (sender === "self") {
            try {
                const session = await invokeChat<NativeSession | null>(
                    "chat_db_get_session",
                    { keyB64: chatKey, sessionUuid },
                );
                if (
                    session &&
                    safeTitle(session.title).toLowerCase() === "new chat"
                ) {
                    const title = sessionTitleFromText(text, "New chat");
                    await updateSessionTitleNative(chatKey, sessionUuid, title);
                }
            } catch (error) {
                if (shouldResetDbError(error)) {
                    throw error;
                }
                log.error("Failed to update native session title", error);
            }
        }

        return {
            messageUuid: message.messageUuid,
            sessionUuid: message.sessionUuid,
            parentMessageUuid: message.parentMessageUuid ?? undefined,
            sender: message.sender,
            text: message.text,
            createdAt: message.createdAt,
            attachments: message.attachments?.map((attachment) => ({
                id: attachment.id,
                kind: attachment.kind,
                name: attachment.name,
                size: attachment.size,
                uploadedAt: attachment.uploadedAt ?? undefined,
            })),
        };
    });
};

const updateMessageNative = async (
    messageUuid: string,
    text: string,
    chatKey: string,
) => {
    await withNativeDbRecovery("updating message", async () => {
        await invokeChat("chat_db_update_message_text", {
            keyB64: chatKey,
            messageUuid,
            text,
        });
    });
};

const deleteSessionNative = async (sessionUuid: string, chatKey: string) => {
    await withNativeDbRecovery("deleting session", async () => {
        await invokeChat("chat_db_delete_session", {
            keyB64: chatKey,
            sessionUuid,
        });
    });
};

export const listSessions = async (chatKey: string): Promise<ChatSession[]> => {
    if (isTauriRuntime()) {
        try {
            return await listSessionsNative(chatKey);
        } catch (error) {
            log.error(
                `Failed to list native sessions: ${formatLogError(error)}`,
            );
            throw error;
        }
    }

    try {
        const { sessions, messages } = await fetchStore();

        const activeSessions = sessions
            .filter((session) => !session.deletedAt && !session.isDeleted)
            .sort((a, b) => b.updatedAt - a.updatedAt);

        const bySession = new Map<string, StoredMessage[]>();
        for (const message of messages) {
            if (message.deletedAt || message.isDeleted) continue;
            const list = bySession.get(message.sessionUuid) ?? [];
            list.push(message);
            bySession.set(message.sessionUuid, list);
        }

        for (const list of bySession.values()) {
            list.sort((a, b) => b.createdAt - a.createdAt);
        }

        return Promise.all(
            activeSessions.map(async (session) => {
                const title = await decryptSessionTitle(session, chatKey);
                const latest = bySession.get(session.sessionUuid)?.[0];
                const lastMessagePreview = latest
                    ? await decryptMessageText(latest, chatKey)
                    : undefined;

                return {
                    sessionUuid: session.sessionUuid,
                    rootSessionUuid: session.sessionUuid,
                    branchFromMessageUuid: undefined,
                    title,
                    createdAt: session.createdAt,
                    updatedAt: session.updatedAt,
                    lastMessagePreview,
                } satisfies ChatSession;
            }),
        );
    } catch (error) {
        log.error(`Failed to list sessions: ${formatLogError(error)}`);
        throw error;
    }
};

export const listMessages = async (
    sessionUuid: string,
    chatKey: string,
): Promise<ChatMessage[]> => {
    if (isTauriRuntime()) {
        try {
            return await listMessagesNative(sessionUuid, chatKey);
        } catch (error) {
            log.error(
                `Failed to list native messages: ${formatLogError(error)}`,
            );
            throw error;
        }
    }

    try {
        const { messages } = await fetchStore();
        const sessionMessages = messages
            .filter(
                (message) =>
                    message.sessionUuid === sessionUuid &&
                    !message.deletedAt &&
                    !message.isDeleted,
            )
            .sort((a, b) => a.createdAt - b.createdAt);

        return Promise.all(
            sessionMessages.map(async (message) => ({
                messageUuid: message.messageUuid,
                sessionUuid: message.sessionUuid,
                parentMessageUuid: message.parentMessageUuid,
                sender: message.sender,
                createdAt: message.createdAt,
                text: await decryptMessageText(message, chatKey),
                attachments: await deserializeAttachments(
                    message.attachments,
                    chatKey,
                ),
            })),
        );
    } catch (error) {
        log.error(`Failed to list messages: ${formatLogError(error)}`);
        throw error;
    }
};

export const createSession = async (chatKey: string) => {
    if (isTauriRuntime()) {
        return createSessionNative(chatKey);
    }

    const db = await chatDb();
    const now = nowMicros();
    const sessionUuid = crypto.randomUUID();

    const encrypted = await encryptChatPayload({ title: "New chat" }, chatKey);

    const session: StoredSession = {
        sessionUuid,
        createdAt: now,
        updatedAt: now,
        encryptedData: encrypted.encryptedData,
        header: encrypted.header,
        remoteId: null,
        needsSync: true,
        deletedAt: null,
    };

    await db.put("sessions", session);
    return sessionUuid;
};

export const addMessage = async (
    sessionUuid: string,
    sender: "self" | "assistant",
    text: string,
    chatKey: string,
    parentMessageUuid?: string,
    attachments: ChatAttachment[] = [],
): Promise<ChatMessage> => {
    if (isTauriRuntime()) {
        return addMessageNative(
            sessionUuid,
            sender,
            text,
            chatKey,
            parentMessageUuid,
            attachments,
        );
    }

    const db = await chatDb();
    const now = nowMicros();
    const messageUuid = crypto.randomUUID();

    const encrypted = await encryptChatPayload({ text }, chatKey);
    const storedAttachments = await serializeAttachments(attachments, chatKey);

    const message: StoredMessage = {
        messageUuid,
        sessionUuid,
        parentMessageUuid,
        sender,
        createdAt: now,
        encryptedData: encrypted.encryptedData,
        header: encrypted.header,
        attachments: storedAttachments,
        remoteId: null,
        deletedAt: null,
    };

    const tx = db.transaction(["sessions", "messages"], "readwrite");
    await tx.objectStore("messages").put(message);

    const sessionStore = tx.objectStore("sessions");
    const session = await sessionStore.get(sessionUuid);
    if (session) {
        session.updatedAt = now;
        session.needsSync = true;

        const currentTitle = await decryptSessionTitle(session, chatKey);
        if (sender === "self" && currentTitle.toLowerCase() === "new chat") {
            const title = sessionTitleFromText(text, "New chat");
            const updated = await encryptChatPayload({ title }, chatKey);
            session.encryptedData = updated.encryptedData;
            session.header = updated.header;
        }

        await sessionStore.put(session);
    }

    await tx.done;
    return {
        messageUuid,
        sessionUuid,
        parentMessageUuid,
        sender,
        text,
        createdAt: now,
        attachments,
    };
};

export const updateSessionTitle = async (
    sessionUuid: string,
    title: string,
    chatKey: string,
) => {
    const safe = sessionTitleFromText(title, "New chat");
    if (isTauriRuntime()) {
        await updateSessionTitleNative(chatKey, sessionUuid, safe);
        return;
    }

    const db = await chatDb();
    const session = await db.get("sessions", sessionUuid);
    if (!session) return;

    const updated = await encryptChatPayload({ title: safe }, chatKey);
    session.encryptedData = updated.encryptedData;
    session.header = updated.header;
    session.updatedAt = nowMicros();
    session.needsSync = true;
    await db.put("sessions", session);
};

export const updateMessage = async (
    messageUuid: string,
    text: string,
    chatKey: string,
) => {
    if (isTauriRuntime()) {
        await updateMessageNative(messageUuid, text, chatKey);
        return;
    }

    const db = await chatDb();
    const tx = db.transaction(["sessions", "messages"], "readwrite");
    const messageStore = tx.objectStore("messages");
    const message = await messageStore.get(messageUuid);
    if (!message) {
        await tx.done;
        return;
    }

    const encrypted = await encryptChatPayload({ text }, chatKey);
    message.encryptedData = encrypted.encryptedData;
    message.header = encrypted.header;
    await messageStore.put(message);

    const sessionStore = tx.objectStore("sessions");
    const session = await sessionStore.get(message.sessionUuid);
    if (session) {
        session.updatedAt = nowMicros();
        session.needsSync = true;
        await sessionStore.put(session);
    }

    await tx.done;
};

const branchSelectionsKey = (rootSessionUuid: string) =>
    `ensu.chat.branchSelections.v1.${rootSessionUuid}`;

export const getBranchSelections = async (rootSessionUuid: string) => {
    const stored = await getKV(branchSelectionsKey(rootSessionUuid));
    if (!stored || typeof stored !== "object") return {};

    return Object.fromEntries(
        Object.entries(stored).filter(
            (entry): entry is [string, string] =>
                typeof entry[0] === "string" && typeof entry[1] === "string",
        ),
    );
};

export const resetChatStore = async () => {
    if (typeof window === "undefined") return;

    localStorage.removeItem(STORAGE_KEY);

    if (isTauriRuntime()) {
        await invokeChat("chat_db_reset");
        return;
    }
    try {
        if (_chatDb) {
            (await _chatDb).close();
        }
    } catch (error) {
        log.error("Failed to close chat IndexedDB before reset", error);
    }
    _chatDb = undefined;
    await deleteDB("ensu-chat");
};

export const setBranchSelection = async (
    rootSessionUuid: string,
    selectionKey: string,
    selectedMessageUuid: string,
) => {
    const selections = await getBranchSelections(rootSessionUuid);
    selections[selectionKey] = selectedMessageUuid;
    await setKV(branchSelectionsKey(rootSessionUuid), selections);
};

export const deleteBranchSelections = (rootSessionUuid: string) =>
    removeKV(branchSelectionsKey(rootSessionUuid));

export const deleteSession = async (sessionUuid: string, chatKey: string) => {
    if (isTauriRuntime()) {
        await deleteSessionNative(sessionUuid, chatKey);
        await deleteBranchSelections(sessionUuid);
        return;
    }

    const db = await chatDb();
    const now = nowMicros();
    const tx = db.transaction(["sessions", "messages"], "readwrite");

    const sessionStore = tx.objectStore("sessions");
    const session = await sessionStore.get(sessionUuid);
    if (session) {
        session.deletedAt = now;
        session.needsSync = true;
        await sessionStore.put(session);
    }

    const messageStore = tx.objectStore("messages");
    const messages = await messageStore.getAll();
    await Promise.all(
        messages
            .filter((message) => message.sessionUuid === sessionUuid)
            .map((message) => {
                message.deletedAt = now;
                return messageStore.put(message);
            }),
    );

    await tx.done;
    await deleteBranchSelections(sessionUuid);
};

let _attachmentDir: Promise<string> | undefined;

const attachmentDir = async () => {
    if (!isTauriRuntime()) {
        return "";
    }

    _attachmentDir ??= (async () => {
        const { appDataDir, join } = await import("@tauri-apps/api/path");
        const { createDir } = await import("@tauri-apps/api/fs");
        const root = await appDataDir();
        const dir = await join(root, "ensu_llmchat_attachments");
        await createDir(dir, { recursive: true });
        return dir;
    })();

    return _attachmentDir;
};

const attachmentPath = async (id: string) => {
    const { join } = await import("@tauri-apps/api/path");
    const dir = await attachmentDir();
    return join(dir, id);
};

export const writeAttachmentBytes = async (id: string, data: Uint8Array) => {
    if (isTauriRuntime()) {
        const { writeBinaryFile } = await import("@tauri-apps/api/fs");
        const path = await attachmentPath(id);
        await writeBinaryFile({ path, contents: data });
        return;
    }

    const db = await chatDb();
    await db.put("attachmentBytes", { id, data });
};

export const storeEncryptedAttachmentBytes = async (
    id: string,
    data: Uint8Array,
    chatKey: string,
    sessionUuid: string,
) => {
    const encrypted = await encryptAttachmentBytes(data, chatKey, sessionUuid);
    await writeAttachmentBytes(id, encrypted);
};

export const readAttachmentBytes = async (id: string): Promise<Uint8Array> => {
    if (isTauriRuntime()) {
        const { readBinaryFile } = await import("@tauri-apps/api/fs");
        const path = await attachmentPath(id);
        return readBinaryFile(path);
    }

    const db = await chatDb();
    const entry = await db.get("attachmentBytes", id);
    if (!entry) {
        throw new Error(`Attachment bytes not found: ${id}`);
    }
    return entry.data instanceof Uint8Array
        ? entry.data
        : new Uint8Array(entry.data);
};

export const readDecryptedAttachmentBytes = async (
    id: string,
    chatKey: string,
    sessionUuid: string,
): Promise<Uint8Array> => {
    const encrypted = await readAttachmentBytes(id);
    try {
        return await decryptAttachmentBytes(encrypted, chatKey, sessionUuid);
    } catch (error) {
        const localKey = cachedLocalChatKey();
        if (!localKey || localKey === chatKey) {
            throw error;
        }
        return decryptAttachmentBytes(encrypted, localKey, sessionUuid);
    }
};

export const attachmentBytesExists = async (id: string): Promise<boolean> => {
    if (isTauriRuntime()) {
        const { exists } = await import("@tauri-apps/api/fs");
        const path = await attachmentPath(id);
        return exists(path);
    }

    const db = await chatDb();
    const entry = await db.get("attachmentBytes", id);
    return !!entry;
};

export const deleteAttachmentBytes = async (id: string) => {
    if (isTauriRuntime()) {
        const { removeFile } = await import("@tauri-apps/api/fs");
        const path = await attachmentPath(id);
        try {
            await removeFile(path);
        } catch {
            // ignore missing files
        }
        return;
    }

    const db = await chatDb();
    await db.delete("attachmentBytes", id);
};

export const getSessionRecord = async (
    sessionUuid: string,
    chatKey: string,
): Promise<LocalSessionRecord | null> => {
    if (isTauriRuntime()) {
        return withNativeDbRecovery("loading session", async () => {
            const session = await invokeChat<NativeSession | null>(
                "chat_db_get_session",
                { keyB64: chatKey, sessionUuid },
            );
            if (!session) return null;
            return {
                sessionUuid: session.sessionUuid,
                title: session.title,
                createdAt: session.createdAt,
                updatedAt: session.updatedAt,
                remoteId: session.remoteId ?? null,
                needsSync: session.needsSync ?? false,
                deletedAt: session.deletedAt ?? null,
            };
        });
    }

    const db = await chatDb();
    const session = await db.get("sessions", sessionUuid);
    if (!session) return null;

    return {
        sessionUuid: session.sessionUuid,
        title: await decryptSessionTitle(session, chatKey),
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        remoteId: session.remoteId ?? null,
        needsSync: session.needsSync ?? false,
        deletedAt: session.deletedAt ?? null,
    };
};

export const listSessionRemoteMap = async (): Promise<Map<string, string>> => {
    if (isTauriRuntime()) {
        return new Map();
    }
    const db = await chatDb();
    const sessions = await db.getAll("sessions");
    const map = new Map<string, string>();
    for (const session of sessions) {
        if (session.remoteId) {
            map.set(session.remoteId, session.sessionUuid);
        }
    }
    return map;
};

export const listMessageRemoteMap = async (): Promise<Map<string, string>> => {
    if (isTauriRuntime()) {
        return new Map();
    }
    const db = await chatDb();
    const messages = await db.getAll("messages");
    const map = new Map<string, string>();
    for (const message of messages) {
        if (message.remoteId) {
            map.set(message.remoteId, message.messageUuid);
        }
    }
    return map;
};

export const listSessionsForSync = async (
    chatKey: string,
): Promise<LocalSessionRecord[]> => {
    if (isTauriRuntime()) {
        return withNativeDbRecovery("listing sessions for sync", async () => {
            const sessions = await invokeChat<NativeSession[]>(
                "chat_db_list_sessions_for_sync",
                { keyB64: chatKey },
            );
            return sessions
                .filter((session) => !session.deletedAt)
                .map((session) => ({
                    sessionUuid: session.sessionUuid,
                    title: session.title,
                    createdAt: session.createdAt,
                    updatedAt: session.updatedAt,
                    remoteId: session.remoteId ?? null,
                    needsSync: session.needsSync ?? false,
                    deletedAt: session.deletedAt ?? null,
                }));
        });
    }

    const db = await chatDb();
    const sessions = await db.getAll("sessions");
    const active = sessions.filter(
        (session) => session.needsSync && !session.deletedAt,
    );

    return Promise.all(
        active.map(async (session) => ({
            sessionUuid: session.sessionUuid,
            title: await decryptSessionTitle(session, chatKey),
            createdAt: session.createdAt,
            updatedAt: session.updatedAt,
            remoteId: session.remoteId ?? null,
            needsSync: session.needsSync ?? false,
            deletedAt: session.deletedAt ?? null,
        })),
    );
};

export const listMessagesForSessionSync = async (
    sessionUuid: string,
    chatKey: string,
    options: { includeDeleted?: boolean } = {},
): Promise<LocalMessageRecord[]> => {
    const includeDeleted = options.includeDeleted ?? false;

    if (isTauriRuntime()) {
        return withNativeDbRecovery("listing messages for sync", async () => {
            const messages = await invokeChat<NativeMessage[]>(
                "chat_db_get_messages_for_sync",
                { keyB64: chatKey, sessionUuid, includeDeleted },
            );
            return messages
                .filter((message) => includeDeleted || !message.deletedAt)
                .map((message) => ({
                    messageUuid: message.messageUuid,
                    sessionUuid: message.sessionUuid,
                    parentMessageUuid: message.parentMessageUuid ?? null,
                    sender: message.sender,
                    text: message.text,
                    createdAt: message.createdAt,
                    deletedAt: message.deletedAt ?? null,
                    attachments: message.attachments?.map((attachment) => ({
                        id: attachment.id,
                        kind: attachment.kind,
                        name: attachment.name,
                        size: attachment.size,
                        uploadedAt: attachment.uploadedAt ?? undefined,
                    })),
                    remoteId: message.remoteId ?? null,
                }));
        });
    }

    const db = await chatDb();
    const messages = await db.getAll("messages");
    const scoped = messages
        .filter((message) => message.sessionUuid === sessionUuid)
        .filter((message) => includeDeleted || !message.deletedAt);

    return Promise.all(
        scoped.map(async (message) => ({
            messageUuid: message.messageUuid,
            sessionUuid: message.sessionUuid,
            parentMessageUuid: message.parentMessageUuid ?? null,
            sender: message.sender,
            text: await decryptMessageText(message, chatKey),
            createdAt: message.createdAt,
            deletedAt: message.deletedAt ?? null,
            attachments: await deserializeAttachments(
                message.attachments,
                chatKey,
            ),
            remoteId: message.remoteId ?? null,
        })),
    );
};

export const upsertSessionRecord = async (
    input: LocalSessionRecord,
    chatKey: string,
) => {
    if (isTauriRuntime()) {
        await invokeChat("chat_db_upsert_session", {
            keyB64: chatKey,
            input: {
                sessionUuid: input.sessionUuid,
                title: input.title,
                createdAt: input.createdAt,
                updatedAt: input.updatedAt,
                remoteId: input.remoteId ?? null,
                needsSync: input.needsSync,
                deletedAt: input.deletedAt ?? null,
            },
        });
        return;
    }

    const db = await chatDb();
    const encrypted = await encryptChatPayload({ title: input.title }, chatKey);

    const session: StoredSession = {
        sessionUuid: input.sessionUuid,
        createdAt: input.createdAt,
        updatedAt: input.updatedAt,
        encryptedData: encrypted.encryptedData,
        header: encrypted.header,
        remoteId: input.remoteId ?? null,
        needsSync: input.needsSync,
        deletedAt: input.deletedAt ?? null,
    };

    await db.put("sessions", session);
};

export const insertMessageFromRemote = async (
    input: LocalMessageRecord,
    chatKey: string,
) => {
    if (isTauriRuntime()) {
        await invokeChat("chat_db_insert_message_with_uuid", {
            keyB64: chatKey,
            input: {
                messageUuid: input.messageUuid,
                sessionUuid: input.sessionUuid,
                parentMessageUuid: input.parentMessageUuid ?? null,
                sender: input.sender,
                text: input.text,
                createdAt: input.createdAt,
                remoteId: input.remoteId ?? null,
                deletedAt: input.deletedAt ?? null,
                attachments: input.attachments?.map((attachment) => ({
                    id: attachment.id,
                    kind: attachment.kind,
                    name: attachment.name,
                    size: attachment.size,
                    uploadedAt: attachment.uploadedAt ?? null,
                })),
            },
        });
        return;
    }

    const db = await chatDb();
    const existing = await db.get("messages", input.messageUuid);
    if (existing) return;

    const encrypted = await encryptChatPayload({ text: input.text }, chatKey);
    const storedAttachments = await serializeAttachments(
        input.attachments ?? [],
        chatKey,
    );

    const message: StoredMessage = {
        messageUuid: input.messageUuid,
        sessionUuid: input.sessionUuid,
        parentMessageUuid: input.parentMessageUuid ?? undefined,
        sender: input.sender,
        createdAt: input.createdAt,
        encryptedData: encrypted.encryptedData,
        header: encrypted.header,
        attachments: storedAttachments,
        remoteId: input.remoteId ?? null,
        deletedAt: input.deletedAt ?? null,
    };

    await db.put("messages", message);
};

export const markSessionSynced = async (
    sessionUuid: string,
    remoteId: string,
    chatKey: string,
) => {
    if (isTauriRuntime()) {
        await invokeChat("chat_db_mark_session_synced", {
            keyB64: chatKey,
            sessionUuid,
            remoteId,
        });
        return;
    }

    const db = await chatDb();
    const session = await db.get("sessions", sessionUuid);
    if (!session) return;
    session.remoteId = remoteId;
    session.needsSync = false;
    await db.put("sessions", session);
};

export const markMessageSynced = async (
    messageUuid: string,
    remoteId: string,
) => {
    if (isTauriRuntime()) {
        return;
    }

    const db = await chatDb();
    const message = await db.get("messages", messageUuid);
    if (!message) return;
    message.remoteId = remoteId;
    await db.put("messages", message);
};

export const markSessionDeletedAt = async (
    sessionUuid: string,
    deletedAt: number,
    chatKey: string,
) => {
    if (isTauriRuntime()) {
        await invokeChat("chat_db_mark_session_deleted", {
            keyB64: chatKey,
            sessionUuid,
            deletedAt,
        });
        await deleteBranchSelections(sessionUuid);
        return;
    }

    const db = await chatDb();
    const tx = db.transaction(["sessions", "messages"], "readwrite");
    const sessionStore = tx.objectStore("sessions");
    const session = await sessionStore.get(sessionUuid);
    if (session) {
        session.deletedAt = deletedAt;
        session.needsSync = false;
        await sessionStore.put(session);
    }

    const messageStore = tx.objectStore("messages");
    const messages = await messageStore.getAll();
    await Promise.all(
        messages
            .filter((message) => message.sessionUuid === sessionUuid)
            .map((message) => {
                message.deletedAt = deletedAt;
                return messageStore.put(message);
            }),
    );

    await tx.done;
    await deleteBranchSelections(sessionUuid);
};

export const markMessageDeletedAt = async (
    messageUuid: string,
    deletedAt: number,
    chatKey: string,
) => {
    if (isTauriRuntime()) {
        await invokeChat("chat_db_mark_message_deleted", {
            keyB64: chatKey,
            messageUuid,
            deletedAt,
        });
        return;
    }

    const db = await chatDb();
    const message = await db.get("messages", messageUuid);
    if (!message) return;
    message.deletedAt = deletedAt;
    await db.put("messages", message);
};

export const markAttachmentUploaded = async (
    messageUuid: string,
    attachmentId: string,
    chatKey: string,
) => {
    if (isTauriRuntime()) {
        await invokeChat("chat_db_mark_attachment_uploaded", {
            keyB64: chatKey,
            messageUuid,
            attachmentId,
        });
        return;
    }

    const db = await chatDb();
    const message = await db.get("messages", messageUuid);
    if (!message?.attachments) return;

    let updated = false;
    const updatedAttachments = message.attachments.map((attachment) => {
        if (attachment.id === attachmentId) {
            if (!attachment.uploadedAt) {
                attachment.uploadedAt = nowMicros();
            }
            updated = true;
        }
        return attachment;
    });

    if (updated) {
        message.attachments = updatedAttachments;
        await db.put("messages", message);
    }
};

export const getPendingDeletions = async (
    chatKey: string,
): Promise<SyncDeletion[]> => {
    if (isTauriRuntime()) {
        const deletions = await invokeChat<
            { entityType: string; uuid: string }[]
        >("chat_db_get_pending_deletions", { keyB64: chatKey });
        return deletions.map((deletion) => ({
            type: deletion.entityType === "message" ? "message" : "session",
            uuid: deletion.uuid,
        }));
    }

    const db = await chatDb();
    const [sessions, messages] = await Promise.all([
        db.getAll("sessions"),
        db.getAll("messages"),
    ]);

    const sessionsById = new Map(
        sessions.map((session) => [session.sessionUuid, session]),
    );

    const deletions: SyncDeletion[] = [];
    for (const session of sessions) {
        if (session.deletedAt && session.needsSync) {
            deletions.push({
                type: "session",
                uuid: session.sessionUuid,
                remoteId: session.remoteId ?? null,
            });
        }
    }

    for (const message of messages) {
        if (!message.deletedAt) continue;
        const session = sessionsById.get(message.sessionUuid);
        if (!session?.needsSync) continue;
        deletions.push({
            type: "message",
            uuid: message.messageUuid,
            remoteId: message.remoteId ?? null,
        });
    }

    return deletions;
};

export const hardDeleteEntity = async (
    deletion: SyncDeletion,
    chatKey: string,
) => {
    if (isTauriRuntime()) {
        try {
            if (deletion.type === "session") {
                const messages = await invokeChat<NativeMessage[]>(
                    "chat_db_get_messages_for_sync",
                    {
                        keyB64: chatKey,
                        sessionUuid: deletion.uuid,
                        includeDeleted: true,
                    },
                );
                await Promise.all(
                    messages.flatMap((message) =>
                        (message.attachments ?? []).map((attachment) =>
                            deleteAttachmentBytes(attachment.id),
                        ),
                    ),
                );
            } else {
                const message = await invokeChat<NativeMessage | null>(
                    "chat_db_get_message",
                    { keyB64: chatKey, messageUuid: deletion.uuid },
                );
                if (message?.attachments?.length) {
                    await Promise.all(
                        message.attachments.map((attachment) =>
                            deleteAttachmentBytes(attachment.id),
                        ),
                    );
                }
            }
        } catch (error) {
            log.error("Failed to clean up attachment bytes", error);
        }

        await invokeChat("chat_db_hard_delete", {
            keyB64: chatKey,
            entityType: deletion.type,
            uuid: deletion.uuid,
        });
        if (deletion.type === "session") {
            await deleteBranchSelections(deletion.uuid);
        }
        return;
    }

    const db = await chatDb();
    if (deletion.type === "session") {
        const tx = db.transaction(["sessions", "messages"], "readwrite");
        await tx.objectStore("sessions").delete(deletion.uuid);
        const messageStore = tx.objectStore("messages");
        const messages = await messageStore.getAll();
        const sessionMessages = messages.filter(
            (message) => message.sessionUuid === deletion.uuid,
        );
        await Promise.all(
            sessionMessages.map((message) =>
                messageStore.delete(message.messageUuid),
            ),
        );
        await tx.done;

        await Promise.all(
            sessionMessages.flatMap((message) =>
                (message.attachments ?? []).map((attachment) =>
                    deleteAttachmentBytes(attachment.id),
                ),
            ),
        );

        await deleteBranchSelections(deletion.uuid);
        return;
    }

    const message = await db.get("messages", deletion.uuid);
    if (message?.attachments?.length) {
        await Promise.all(
            message.attachments.map((attachment) =>
                deleteAttachmentBytes(attachment.id),
            ),
        );
    }
    await db.delete("messages", deletion.uuid);
};
