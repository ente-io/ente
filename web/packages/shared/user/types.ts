export interface KeyAttributes {
    kekSalt: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
    opsLimit: number;
    memLimit: number;
    publicKey: string;
    encryptedSecretKey: string;
    secretKeyDecryptionNonce: string;
    /** Doesn't change after being initially created. */
    masterKeyEncryptedWithRecoveryKey: string;
    masterKeyDecryptionNonce: string;
    /** Doesn't change after being initially created. */
    recoveryKeyEncryptedWithMasterKey: string;
    recoveryKeyDecryptionNonce: string;
}

export interface User {
    id: number;
    email: string;
    token: string;
    encryptedToken: string;
    isTwoFactorEnabled: boolean;
    twoFactorSessionID: string;
}

export interface KEK {
    key: string;
    opsLimit: number;
    memLimit: number;
}
