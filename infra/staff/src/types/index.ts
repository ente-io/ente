export interface User {
    ID: string;
    email: string;
    creationTime: number;
}

export interface UserResponse {
    user: User;
    subscription: Subscription;
    authCodes?: number;
    details?: { usage?: number; storageBonus?: number; profileData: Security };
}

export interface UserData {
    user: Record<string, string>;
    storage: Record<string, string>;
    subscription: Record<string, string>;
    security: Record<string, string>;
}

export interface UserComponentProps {
    userData: UserData | null;
}

export interface ErrorResponse {
    message: string;
}

export interface Subscription {
    productID: string;
    paymentProvider: string;
    expiryTime: number;
    storage: number;
}

export interface Security {
    isEmailMFAEnabled: boolean;
    isTwoFactorEnabled: boolean;
    passkeys: string;
    passkeyCount: number;
    canDisableEmailMFA: boolean;
}

export interface FamilyMember {
    id: string;
    email: string;
    status: string;
    usage: number;
    storageLimit: number;
}

export interface DisablePasskeysProps {
    open: boolean;
    handleClose: () => void;
    handleDisablePasskeys: () => void;
}
