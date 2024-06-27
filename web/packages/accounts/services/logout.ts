import { clearBlobCaches } from "@/next/blob-cache";
import { clearHTTPState } from "@/next/http";
import log from "@/next/log";
import InMemoryStore from "@ente/shared/storage/InMemoryStore";
import localForage from "@ente/shared/storage/localForage";
import { clearData } from "@ente/shared/storage/localStorage";
import { clearKeys } from "@ente/shared/storage/sessionStorage";
import { clear as clearKV } from "idb-keyval";
import { logout as remoteLogout } from "../api/user";

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

    try {
        await remoteLogout();
    } catch (e) {
        ignoreError("remote", e);
    }
    try {
        InMemoryStore.clear();
    } catch (e) {
        ignoreError("in-memory store", e);
    }
    try {
        clearKeys();
    } catch (e) {
        ignoreError("session store", e);
    }
    try {
        clearData();
    } catch (e) {
        ignoreError("local storage", e);
    }
    try {
        await localForage.clear();
    } catch (e) {
        ignoreError("local forage", e);
    }
    try {
        await clearBlobCaches();
    } catch (e) {
        ignoreError("cache", e);
    }
    try {
        clearHTTPState();
    } catch (e) {
        ignoreError("http", e);
    }
    try {
        await clearKV();
    } catch (e) {
        ignoreError("kv", e);
    }
};
