export interface keyAttributes {
    kekSalt: string;
    kekHash: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
}

export const ENCRYPTION_CHUNK_SIZE = 4 * 1024 * 1024;
