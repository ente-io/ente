import DownloadManager from "@/new/photos/services/download";
import { clearFeatureFlagSessionState } from "@/new/photos/services/feature-flags";
import { terminateFaceWorker } from "@/new/photos/services/ml";
import { clearFaceData } from "@/new/photos/services/ml/db";
import mlWorkManager from "@/new/photos/services/ml/mlWorkManager";
import log from "@/next/log";
import { accountLogout } from "@ente/accounts/services/logout";
import { clipService } from "services/clip-service";
import exportService from "./export";

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
        DownloadManager.logout();
    } catch (e) {
        ignoreError("download", e);
    }

    try {
        await clipService.logout();
    } catch (e) {
        ignoreError("CLIP", e);
    }

    try {
        terminateFaceWorker();
    } catch (e) {
        ignoreError("face", e);
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
