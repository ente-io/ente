import { savedLocalUser } from "ente-accounts/services/accounts-db";
import { HTTPError } from "ente-base/http";
import log from "ente-base/log";
import {
    isTauriAppRuntime,
    secureStorageDelete,
    secureStorageGet,
    secureStorageSet,
} from "../secure-storage";
import { ensureCryptoInit, enteWasm } from "../wasm";
import { ChatKeyNotFoundError, createChatKey, getChatKey } from "./gateway";

const CHAT_KEY_LOCAL_STORAGE_KEY = "ensu.chatKey";
const LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY = "ensu.chatKey.local";
const CHAT_KEY_FILE_NAME = "chat-keys.json";
const REMOTE_CHAT_KEY_SECURE_STORAGE_KEY = "remoteChatKey.v2";
const LOCAL_CHAT_KEY_SECURE_STORAGE_KEY = "localChatKey.v2";
const LEGACY_REMOTE_CHAT_KEY_SECURE_STORAGE_KEY = "remoteChatKey";
const LEGACY_LOCAL_CHAT_KEY_SECURE_STORAGE_KEY = "localChatKey";

type PersistedChatKeys = { remoteChatKey?: string; localChatKey?: string };

let _persistedChatKeys: PersistedChatKeys = {};
let _legacyPersistedChatKeys: PersistedChatKeys = {};
/** All distinct keys discovered during init, before any cleanup. */
let _allDiscoveredLocalChatKeys: string[] = [];
let _chatKeyStoreInitPromise: Promise<void> | undefined;
let _chatKeyStoreInitUserID: number | undefined;

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

const scopedRemoteChatKeyLocalStorageKey = () => {
    const userID = savedLocalUser()?.id;
    return userID ? `${CHAT_KEY_LOCAL_STORAGE_KEY}.${userID}` : undefined;
};

const scopedRemoteChatKeySecureStorageKey = () => {
    const userID = savedLocalUser()?.id;
    return userID
        ? `${REMOTE_CHAT_KEY_SECURE_STORAGE_KEY}.${userID}`
        : undefined;
};

const scopedLegacyRemoteChatKeySecureStorageKey = () => {
    const userID = savedLocalUser()?.id;
    return userID
        ? `${LEGACY_REMOTE_CHAT_KEY_SECURE_STORAGE_KEY}.${userID}`
        : undefined;
};

const clearLegacyRemoteChatKeyLocalStorage = () =>
    removeLocalStorageKey(CHAT_KEY_LOCAL_STORAGE_KEY);

const clearScopedRemoteChatKeyLocalStorage = () => {
    if (typeof localStorage === "undefined") return;
    const keys = [];
    for (let i = 0; i < localStorage.length; i += 1) {
        const key = localStorage.key(i);
        if (key?.startsWith(`${CHAT_KEY_LOCAL_STORAGE_KEY}.`)) keys.push(key);
    }
    for (const key of keys) localStorage.removeItem(key);
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
    const remoteStorageKey = scopedRemoteChatKeySecureStorageKey();
    if (remoteStorageKey) {
        if (_persistedChatKeys.remoteChatKey) {
            operations.push(
                secureStorageSet(
                    remoteStorageKey,
                    _persistedChatKeys.remoteChatKey,
                ),
            );
        } else {
            operations.push(secureStorageDelete(remoteStorageKey));
        }
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

const cleanupLegacyChatKeyCopies = async () => {
    clearLegacyRemoteChatKeyLocalStorage();
    clearScopedRemoteChatKeyLocalStorage();
    removeLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);

    try {
        const { removeFile } = await import("@tauri-apps/api/fs");
        const path = await nativeChatKeyPath();
        await removeFile(path);
    } catch {
        // ignore missing legacy file
    }
};

export const initChatKeyStore = async () => {
    if (!isTauriAppRuntime()) return;

    const userID = savedLocalUser()?.id;
    if (_chatKeyStoreInitPromise && _chatKeyStoreInitUserID === userID) {
        return _chatKeyStoreInitPromise;
    }

    _chatKeyStoreInitUserID = userID;
    _chatKeyStoreInitPromise = (async () => {
        const remoteStorageKey = scopedRemoteChatKeySecureStorageKey();
        const legacyRemoteStorageKey =
            scopedLegacyRemoteChatKeySecureStorageKey();
        const remoteLocalStorageKey = scopedRemoteChatKeyLocalStorageKey();
        const [
            secureRemoteChatKey,
            secureLocalChatKey,
            legacySecureRemoteChatKey,
            legacySecureLocalChatKey,
            nativeKeys,
        ] = await Promise.all([
            remoteStorageKey
                ? secureStorageGet(remoteStorageKey).catch(() => undefined)
                : Promise.resolve(undefined),
            secureStorageGet(LOCAL_CHAT_KEY_SECURE_STORAGE_KEY).catch(
                () => undefined,
            ),
            legacyRemoteStorageKey
                ? secureStorageGet(legacyRemoteStorageKey).catch(
                      () => undefined,
                  )
                : Promise.resolve(undefined),
            secureStorageGet(LEGACY_LOCAL_CHAT_KEY_SECURE_STORAGE_KEY).catch(
                () => undefined,
            ),
            readNativeChatKeys(),
        ]);
        const legacyRemoteChatKey =
            legacySecureRemoteChatKey ??
            (remoteLocalStorageKey
                ? readLocalStorageKey(remoteLocalStorageKey)
                : undefined);
        // Prefer localStorage over legacy secure storage for the local key.
        // Pre-v0.1.12 builds only used localStorage, so when both exist the
        // localStorage value is the key that actually encrypted the legacy DB.
        // Stale OS keyring entries from a previous v0.1.12 install can shadow
        // the correct localStorage key if secure storage is checked first.
        const legacyLocalChatKey =
            readLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY) ??
            legacySecureLocalChatKey ??
            nativeKeys.localChatKey;
        const remoteChatKey = secureRemoteChatKey ?? legacyRemoteChatKey;
        const localChatKey = secureLocalChatKey ?? legacyLocalChatKey;

        _persistedChatKeys = { remoteChatKey, localChatKey };
        _legacyPersistedChatKeys = {
            remoteChatKey: legacyRemoteChatKey,
            localChatKey: legacyLocalChatKey,
        };

        // Capture every distinct local chat key found across all sources
        // *before* cleanup deletes legacy copies. The migration needs all
        // of these because the ?? chains above can shadow the correct key
        // when stale entries exist in the OS keyring.
        {
            const rawLocalStorage = readLocalStorageKey(
                LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY,
            );
            const seen = new Set<string>();
            const all: string[] = [];
            for (const k of [
                secureLocalChatKey,
                legacySecureLocalChatKey,
                nativeKeys.localChatKey,
                rawLocalStorage,
            ]) {
                if (k && !seen.has(k)) {
                    seen.add(k);
                    all.push(k);
                }
            }
            _allDiscoveredLocalChatKeys = all;
        }

        if (
            secureRemoteChatKey !== remoteChatKey ||
            secureLocalChatKey !== localChatKey
        ) {
            try {
                await persistNativeChatKeys();
            } catch (error) {
                log.warn(
                    "Failed to persist chat keys to secure storage; continuing with in-memory keys",
                    error,
                );
                return;
            }
        }

        try {
            await cleanupLegacyChatKeyCopies();
        } catch (error) {
            log.warn("Failed to clean up legacy chat key copies", error);
        }
    })().catch((error: unknown) => {
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

    clearLegacyRemoteChatKeyLocalStorage();
    const storageKey = scopedRemoteChatKeyLocalStorageKey();
    if (!storageKey) return;
    writeLocalStorageKey(storageKey, chatKey);
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

    clearLegacyRemoteChatKeyLocalStorage();
    const storageKey = scopedRemoteChatKeyLocalStorageKey();
    return storageKey ? readLocalStorageKey(storageKey) : undefined;
};

export const legacyCachedChatKey = (): string | undefined => {
    if (isTauriAppRuntime()) {
        return _legacyPersistedChatKeys.remoteChatKey;
    }

    const storageKey = scopedRemoteChatKeyLocalStorageKey();
    return storageKey ? readLocalStorageKey(storageKey) : undefined;
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

export const legacyLocalChatKey = (): string | undefined => {
    if (isTauriAppRuntime()) {
        return _legacyPersistedChatKeys.localChatKey;
    }

    return readLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);
};

/**
 * Return all distinct legacy key candidates that might decrypt a legacy DB.
 *
 * Unlike {@link legacyLocalChatKey} and {@link legacyCachedChatKey} which
 * return the single "best" key from a prioritized chain, this returns every
 * key found across all legacy storage locations so the migration can try
 * each one. This is needed because stale keys in the OS keyring (secure
 * storage) can shadow the correct key in localStorage.
 */
export const allLegacyKeyCandidates = (): string[] => {
    const seen = new Set<string>();
    const keys: string[] = [];
    const add = (k: string | undefined) => {
        if (k && !seen.has(k)) {
            seen.add(k);
            keys.push(k);
        }
    };
    add(_legacyPersistedChatKeys.remoteChatKey);
    add(_legacyPersistedChatKeys.localChatKey);
    add(_persistedChatKeys.remoteChatKey);
    add(_persistedChatKeys.localChatKey);
    // Include every local chat key discovered during init (before cleanup
    // deleted legacy copies). This ensures we try the raw localStorage key
    // even when stale OS keyring entries shadowed it in the ?? chains.
    for (const k of _allDiscoveredLocalChatKeys) add(k);
    return keys;
};

export const clearCachedChatKey = () => {
    if (isTauriAppRuntime()) {
        delete _persistedChatKeys.remoteChatKey;
        persistNativeChatKeysSoon();
    }

    clearLegacyRemoteChatKeyLocalStorage();
    clearScopedRemoteChatKeyLocalStorage();
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
