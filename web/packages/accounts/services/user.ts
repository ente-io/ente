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
        try {
            await _logout();
        } catch (e) {
            // ignore
        }
        try {
            InMemoryStore.clear();
        } catch (e) {
            // ignore
            log.error("clear InMemoryStore failed", e);
        }
        try {
            clearKeys();
        } catch (e) {
            log.error("clearKeys failed", e);
        }
        try {
            clearData();
        } catch (e) {
            log.error("clearData failed", e);
        }
        try {
            await deleteAllCache();
        } catch (e) {
            log.error("deleteAllCache failed", e);
        }
        try {
            await clearFiles();
        } catch (e) {
            log.error("clearFiles failed", e);
        }
        try {
            globalThis.electron?.clearElectronStore();
        } catch (e) {
            log.error("clearElectronStore failed", e);
        }
        try {
            eventBus.emit(Events.LOGOUT);
        } catch (e) {
            log.error("Error in logout handlers", e);
        }
        router.push(PAGES.ROOT);
    } catch (e) {
        log.error("logoutUser failed", e);
    }
};
