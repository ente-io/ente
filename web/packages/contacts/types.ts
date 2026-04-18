export interface WrappedRootContactKey {
    encryptedKey: string;
    header: string;
}

export interface ContactDisplayRecord {
    contactId: string;
    contactUserId: number;
    resolvedEmail: string | undefined;
    displayName: string | undefined;
    profilePictureAttachmentID: string | undefined;
    updatedAt: number;
}

export interface ContactLookup {
    userID?: number;
    email?: string;
}

export interface ContactsDisplaySnapshot {
    isHydrated: boolean;
    recordsByUserID: ReadonlyMap<number, ContactDisplayRecord>;
    recordsByEmail: ReadonlyMap<string, ContactDisplayRecord>;
    avatarURLsByContactID: ReadonlyMap<string, string>;
}

export interface ResolvedContactDisplay {
    contactId: string | undefined;
    profilePictureAttachmentID: string | undefined;
    primaryLabel: string;
    actualEmail: string | undefined;
    initial: string;
    source: "contact" | "fallback";
}

export interface ResolvedContactAvatar extends ResolvedContactDisplay {
    avatarURL: string | undefined;
}

export type LegacyContactState =
    | "INVITED"
    | "REVOKED"
    | "ACCEPTED"
    | "CONTACT_LEFT"
    | "CONTACT_DENIED";

export type LegacyRecoveryStatus =
    | "INITIATED"
    | "WAITING"
    | "REJECTED"
    | "RECOVERED"
    | "STOPPED"
    | "READY";

export interface LegacyUser {
    id: number;
    email: string;
}

export interface LegacyContactRecord {
    user: LegacyUser;
    emergencyContact: LegacyUser;
    state: LegacyContactState;
    recoveryNoticeInDays: number;
}

export interface LegacyRecoverySession {
    id: string;
    user: LegacyUser;
    emergencyContact: LegacyUser;
    status: LegacyRecoveryStatus;
    waitTill: number;
    createdAt: number;
}

export interface LegacyInfo {
    contacts: LegacyContactRecord[];
    recoverSessions: LegacyRecoverySession[];
    othersEmergencyContact: LegacyContactRecord[];
    othersRecoverySession: LegacyRecoverySession[];
}

export interface LegacyRecoveryBundle {
    recoveryKey: string;
    userKeyAttributes: Record<string, unknown>;
}
