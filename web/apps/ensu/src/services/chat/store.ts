import log from "ente-base/log";
import { decryptChatPayload, encryptChatPayload } from "./crypto";

const STORAGE_KEY = "ensu.chat.store.v1";
const BRANCH_SELECTIONS_KEY = "ensu.chat.branchSelections.v1";

interface StoredSession {
    sessionUuid: string;
    rootSessionUuid: string;
    branchFromMessageUuid?: string;
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

interface ChatStoreData {
    sessions: StoredSession[];
    messages: StoredMessage[];
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

const nowMicros = () => Date.now() * 1000;

const loadStore = (): ChatStoreData => {
    const json = localStorage.getItem(STORAGE_KEY);
    if (!json) return { sessions: [], messages: [] };

    try {
        const parsed = JSON.parse(json) as Partial<ChatStoreData>;
        return {
            sessions: parsed.sessions ?? [],
            messages: parsed.messages ?? [],
        };
    } catch (error) {
        log.error("Failed to parse chat store", error);
        return { sessions: [], messages: [] };
    }
};

const saveStore = (store: ChatStoreData) =>
    localStorage.setItem(STORAGE_KEY, JSON.stringify(store));

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

export const listSessions = async (chatKey: string): Promise<ChatSession[]> => {
    const { sessions, messages } = loadStore();

    const sortedSessions = [...sessions]
        .filter((session) => !session.isDeleted)
        .sort((a, b) => b.updatedAt - a.updatedAt);

    const sessionsWithTitles = await Promise.all(
        sortedSessions.map(async (session) => {
            const title = await decryptSessionTitle(session, chatKey);

            const sessionMessages = messages
                .filter(
                    (message) =>
                        message.sessionUuid === session.sessionUuid &&
                        !message.isDeleted,
                )
                .sort((a, b) => b.createdAt - a.createdAt);

            let lastMessagePreview: string | undefined;
            const [latest] = sessionMessages;
            if (latest) {
                lastMessagePreview = await decryptMessageText(latest, chatKey);
            }

            return {
                sessionUuid: session.sessionUuid,
                rootSessionUuid: session.rootSessionUuid,
                branchFromMessageUuid: session.branchFromMessageUuid,
                title,
                createdAt: session.createdAt,
                updatedAt: session.updatedAt,
                lastMessagePreview,
            } satisfies ChatSession;
        }),
    );

    return sessionsWithTitles;
};

export const listMessages = async (
    sessionUuid: string,
    chatKey: string,
): Promise<ChatMessage[]> => {
    const { messages } = loadStore();

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
};

export const createSession = async (chatKey: string) => {
    const store = loadStore();
    const now = nowMicros();
    const sessionUuid = crypto.randomUUID();

    const encrypted = await encryptChatPayload({ title: "New chat" }, chatKey);

    const session: StoredSession = {
        sessionUuid,
        rootSessionUuid: sessionUuid,
        createdAt: now,
        updatedAt: now,
        encryptedData: encrypted.encryptedData,
        header: encrypted.header,
    };

    store.sessions.push(session);
    saveStore(store);

    return sessionUuid;
};

export const addMessage = async (
    sessionUuid: string,
    sender: "self" | "assistant",
    text: string,
    chatKey: string,
    parentMessageUuid?: string,
) => {
    const store = loadStore();
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

    store.messages.push(message);

    const session = store.sessions.find(
        (item) => item.sessionUuid === sessionUuid,
    );
    if (session) {
        session.updatedAt = now;

        const currentTitle = await decryptSessionTitle(session, chatKey);
        if (currentTitle === "New chat" && sender === "self") {
            const trimmed = text.trim();
            const title =
                trimmed.length > 0 ? trimmed.slice(0, 40) : "New chat";
            const updated = await encryptChatPayload({ title }, chatKey);
            session.encryptedData = updated.encryptedData;
            session.header = updated.header;
        }
    }

    saveStore(store);

    return messageUuid;
};

export const updateMessage = async (
    messageUuid: string,
    text: string,
    chatKey: string,
) => {
    const store = loadStore();
    const message = store.messages.find(
        (item) => item.messageUuid === messageUuid,
    );
    if (!message) return;

    const encrypted = await encryptChatPayload({ text }, chatKey);
    message.encryptedData = encrypted.encryptedData;
    message.header = encrypted.header;

    const now = nowMicros();
    const session = store.sessions.find(
        (item) => item.sessionUuid === message.sessionUuid,
    );
    if (session) {
        session.updatedAt = now;
    }

    saveStore(store);
};

export const deleteSession = (sessionUuid: string) => {
    const store = loadStore();
    const session = store.sessions.find(
        (item) => item.sessionUuid === sessionUuid,
    );
    const rootSessionUuid = session?.rootSessionUuid ?? sessionUuid;

    store.sessions = store.sessions.filter(
        (item) => item.sessionUuid !== sessionUuid,
    );
    store.messages = store.messages.filter(
        (message) => message.sessionUuid !== sessionUuid,
    );
    saveStore(store);
    deleteBranchSelections(rootSessionUuid);
};
