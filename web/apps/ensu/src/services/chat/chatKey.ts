import { HTTPError } from "ente-base/http";
import { ensureCryptoInit, enteWasm } from "../wasm";
import { ChatKeyNotFoundError, createChatKey, getChatKey } from "./gateway";

const CHAT_KEY_LOCAL_STORAGE_KEY = "ensu.chatKey";
const LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY = "ensu.chatKey.local";

const isTauriRuntime = () =>
    typeof window !== "undefined" &&
    ("__TAURI__" in window || "__TAURI_IPC__" in window);

interface LegacyLocalStorageData {
    chatStoreJson: string | null;
    chatKey: string | null;
}

const readLegacyLocalChatKey = async () => {
    if (!isTauriRuntime()) return undefined;

    try {
        const { invoke } = await import("@tauri-apps/api/core");
        const legacy = await invoke<LegacyLocalStorageData>(
            "read_legacy_localstorage",
        );
        return legacy?.chatKey ?? undefined;
    } catch {
        return undefined;
    }
};

const validateNativeDbKey = async (key: string) => {
    if (!isTauriRuntime()) return true;

    try {
        const { invoke } = await import("@tauri-apps/api/core");
        return await invoke<boolean>("chat_db_validate_key", { keyB64: key });
    } catch {
        return false;
    }
};

/**
 * Return the cached chat key (base64), if present.
 */
export const cachedChatKey = (): string | undefined => {
    if (typeof localStorage === "undefined") return undefined;
    const value = localStorage.getItem(CHAT_KEY_LOCAL_STORAGE_KEY);
    return value ?? undefined;
};

/**
 * Return the cached local-only chat key (base64), if present.
 */
export const cachedLocalChatKey = (): string | undefined => {
    if (typeof localStorage === "undefined") return undefined;
    const value = localStorage.getItem(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);
    return value ?? undefined;
};

export const clearCachedChatKey = () => {
    if (typeof localStorage === "undefined") return;
    localStorage.removeItem(CHAT_KEY_LOCAL_STORAGE_KEY);
};

export const clearLocalChatKey = () => {
    if (typeof localStorage === "undefined") return;
    localStorage.removeItem(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);
};

/**
 * Get (or create) the chat encryption key.
 *
 * The key is stored on the server encrypted with the user's master key.
 */
export const getOrCreateChatKey = async (masterKeyB64: string) => {
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
        localStorage.setItem(CHAT_KEY_LOCAL_STORAGE_KEY, chatKey);
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
            localStorage.setItem(CHAT_KEY_LOCAL_STORAGE_KEY, chatKey);
            return chatKey;
        } catch (error) {
            const httpError = error as HTTPError | undefined;
            if (httpError instanceof HTTPError && httpError.res.status === 409) {
                const remote = await getChatKey();
                const resolved = await wasm.crypto_decrypt_blob(
                    remote.encryptedKey,
                    remote.header,
                    masterKeyB64,
                );
                localStorage.setItem(CHAT_KEY_LOCAL_STORAGE_KEY, resolved);
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
    const cached = cachedLocalChatKey();

    if (isTauriRuntime()) {
        const legacy = await readLegacyLocalChatKey();

        if (cached) {
            if (!legacy || legacy === cached) return cached;

            if (await validateNativeDbKey(cached)) {
                return cached;
            }

            if (await validateNativeDbKey(legacy)) {
                localStorage.setItem(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY, legacy);
                return legacy;
            }

            return cached;
        }

        if (legacy) {
            localStorage.setItem(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY, legacy);
            return legacy;
        }
    }

    if (cached) return cached;

    await ensureCryptoInit();
    const wasm = await enteWasm();
    const chatKey = await wasm.crypto_generate_key();
    if (typeof localStorage !== "undefined") {
        localStorage.setItem(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY, chatKey);
    }
    return chatKey;
};
