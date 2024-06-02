import { getData, LS_KEYS } from "@ente/shared/storage/localStorage";
import { UserDetails } from "types/user";

export function getLocalUserDetails(): UserDetails {
    return getData(LS_KEYS.USER_DETAILS)?.value;
}
