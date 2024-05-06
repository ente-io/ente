import { getData, LS_KEYS } from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";
import { UserDetails } from "types/user";

export function getLocalUserDetails(): UserDetails {
    return getData(LS_KEYS.USER_DETAILS)?.value;
}

export const isInternalUser = () => {
    const userEmail = getData(LS_KEYS.USER)?.email;
    if (!userEmail) return false;

    return userEmail.endsWith("@ente.io");
};

export const isInternalUserForML = () => {
    const userId = (getData(LS_KEYS.USER) as User)?.id;
    if (userId == 1) return true;

    return isInternalUser();
};
