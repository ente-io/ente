import { clearFeatureFlagSessionState } from "@/new/photos/services/feature-flags";
import log from "@/next/log";
import { accountLogout } from "@ente/accounts/services/logout";
import { clipService } from "services/clip-service";
import DownloadManager from "./download";
import exportService from "./export";
import { clearFaceData } from "./face/db";
import mlWorkManager from "./face/mlWorkManager";

/**
 * Logout sequence for the photos app.
 *
 * This function is guaranteed not to throw any errors.
 *
 * See: [Note: Do not throw during logout].
 */
export const photosLogout = async () => {
    const ignoreError = (label: string, e: unknown) =>
        log.error(`Ignoring error during logout (${label})`, e);

    // Terminate any workers before clearing persistent state.
    // See: [Note: Caching IDB instances in separate execution contexts].

    await accountLogout();

    try {
        clearFeatureFlagSessionState();
    } catch (e) {
        ignoreError("feature-flag", e);
    }

    try {
        await DownloadManager.logout();
    } catch (e) {
        ignoreError("download", e);
    }

    try {
        await clipService.logout();
    } catch (e) {
        ignoreError("CLIP", e);
    }

    const electron = globalThis.electron;
    if (electron) {
        try {
            await mlWorkManager.logout();
        } catch (e) {
            ignoreError("ML", e);
        }

        try {
            await clearFaceData();
        } catch (e) {
            ignoreError("face", e);
        }

        try {
            exportService.disableContinuousExport();
        } catch (e) {
            ignoreError("export", e);
        }

        try {
            await electron?.logout();
        } catch (e) {
            ignoreError("electron", e);
        }
    }
};
