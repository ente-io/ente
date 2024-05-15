import { clearCaches } from "@/next/blob-cache";
import log from "@/next/log";
import { Events, eventBus } from "@ente/shared/events";
import InMemoryStore from "@ente/shared/storage/InMemoryStore";
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
        await clearCaches();
    } catch (e) {
        log.error("Ignoring error when clearing caches", e);
    }
    try {
        await clearFiles();
    } catch (e) {
        log.error("Ignoring error when clearing files", e);
    }
    const electron = globalThis.electron;
    if (electron) {
        try {
            await electron.watch.reset();
        } catch (e) {
            log.error("Ignoring error when resetting native folder watches", e);
        }
        try {
            await electron.clearConvertToMP4Results();
        } catch (e) {
            log.error("Ignoring error when clearing convert-to-mp4 results", e);
        }
        try {
            await electron.clearStores();
        } catch (e) {
            log.error("Ignoring error when clearing native stores", e);
        }
    }
    try {
        eventBus.emit(Events.LOGOUT);
    } catch (e) {
        log.error("Ignoring error in event-bus logout handlers", e);
    }
    router.push(PAGES.ROOT);
};
