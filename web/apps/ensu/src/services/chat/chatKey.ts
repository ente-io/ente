import { ensureCryptoInit, enteWasm } from "../wasm";
import { ChatKeyNotFoundError, createChatKey, getChatKey } from "./gateway";

const CHAT_KEY_LOCAL_STORAGE_KEY = "ensu.chatKey";
const LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY = "ensu.chatKey.local";

/**
 * Return the cached chat key (base64), if present.
 */
export const cachedChatKey = (): string | undefined => {
    const value = localStorage.getItem(CHAT_KEY_LOCAL_STORAGE_KEY);
    return value ?? undefined;
};

export const clearCachedChatKey = () => {
    localStorage.removeItem(CHAT_KEY_LOCAL_STORAGE_KEY);
};

export const clearLocalChatKey = () => {
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
        const chatKey = await wasm.crypto_decrypt_box(
            remote.encryptedKey,
            remote.header,
            masterKeyB64,
        );
        localStorage.setItem(CHAT_KEY_LOCAL_STORAGE_KEY, chatKey);
        return chatKey;
    } catch (e) {
        if (!(e instanceof ChatKeyNotFoundError)) throw e;

        const chatKey = await wasm.crypto_generate_key();
        const encrypted = await wasm.crypto_encrypt_box(chatKey, masterKeyB64);

        await createChatKey(encrypted.encrypted_data, encrypted.nonce);
        localStorage.setItem(CHAT_KEY_LOCAL_STORAGE_KEY, chatKey);
        return chatKey;
    }
};

/**
 * Get or create a local-only chat key (used when the user is not signed in).
 */
export const getOrCreateLocalChatKey = async () => {
    const cached = localStorage.getItem(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY);
    if (cached) return cached;

    await ensureCryptoInit();
    const wasm = await enteWasm();
    const chatKey = await wasm.crypto_generate_key();
    localStorage.setItem(LOCAL_CHAT_KEY_LOCAL_STORAGE_KEY, chatKey);
    return chatKey;
};
