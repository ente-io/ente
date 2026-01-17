import { base64ToUtf8, utf8ToBase64 } from "../base64";
import { ensureCryptoInit, enteWasm } from "../wasm";

export interface EncryptedChatPayload {
    encryptedData: string;
    header: string;
}

/** Encrypt a JSON payload for storage/sync using the chat key (base64). */
export const encryptChatPayload = async (
    payload: unknown,
    chatKeyB64: string,
): Promise<EncryptedChatPayload> => {
    await ensureCryptoInit();
    const wasm = await enteWasm();

    const plaintextB64 = utf8ToBase64(JSON.stringify(payload));
    const encrypted = await wasm.crypto_encrypt_blob(plaintextB64, chatKeyB64);

    return {
        encryptedData: encrypted.encrypted_data,
        header: encrypted.decryption_header,
    };
};

/** Decrypt a JSON payload using the chat key (base64). */
export const decryptChatPayload = async (
    { encryptedData, header }: EncryptedChatPayload,
    chatKeyB64: string,
): Promise<unknown> => {
    await ensureCryptoInit();
    const wasm = await enteWasm();

    const plaintextB64 = await wasm.crypto_decrypt_blob(
        encryptedData,
        header,
        chatKeyB64,
    );
    return JSON.parse(base64ToUtf8(plaintextB64));
};
