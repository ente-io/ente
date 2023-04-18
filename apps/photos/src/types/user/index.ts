import { Subscription } from 'types/billing';

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
export interface KEK {
    key: string;
    opsLimit: number;
    memLimit: number;
}

export interface UpdatedKey {
    kekSalt: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
    memLimit: number;
    opsLimit: number;
}
export interface RecoveryKey {
    masterKeyEncryptedWithRecoveryKey: string;
    masterKeyDecryptionNonce: string;
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
export interface EmailVerificationResponse {
    id: number;
    keyAttributes?: KeyAttributes;
    encryptedToken?: string;
    token?: string;
    twoFactorSessionID: string;
}

export interface TwoFactorVerificationResponse {
    id: number;
    keyAttributes: KeyAttributes;
    encryptedToken?: string;
    token?: string;
}

export interface TwoFactorSecret {
    secretCode: string;
    qrCode: string;
}

export interface TwoFactorRecoveryResponse {
    encryptedSecret: string;
    secretDecryptionNonce: string;
}

export interface FamilyMember {
    email: string;
    usage: number;
    id: string;
    isAdmin: boolean;
}

export interface FamilyData {
    storage: number;
    expiry: number;
    members: FamilyMember[];
}

export interface UserDetails {
    email: string;
    usage: number;
    fileCount: number;
    sharedCollectionCount: number;
    subscription: Subscription;
    familyData?: FamilyData;
}

export interface DeleteChallengeResponse {
    allowDelete: boolean;
    encryptedChallenge: string;
}

export interface GetRemoteStoreValueResponse {
    value: string;
}

export interface UpdateRemoteStoreValueRequest {
    key: string;
    value: string;
}
