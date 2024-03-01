import { Subscription } from "types/billing";

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

export interface Bonus {
    storage: number;
    type: string;
    validTill: number;
    isRevoked: boolean;
}

export interface BonusData {
    storageBonuses: Bonus[];
}

export interface UserDetails {
    email: string;
    usage: number;
    fileCount: number;
    sharedCollectionCount: number;
    subscription: Subscription;
    familyData?: FamilyData;
    storageBonus?: number;
    bonusData?: BonusData;
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

export interface SRPAttributes {
    srpUserID: string;
    srpSalt: string;
    memLimit: number;
    opsLimit: number;
    kekSalt: string;
    isEmailMFAEnabled: boolean;
}

export interface GetSRPAttributesResponse {
    attributes: SRPAttributes;
}

export interface SRPSetupAttributes {
    srpSalt: string;
    srpVerifier: string;
    srpUserID: string;
    loginSubKey: string;
}

export interface SetupSRPRequest {
    srpUserID: string;
    srpSalt: string;
    srpVerifier: string;
    srpA: string;
}

export interface SetupSRPResponse {
    setupID: string;
    srpB: string;
}

export interface CompleteSRPSetupRequest {
    setupID: string;
    srpM1: string;
}

export interface CompleteSRPSetupResponse {
    setupID: string;
    srpM2: string;
}

export interface CreateSRPSessionResponse {
    sessionID: string;
    srpB: string;
}

export interface GetFeatureFlagResponse {
    disableCFUploadProxy?: boolean;
}
