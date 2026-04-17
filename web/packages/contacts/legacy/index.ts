export {
    legacyAddContact,
    legacyApproveRecovery,
    legacyChangePassword,
    legacyGetInfo,
    legacyPublicKey,
    legacyRecoveryBundle,
    legacyRejectRecovery,
    legacyStartRecovery,
    legacyStopRecovery,
    legacyUpdateContact,
    legacyUpdateRecoveryNotice,
    legacyVerificationID,
} from "../index";
export { LegacyDrawerContent } from "./components/LegacyDrawerContent";
export { mergeLegacySuggestedUsers } from "./suggestions";
export type {
    LegacyContactRecord,
    LegacyContactState,
    LegacyInfo,
    LegacyRecoveryBundle,
    LegacyRecoverySession,
    LegacyRecoveryStatus,
    LegacySuggestedUser,
    LegacyUser,
} from "./types";
