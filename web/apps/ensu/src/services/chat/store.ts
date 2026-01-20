import { openDB, type DBSchema, type IDBPDatabase } from "idb";
import log from "ente-base/log";
import { decryptChatPayload, encryptChatPayload } from "./crypto";

const DB_NAME = "ensu.chat.db";
const DB_VERSION = 1;

interface StoredSession {
    sessionUuid: string;
    createdAt: number;
    updatedAt: number;
    encryptedData: string;
    header: string;
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
    isDeleted?: boolean;
}

interface ChatDbSchema extends DBSchema {
    sessions: {
        key: string;
        value: StoredSession;
    };
    messages: {
        key: string;
        value: StoredMessage;
    };
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
}

interface NativeSession {
    sessionUuid: string;
    title: string;
    createdAt: number;
    updatedAt: number;
    remoteId?: string | null;
    needsSync?: boolean;
    deletedAt?: number | null;
}

interface NativeMessage {
    messageUuid: string;
    sessionUuid: string;
    parentMessageUuid?: string | null;
    sender: "self" | "assistant";
    text: string;
    createdAt: number;
    deletedAt?: number | null;
}

const nowMicros = () => Date.now() * 1000;

const isTauriRuntime = () =>
    typeof window !== "undefined" &&
    ("__TAURI__" in window || "__TAURI_IPC__" in window);

let _chatDb: Promise<IDBPDatabase<ChatDbSchema>> | undefined;

const openChatDb = async () => {
    const db = await openDB<ChatDbSchema>(DB_NAME, DB_VERSION, {
        upgrade(db) {
            if (!db.objectStoreNames.contains("sessions")) {
                db.createObjectStore("sessions", { keyPath: "sessionUuid" });
            }
            if (!db.objectStoreNames.contains("messages")) {
                db.createObjectStore("messages", { keyPath: "messageUuid" });
            }
        },
        blocking() {
            log.info("Another client is trying to open a newer chat DB schema");
            db.close();
            _chatDb = undefined;
        },
        blocked() {
            log.warn("Waiting for an existing client to release the chat DB");
        },
        terminated() {
            log.warn("Chat DB connection was terminated");
            _chatDb = undefined;
        },
    });

    return db;
};

const chatDb = () => (_chatDb ??= openChatDb());

const safeTitle = (value: unknown) =>
    typeof value === "string" && value.trim().length
        ? value.trim()
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

const fetchStore = async () => {
    const db = await chatDb();
    const [sessions, messages] = await Promise.all([
        db.getAll("sessions"),
        db.getAll("messages"),
    ]);
    return { sessions, messages };
};

const invokeChat = async <T>(command: string, args?: Record<string, unknown>) => {
    const { invoke } = await import("@tauri-apps/api/tauri");
    return invoke<T>(command, args);
};

const listSessionsNative = async (chatKey: string): Promise<ChatSession[]> => {
    const sessions = await invokeChat<NativeSession[]>("chat_db_list_sessions", {
        keyB64: chatKey,
    });

    const previews = await Promise.all(
        sessions.map(async (session) => {
            try {
                const messages = await invokeChat<NativeMessage[]>(
                    "chat_db_get_messages",
                    { keyB64: chatKey, sessionUuid: session.sessionUuid },
                );
                const latest = messages[messages.length - 1];
                return latest?.text;
            } catch (error) {
                log.error("Failed to load native messages", error);
                return undefined;
            }
        }),
    );

    return sessions.map((session, idx) => ({
        sessionUuid: session.sessionUuid,
        rootSessionUuid: session.sessionUuid,
        branchFromMessageUuid: undefined,
        title: safeTitle(session.title),
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        lastMessagePreview: previews[idx],
    }));
};

const listMessagesNative = async (
    sessionUuid: string,
    chatKey: string,
): Promise<ChatMessage[]> => {
    const messages = await invokeChat<NativeMessage[]>("chat_db_get_messages", {
        keyB64: chatKey,
        sessionUuid,
    });

    return messages.map((message) => ({
        messageUuid: message.messageUuid,
        sessionUuid: message.sessionUuid,
        parentMessageUuid: message.parentMessageUuid ?? undefined,
        sender: message.sender,
        text: message.text,
        createdAt: message.createdAt,
    }));
};

const createSessionNative = async (chatKey: string) => {
    const session = await invokeChat<NativeSession>("chat_db_create_session", {
        keyB64: chatKey,
        title: "New chat",
    });
    return session.sessionUuid;
};

const updateSessionTitleNative = async (
    chatKey: string,
    sessionUuid: string,
    title: string,
) => {
    await invokeChat("chat_db_update_session_title", {
        keyB64: chatKey,
        sessionUuid,
        title,
    });
};

const addMessageNative = async (
    sessionUuid: string,
    sender: "self" | "assistant",
    text: string,
    chatKey: string,
    parentMessageUuid?: string,
) => {
    const message = await invokeChat<NativeMessage>("chat_db_insert_message", {
        keyB64: chatKey,
        input: {
            sessionUuid,
            sender,
            text,
            parentMessageUuid,
        },
    });

    if (sender === "self") {
        try {
            const session = await invokeChat<NativeSession | null>(
                "chat_db_get_session",
                { keyB64: chatKey, sessionUuid },
            );
            if (session && safeTitle(session.title) === "New chat") {
                const trimmed = text.trim();
                const title =
                    trimmed.length > 0 ? trimmed.slice(0, 40) : "New chat";
                await updateSessionTitleNative(chatKey, sessionUuid, title);
            }
        } catch (error) {
            log.error("Failed to update native session title", error);
        }
    }

    return message.messageUuid;
};

const updateMessageNative = async (
    messageUuid: string,
    text: string,
    chatKey: string,
) => {
    await invokeChat("chat_db_update_message_text", {
        keyB64: chatKey,
        messageUuid,
        text,
    });
};

const deleteSessionNative = async (sessionUuid: string, chatKey: string) => {
    await invokeChat("chat_db_delete_session", {
        keyB64: chatKey,
        sessionUuid,
    });
};

export const listSessions = async (chatKey: string): Promise<ChatSession[]> => {
    if (isTauriRuntime()) {
        try {
            return await listSessionsNative(chatKey);
        } catch (error) {
            log.error("Failed to list native sessions", error);
            return [];
        }
    }

    try {
        const { sessions, messages } = await fetchStore();

        const activeSessions = sessions
            .filter((session) => !session.isDeleted)
            .sort((a, b) => b.updatedAt - a.updatedAt);

        const bySession = new Map<string, StoredMessage[]>();
        for (const message of messages) {
            if (message.isDeleted) continue;
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
        log.error("Failed to list sessions", error);
        return [];
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
            log.error("Failed to list native messages", error);
            return [];
        }
    }

    try {
        const { messages } = await fetchStore();
        const sessionMessages = messages
            .filter(
                (message) =>
                    message.sessionUuid === sessionUuid && !message.isDeleted,
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
            })),
        );
    } catch (error) {
        log.error("Failed to list messages", error);
        return [];
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
) => {
    if (isTauriRuntime()) {
        return addMessageNative(
            sessionUuid,
            sender,
            text,
            chatKey,
            parentMessageUuid,
        );
    }

    const db = await chatDb();
    const now = nowMicros();
    const messageUuid = crypto.randomUUID();

    const encrypted = await encryptChatPayload({ text }, chatKey);

    const message: StoredMessage = {
        messageUuid,
        sessionUuid,
        parentMessageUuid,
        sender,
        createdAt: now,
        encryptedData: encrypted.encryptedData,
        header: encrypted.header,
    };

    const tx = db.transaction(["sessions", "messages"], "readwrite");
    await tx.objectStore("messages").put(message);

    const sessionStore = tx.objectStore("sessions");
    const session = await sessionStore.get(sessionUuid);
    if (session) {
        session.updatedAt = now;

        const currentTitle = await decryptSessionTitle(session, chatKey);
        if (currentTitle === "New chat" && sender === "self") {
            const trimmed = text.trim();
            const title = trimmed.length > 0 ? trimmed.slice(0, 40) : "New chat";
            const updated = await encryptChatPayload({ title }, chatKey);
            session.encryptedData = updated.encryptedData;
            session.header = updated.header;
        }

        await sessionStore.put(session);
    }

    await tx.done;
    return messageUuid;
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
        await sessionStore.put(session);
    }

    await tx.done;
};

const BRANCH_SELECTIONS_KEY = "ensu.chat.branchSelections.v1";

type BranchSelectionsStore = Record<string, Record<string, string>>;

const loadBranchSelections = (): BranchSelectionsStore => {
    const json = localStorage.getItem(BRANCH_SELECTIONS_KEY);
    if (!json) return {};
    try {
        const parsed = JSON.parse(json) as BranchSelectionsStore;
        return parsed ?? {};
    } catch (error) {
        log.error("Failed to parse branch selections", error);
        return {};
    }
};

const saveBranchSelections = (store: BranchSelectionsStore) =>
    localStorage.setItem(BRANCH_SELECTIONS_KEY, JSON.stringify(store));

export const getBranchSelections = (rootSessionUuid: string) => {
    const store = loadBranchSelections();
    return store[rootSessionUuid] ?? {};
};

export const setBranchSelection = (
    rootSessionUuid: string,
    selectionKey: string,
    selectedMessageUuid: string,
) => {
    const store = loadBranchSelections();
    const selections = store[rootSessionUuid] ?? {};
    selections[selectionKey] = selectedMessageUuid;
    store[rootSessionUuid] = selections;
    saveBranchSelections(store);
};

export const deleteBranchSelections = (rootSessionUuid: string) => {
    const store = loadBranchSelections();
    delete store[rootSessionUuid];
    saveBranchSelections(store);
};

export const deleteSession = async (sessionUuid: string, chatKey: string) => {
    if (isTauriRuntime()) {
        await deleteSessionNative(sessionUuid, chatKey);
        deleteBranchSelections(sessionUuid);
        return;
    }

    const db = await chatDb();
    const tx = db.transaction(["sessions", "messages"], "readwrite");
    await tx.objectStore("sessions").delete(sessionUuid);

    const messageStore = tx.objectStore("messages");
    const messages = await messageStore.getAll();
    await Promise.all(
        messages
            .filter((message) => message.sessionUuid === sessionUuid)
            .map((message) => messageStore.delete(message.messageUuid)),
    );

    await tx.done;
    deleteBranchSelections(sessionUuid);
};
