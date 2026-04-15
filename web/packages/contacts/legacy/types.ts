export type {
    LegacyContactRecord,
    LegacyContactState,
    LegacyInfo,
    LegacyRecoveryBundle,
    LegacyRecoverySession,
    LegacyRecoveryStatus,
    LegacyUser,
} from "../types";

export interface LegacySuggestedUser {
    id?: number;
    email: string;
}
