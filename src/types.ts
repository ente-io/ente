export interface KeyAttributes {
    kekSalt: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
    opsLimit: number;
    memLimit: number;
    publicKey: string;
    encryptedSecretKey: string;
    secretKeyDecryptionNonce: string;
    masterKeyEncryptedWithRecoveryKey: string;
    masterKeyDecryptionNonce: string;
    recoveryKeyEncryptedWithMasterKey: string;
    recoveryKeyDecryptionNonce: string;
}

export const ENCRYPTION_CHUNK_SIZE = 4 * 1024 * 1024;
export const GAP_BTW_TILES = 4;
export const DATE_CONTAINER_HEIGHT = 48;
export const IMAGE_CONTAINER_MAX_HEIGHT = 200;
export const IMAGE_CONTAINER_MAX_WIDTH =
    IMAGE_CONTAINER_MAX_HEIGHT - GAP_BTW_TILES;
export const MIN_COLUMNS = 4;
export const SPACE_BTW_DATES = 44;
