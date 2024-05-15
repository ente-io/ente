import log from "@/next/log";
import { accountLogout } from "@ente/accounts/services/logout";
import { clipService } from "services/clip-service";
import DownloadManager from "./download";
import exportService from "./export";
import mlWorkManager from "./machineLearning/mlWorkManager";

/**
 * Logout sequence for the photos app.
 *
 * This function is guaranteed not to throw any errors.
 *
 * See: [Note: Do not throw during logout].
 */
export const photosLogout = async () => {
    await accountLogout();

    try {
        await DownloadManager.logout();
    } catch (e) {
        log.error("Ignoring error during logout (download)", e);
    }

    try {
        await clipService.logout();
    } catch (e) {
        log.error("Ignoring error during logout (CLIP)", e);
    }

    const electron = globalThis.electron;
    if (electron) {
        try {
            await mlWorkManager.logout();
        } catch (e) {
            log.error("Ignoring error during logout (ML)", e);
        }

        try {
            exportService.disableContinuousExport();
        } catch (e) {
            log.error("Ignoring error during logout (export)", e);
        }

        try {
            await electron?.logout();
        } catch (e) {
            log.error("Ignoring error during logout (electron)", e);
        }
    }
};
