export interface keyAttributes {
    kekSalt: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
    opsLimit: number;
    memLimit: number;
}

export const ENCRYPTION_CHUNK_SIZE = 4 * 1024 * 1024;
