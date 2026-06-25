import { isTauriRuntime } from "@/services/tauri-runtime";
import log from "ente-base/log";
import {
    secureStorageDelete,
    secureStorageGet,
    secureStorageSet,
} from "../secure-storage";
import { ensureCryptoInit, enteWasm } from "../wasm";

const CHAT_KEY_LOCAL_STORAGE_KEY = "ensu.chatKey";
const LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY = "ensu.chatKey.local";
const CHAT_KEY_FILE_NAME = "chat-keys.json";
const REMOTE_CHAT_KEY_SECURE_STORAGE_KEY = "remoteChatKey.v2";
const LOCAL_CHAT_KEY_SECURE_STORAGE_KEY = "localChatKey.v2";
const LEGACY_ATTACHMENT_KEY_SECURE_STORAGE_KEY = "legacyAttachmentKey.v2";
const LEGACY_REMOTE_CHAT_KEY_SECURE_STORAGE_KEY = "remoteChatKey";
const LEGACY_LOCAL_CHAT_KEY_SECURE_STORAGE_KEY = "localChatKey";

type PersistedChatKeys = { localChatKey?: string };
type LegacyChatKeys = { remoteChatKey?: string; localChatKey?: string };

let _persistedChatKeys: PersistedChatKeys = {};
let _legacyPersistedChatKeys: LegacyChatKeys = {};
let _legacyAttachmentChatKey: string | undefined;
/** All distinct keys discovered during init, before any cleanup. */
let _allDiscoveredLocalChatKeys: string[] = [];
let _chatKeyStoreInitPromise: Promise<void> | undefined;
let _chatKeyStoreInitUserID: number | undefined;

const legacyUserID = () => {
    try {
        const raw = readLocalStorageKey("user");
        if (!raw) return undefined;
        const id = (JSON.parse(raw) as { id?: unknown }).id;
        return typeof id === "number" ? id : undefined;
    } catch {
        return undefined;
    }
};

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

const legacyRemoteChatKeyLocalStorageKeys = () => {
    const keys = [CHAT_KEY_LOCAL_STORAGE_KEY];
    const userID = legacyUserID();
    if (userID) keys.push(`${CHAT_KEY_LOCAL_STORAGE_KEY}.${userID}`);

    if (typeof localStorage !== "undefined") {
        for (let i = 0; i < localStorage.length; i += 1) {
            const key = localStorage.key(i);
            if (
                key?.startsWith(`${CHAT_KEY_LOCAL_STORAGE_KEY}.`) &&
                key !== LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY &&
                !keys.includes(key)
            ) {
                keys.push(key);
            }
        }
    }

    return keys;
};

const legacyRemoteChatKeySecureStorageKeys = () => {
    const userID = legacyUserID();
    return userID
        ? [
              `${REMOTE_CHAT_KEY_SECURE_STORAGE_KEY}.${userID}`,
              `${LEGACY_REMOTE_CHAT_KEY_SECURE_STORAGE_KEY}.${userID}`,
          ]
        : [];
};

const clearLegacyRemoteChatKeyLocalStorage = () =>
    legacyRemoteChatKeyLocalStorageKeys().forEach(removeLocalStorageKey);

const nativeChatKeyPath = async () => {
    const { appDataDir, join } = await import("@tauri-apps/api/path");
    const root = await appDataDir();
    return join(root, CHAT_KEY_FILE_NAME);
};

const readNativeChatKeys = async (): Promise<PersistedChatKeys> => {
    if (!isTauriRuntime()) return {};

    const [{ exists, readFile }, path] = await Promise.all([
        import("@tauri-apps/plugin-fs"),
        nativeChatKeyPath(),
    ]);

    if (!(await exists(path))) return {};

    try {
        const raw = new TextDecoder().decode(await readFile(path));
        const parsed = JSON.parse(raw) as PersistedChatKeys;
        return {
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
    if (!isTauriRuntime()) return;

    const operations: Promise<void>[] = [];
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
    removeLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);

    try {
        const { remove } = await import("@tauri-apps/plugin-fs");
        const path = await nativeChatKeyPath();
        await remove(path);
    } catch {
        // ignore missing legacy file
    }
};

export const initChatKeyStore = async () => {
    if (!isTauriRuntime()) return;

    const userID = legacyUserID();
    if (_chatKeyStoreInitPromise && _chatKeyStoreInitUserID === userID) {
        return _chatKeyStoreInitPromise;
    }

    _chatKeyStoreInitUserID = userID;
    _chatKeyStoreInitPromise = (async () => {
        const remoteStorageKeys = legacyRemoteChatKeySecureStorageKeys();
        const remoteLocalStorageKeys = legacyRemoteChatKeyLocalStorageKeys();
        const [
            secureLocalChatKey,
            secureLegacyAttachmentKey,
            legacySecureLocalChatKey,
            secureRemoteChatKeys,
            nativeKeys,
        ] = await Promise.all([
            secureStorageGet(LOCAL_CHAT_KEY_SECURE_STORAGE_KEY).catch(
                () => undefined,
            ),
            secureStorageGet(LEGACY_ATTACHMENT_KEY_SECURE_STORAGE_KEY).catch(
                () => undefined,
            ),
            secureStorageGet(LEGACY_LOCAL_CHAT_KEY_SECURE_STORAGE_KEY).catch(
                () => undefined,
            ),
            Promise.all(
                remoteStorageKeys.map((key) =>
                    secureStorageGet(key).catch(() => undefined),
                ),
            ),
            readNativeChatKeys(),
        ]);
        const legacyRemoteChatKey =
            secureRemoteChatKeys.find(Boolean) ??
            remoteLocalStorageKeys
                .map((key) => readLocalStorageKey(key))
                .find(Boolean);
        // Prefer localStorage over legacy secure storage for the local key.
        // Pre-v0.1.12 builds only used localStorage, so when both exist the
        // localStorage value is the key that actually encrypted the legacy DB.
        // Stale OS keyring entries from a previous v0.1.12 install can shadow
        // the correct localStorage key if secure storage is checked first.
        const legacyLocalChatKey =
            readLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY) ??
            legacySecureLocalChatKey ??
            nativeKeys.localChatKey;
        const localChatKey =
            secureLocalChatKey ?? legacyLocalChatKey ?? legacyRemoteChatKey;

        _persistedChatKeys = { localChatKey };
        _legacyPersistedChatKeys = {
            remoteChatKey: legacyRemoteChatKey,
            localChatKey: legacyLocalChatKey,
        };
        _legacyAttachmentChatKey = secureLegacyAttachmentKey;

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
                legacyRemoteChatKey,
            ]) {
                if (k && !seen.has(k)) {
                    seen.add(k);
                    all.push(k);
                }
            }
            _allDiscoveredLocalChatKeys = all;
        }

        if (secureLocalChatKey !== localChatKey) {
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
    if (isTauriRuntime()) {
        _persistedChatKeys.localChatKey = chatKey;
        persistNativeChatKeysSoon();
        return;
    }

    clearLegacyRemoteChatKeyLocalStorage();
    writeLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY, chatKey);
};

/**
 * Return the cached local-only chat key (base64), if present.
 */
export const cachedLocalChatKey = (): string | undefined => {
    if (isTauriRuntime()) {
        return _persistedChatKeys.localChatKey;
    }

    return (
        readLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY) ??
        legacyRemoteChatKeyLocalStorageKeys()
            .map((key) => readLocalStorageKey(key))
            .find(Boolean)
    );
};

export const legacyLocalChatKey = (): string | undefined => {
    if (isTauriRuntime()) {
        return _legacyPersistedChatKeys.localChatKey;
    }

    return readLocalStorageKey(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);
};

/**
 * Return all distinct legacy key candidates that might decrypt a legacy DB.
 *
 * Unlike {@link legacyLocalChatKey}, this returns every key found across all
 * legacy storage locations so the migration can try each one. This is needed
 * because stale keys in the OS keyring can shadow the correct key in
 * localStorage.
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
    add(_persistedChatKeys.localChatKey);
    // Include every local chat key discovered during init (before cleanup
    // deleted legacy copies). This ensures we try the raw localStorage key
    // even when stale OS keyring entries shadowed it in the ?? chains.
    for (const k of _allDiscoveredLocalChatKeys) add(k);
    return keys;
};

export const legacyAttachmentChatKey = (): string | undefined =>
    _legacyAttachmentChatKey;

export const setLegacyAttachmentChatKey = async (chatKey?: string) => {
    _legacyAttachmentChatKey = chatKey;
    if (!isTauriRuntime()) return;
    if (chatKey) {
        await secureStorageSet(
            LEGACY_ATTACHMENT_KEY_SECURE_STORAGE_KEY,
            chatKey,
        );
    } else {
        await secureStorageDelete(LEGACY_ATTACHMENT_KEY_SECURE_STORAGE_KEY);
    }
};

/**
 * Get or create the local-only chat encryption key.
 */
export const getOrCreateLocalChatKey = async () => {
    await initChatKeyStore();
    const cached = cachedLocalChatKey();
    if (cached) return cached;

    await ensureCryptoInit();
    const wasm = await enteWasm();
    const chatKey = await wasm.crypto_generate_key();
    setCachedChatKey(chatKey);
    return chatKey;
};
