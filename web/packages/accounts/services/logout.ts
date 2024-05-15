import { clearCaches } from "@/next/blob-cache";
import log from "@/next/log";
import InMemoryStore from "@ente/shared/storage/InMemoryStore";
import loc } from "@ente/shared/storage/localForage";
import { clearData } from "@ente/shared/storage/localStorage";
import { clearKeys } from "@ente/shared/storage/sessionStorage";
import { logout as remoteLogout } from "../api/user";
import localForage from "@ente/shared/storage/localForage";

/**
 * Logout sequence common to all apps that rely on the accounts package.
 *
 * [Note: Do not throw during logout]
 *
 * This function is guaranteed to not thrown any errors, and will try to
 * independently complete all the steps in the sequence that can be completed.
 * This allows the user to logout and start again even if somehow their account
 * gets in an unexpected state.
 */
export const accountLogout = async () => {
    try {
        await remoteLogout();
    } catch (e) {
        log.error("Ignoring error during POST /users/logout", e);
    }
    try {
        InMemoryStore.clear();
    } catch (e) {
        log.error("Ignoring error when clearing in-memory store", e);
    }
    try {
        clearKeys();
    } catch (e) {
        log.error("Ignoring error when clearing keys", e);
    }
    try {
        clearData();
    } catch (e) {
        log.error("Ignoring error when clearing data", e);
    }
    try {
        await clearCaches();
    } catch (e) {
        log.error("Ignoring error when clearing caches", e);
    }
    try {
        await localForage.clear();
    } catch (e) {
        log.error("Ignoring error when clearing local forage", e);
    }
};
