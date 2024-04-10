import log from "@/next/log";
import { Events, eventBus } from "@ente/shared/events";
import InMemoryStore from "@ente/shared/storage/InMemoryStore";
import { deleteAllCache } from "@ente/shared/storage/cacheStorage/helpers";
import { clearFiles } from "@ente/shared/storage/localForage/helpers";
import { clearData } from "@ente/shared/storage/localStorage";
import { clearKeys } from "@ente/shared/storage/sessionStorage";
import router from "next/router";
import { _logout } from "../api/user";
import { PAGES } from "../constants/pages";

export const logoutUser = async () => {
    try {
        await _logout();
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
        await deleteAllCache();
    } catch (e) {
        log.error("Ignoring error when clearing caches", e);
    }
    try {
        await clearFiles();
    } catch (e) {
        log.error("Ignoring error when clearing files", e);
    }
    try {
        globalThis.electron?.clearStores();
    } catch (e) {
        log.error("Ignoring error when clearing electron stores", e);
    }
    try {
        eventBus.emit(Events.LOGOUT);
    } catch (e) {
        log.error("Ignoring error in event-bus logout handlers", e);
    }
    router.push(PAGES.ROOT);
};
