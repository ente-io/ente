import ElectronAPIs from "@ente/shared/electron";
import { Events, eventBus } from "@ente/shared/events";
import { logError } from "@ente/shared/sentry";
import InMemoryStore from "@ente/shared/storage/InMemoryStore";
import { deleteAllCache } from "@ente/shared/storage/cacheStorage/helpers";
import { clearFiles } from "@ente/shared/storage/localForage/helpers";
import { clearData } from "@ente/shared/storage/localStorage";
import { clearKeys } from "@ente/shared/storage/sessionStorage";
import isElectron from "is-electron";
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
            logError(e, "clear InMemoryStore failed");
        }
        try {
            clearKeys();
        } catch (e) {
            logError(e, "clearKeys failed");
        }
        try {
            clearData();
        } catch (e) {
            logError(e, "clearData failed");
        }
        try {
            await deleteAllCache();
        } catch (e) {
            logError(e, "deleteAllCache failed");
        }
        try {
            await clearFiles();
        } catch (e) {
            logError(e, "clearFiles failed");
        }
        if (isElectron()) {
            try {
                ElectronAPIs.clearElectronStore();
            } catch (e) {
                logError(e, "clearElectronStore failed");
            }
        }
        try {
            eventBus.emit(Events.LOGOUT);
        } catch (e) {
            logError(e, "Error in logout handlers");
        }
        router.push(PAGES.ROOT);
    } catch (e) {
        logError(e, "logoutUser failed");
    }
};
