import { HTTPError } from "ente-base/http";
import { ensureCryptoInit, enteWasm } from "../wasm";
import { ChatKeyNotFoundError, createChatKey, getChatKey } from "./gateway";
import {
    isTauriAppRuntime,
    secureStorageDelete,
    secureStorageGet,
    secureStorageSet,
} from "../secure-storage";

const CHAT_KEY_LOCAL_STORAGE_KEY = "ensu.chatKey";
const LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY = "ensu.chatKey.local";
const CHAT_KEY_FILE_NAME = "chat-keys.json";
const REMOTE_CHAT_KEY_SECURE_STORAGE_KEY = "remoteChatKey";
const LOCAL_CHAT_KEY_SECURE_STORAGE_KEY = "localChatKey";

type PersistedChatKeys = {
    remoteChatKey?: string;
    localChatKey?: string;
};

let _persistedChatKeys: PersistedChatKeys = {};
let _chatKeyStoreInitPromise: Promise<void> | undefined;

const readLocalStorageKey = (key: string) => {
    if (typeof localStorage === "undefined") return undefined;
    return localStorage.getItem(key) ?? undefined;
};

const writeLocalStorageKey = (key: string, value: string) => {
    if (typeof localStorage === "undefined") return;
    localStorage.setItem(key, value);
};

const removeLocalStorageKey = (key: string) => {
    if (typeof localStorage === "undefined") return;
    localStorage.removeItem(key);
};

const nativeChatKeyPath = async () => {
    const { appDataDir, join } = await import("@tauri-apps/api/path");
    const root = await appDataDir();
    return join(root, CHAT_KEY_FILE_NAME);
};

const readNativeChatKeys = async (): Promise<PersistedChatKeys> => {
    if (!isTauriAppRuntime()) return {};

    const [{ exists, readBinaryFile }, path] = await Promise.all([
        import("@tauri-apps/api/fs"),
        nativeChatKeyPath(),
    ]);

    if (!(await exists(path))) return {};

    try {
        const raw = new TextDecoder().decode(await readBinaryFile(path));
        const parsed = JSON.parse(raw) as PersistedChatKeys;
        return {
            remoteChatKey:
                typeof parsed.remoteChatKey === "string"
                    ? parsed.remoteChatKey
                    : undefined,
            localChatKey:
                typeof parsed.localChatKey === "string"
                    ? parsed.localChatKey
                    : undefined,
        };
    } catch {
        return {};
    }
};

const persistNativeChatKeys = async () => {
    if (!isTauriAppRuntime()) return;

    const operations: Promise<void>[] = [];
    if (_persistedChatKeys.remoteChatKey) {
        operations.push(
            secureStorageSet(
                REMOTE_CHAT_KEY_SECURE_STORAGE_KEY,
                _persistedChatKeys.remoteChatKey,
            ),
        );
    } else {
        operations.push(secureStorageDelete(REMOTE_CHAT_KEY_SECURE_STORAGE_KEY));
    }

    if (_persistedChatKeys.localChatKey) {
        operations.push(
            secureStorageSet(
                LOCAL_CHAT_KEY_SECURE_STORAGE_KEY,
                _persistedChatKeys.localChatKey,
            ),
        );
    } else {
        operations.push(secureStorageDelete(LOCAL_CHAT_KEY_SECURE_STORAGE_KEY));
    }

    await Promise.all(operations);
};

const persistNativeChatKeysSoon = () => {
    persistNativeChatKeys().catch(() => {
        // Best effort cache persistence.
    });
};

export const initChatKeyStore = async () => {
    if (!isTauriAppRuntime()) return;

    _chatKeyStoreInitPromise ??= (async () => {
        const [secureRemoteChatKey, secureLocalChatKey, nativeKeys] =
            await Promise.all([
                secureStorageGet(
                    REMOTE_CHAT_KEY_SECURE_STORAGE_KEY,
                ).catch(() => undefined),
                secureStorageGet(
                    LOCAL_CHAT_KEY_SECURE_STORAGE_KEY,
                ).catch(() => undefined),
                readNativeChatKeys(),
            ]);
        const remoteChatKey =
            secureRemoteChatKey ??
            nativeKeys.remoteChatKey ??
            readLocalStorageKey(CHAT_KEY_LOCAL_STORAGE_KEY);
        const localChatKey =
            secureLocalChatKey ??
            nativeKeys.localChatKey ??
            readLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);

        _persistedChatKeys = { remoteChatKey, localChatKey };

        if (
            secureRemoteChatKey !== remoteChatKey ||
            secureLocalChatKey !== localChatKey
        ) {
            try {
                await persistNativeChatKeys();
                removeLocalStorageKey(CHAT_KEY_LOCAL_STORAGE_KEY);
                removeLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);
            } catch {
                // Keep legacy localStorage keys when secure storage is unavailable.
            }
        } else {
            removeLocalStorageKey(CHAT_KEY_LOCAL_STORAGE_KEY);
            removeLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);
        }

        try {
            const { removeFile } = await import("@tauri-apps/api/fs");
            const path = await nativeChatKeyPath();
            await removeFile(path);
        } catch {
            // ignore missing legacy file
        }
    })().catch((error) => {
        _chatKeyStoreInitPromise = undefined;
        throw error;
    });

    return _chatKeyStoreInitPromise;
};

const setCachedChatKey = (chatKey: string) => {
    if (isTauriAppRuntime()) {
        _persistedChatKeys.remoteChatKey = chatKey;
        persistNativeChatKeysSoon();
        return;
    }

    writeLocalStorageKey(CHAT_KEY_LOCAL_STORAGE_KEY, chatKey);
};

const setCachedLocalChatKey = (chatKey: string) => {
    if (isTauriAppRuntime()) {
        _persistedChatKeys.localChatKey = chatKey;
        persistNativeChatKeysSoon();
        return;
    }

    writeLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY, chatKey);
};

/**
 * Return the cached chat key (base64), if present.
 */
export const cachedChatKey = (): string | undefined => {
    if (isTauriAppRuntime()) {
        return _persistedChatKeys.remoteChatKey;
    }

    return readLocalStorageKey(CHAT_KEY_LOCAL_STORAGE_KEY);
};

/**
 * Return the cached local-only chat key (base64), if present.
 */
export const cachedLocalChatKey = (): string | undefined => {
    if (isTauriAppRuntime()) {
        return _persistedChatKeys.localChatKey;
    }

    return readLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);
};

export const clearCachedChatKey = () => {
    if (isTauriAppRuntime()) {
        delete _persistedChatKeys.remoteChatKey;
        persistNativeChatKeysSoon();
        return;
    }

    removeLocalStorageKey(CHAT_KEY_LOCAL_STORAGE_KEY);
};

export const clearLocalChatKey = () => {
    if (isTauriAppRuntime()) {
        delete _persistedChatKeys.localChatKey;
        persistNativeChatKeysSoon();
        return;
    }

    removeLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);
};

/**
 * Get (or create) the chat encryption key.
 *
 * The key is stored on the server encrypted with the user's master key.
 */
export const getOrCreateChatKey = async (masterKeyB64: string) => {
    await initChatKeyStore();
    const cached = cachedChatKey();
    if (cached) return cached;

    await ensureCryptoInit();
    const wasm = await enteWasm();

    try {
        const remote = await getChatKey();
        const chatKey = await wasm.crypto_decrypt_blob(
            remote.encryptedKey,
            remote.header,
            masterKeyB64,
        );
        setCachedChatKey(chatKey);
        return chatKey;
    } catch (e) {
        if (!(e instanceof ChatKeyNotFoundError)) throw e;

        const chatKey = await wasm.crypto_generate_key();
        const encrypted = await wasm.crypto_encrypt_blob(chatKey, masterKeyB64);

        try {
            await createChatKey(
                encrypted.encrypted_data,
                encrypted.decryption_header,
            );
            setCachedChatKey(chatKey);
            return chatKey;
        } catch (error) {
            if (error instanceof HTTPError && error.res.status === 409) {
                const remote = await getChatKey();
                const resolved = await wasm.crypto_decrypt_blob(
                    remote.encryptedKey,
                    remote.header,
                    masterKeyB64,
                );
                setCachedChatKey(resolved);
                return resolved;
            }
            throw error;
        }
    }
};

/**
 * Get or create a local-only chat key (used when the user is not signed in).
 */
export const getOrCreateLocalChatKey = async () => {
    await initChatKeyStore();
    const cached = cachedLocalChatKey();
    if (cached) return cached;

    await ensureCryptoInit();
    const wasm = await enteWasm();
    const chatKey = await wasm.crypto_generate_key();
    setCachedLocalChatKey(chatKey);
    return chatKey;
};
