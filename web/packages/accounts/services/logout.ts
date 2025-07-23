import { clearBlobCaches } from "ente-base/blob-cache";
import { clearKVDB } from "ente-base/kv";
import { clearLocalStorage } from "ente-base/local-storage";
import log from "ente-base/log";
import { clearSessionStorage } from "ente-base/session";
import { clearStashedRedirect } from "./redirect";
import { remoteLogoutIfNeeded } from "./user";

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
    const ignoreError = (label: string, e: unknown) =>
        log.error(`Ignoring error during logout (${label})`, e);

    log.info("logout (account)");

    try {
        await remoteLogoutIfNeeded();
    } catch (e) {
        ignoreError("Remote", e);
    }
    try {
        clearStashedRedirect();
    } catch (e) {
        ignoreError("In-memory store", e);
    }
    try {
        clearSessionStorage();
    } catch (e) {
        ignoreError("Session storage", e);
    }
    try {
        clearLocalStorage();
    } catch (e) {
        ignoreError("Local storage", e);
    }
    try {
        await clearBlobCaches();
    } catch (e) {
        ignoreError("Blob cache", e);
    }
    try {
        await clearKVDB();
    } catch (e) {
        ignoreError("KV DB", e);
    }
};

/**
 * This is a subset of the cleanup of local persistence that has already
 * happened during {@link accountLogout}. However, once the logout sequence is
 * complete, we do these specific steps again to clear any state that might've
 * been persisted meanwhile because of in-flight requests getting completed.
 *
 * Post this, we'll reload the page so that in-flight requests are discarded.
 */
export const logoutClearStateAgain = async () => {
    const ignoreError = (label: string, e: unknown) =>
        log.error(`Ignoring error during logout (${label})`, e);

    log.info("logout (sweep)");

    try {
        clearLocalStorage();
    } catch (e) {
        ignoreError("Local storage", e);
    }
    try {
        await clearKVDB();
    } catch (e) {
        ignoreError("KV DB", e);
    }
};
