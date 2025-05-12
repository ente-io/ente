//  Type related Users

export interface User {
    ID: string;
    email: string;
    creationTime: number;
}

export interface UserResponse {
    user: User;
    subscription: Subscription;
    authCodes?: number;
    details?: {
        usage?: number;
        storageBonus?: number;
        profileData: Security;
    };
}

export interface UserData {
    user: Record<string, string>;
    storage: Record<string, string>;
    subscription?: Record<string, string>;
    security: Record<string, string>;
    details?: {
        familyData: {
            members: FamilyMember[];
        };
    };
}

export interface UserComponentProps {
    userData: UserData | null;
}

// Error Response Interface
export interface ErrorResponse {
    message: string;
}

// Types related to Subscriptions
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

// Types related Family
export interface FamilyMember {
    id: string;
    email: string;
    status: string;
    usage: number;
    storageLimit: number;
}

// Types related to passkeys
export interface DisablePasskeysProps {
    open: boolean;
    handleClose: () => void;
    handleDisablePasskeys: () => void; // Callback to handle disabling passkeys
}
