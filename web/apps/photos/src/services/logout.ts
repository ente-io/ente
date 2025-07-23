import {
    accountLogout,
    logoutClearStateAgain,
} from "ente-accounts/services/logout";
import log from "ente-base/log";
import { logoutFileViewerDataSource } from "ente-gallery/components/viewer/data-source";
import { downloadManager } from "ente-gallery/services/download";
import { clearFilesDB } from "ente-gallery/services/files-db";
import { resetUploadState } from "ente-gallery/services/upload";
import { resetVideoState } from "ente-gallery/services/video";
import exportService from "ente-new/photos/services/export";
import { logoutML, terminateMLWorker } from "ente-new/photos/services/ml";
import { logoutSearch } from "ente-new/photos/services/search";
import { logoutSettings } from "ente-new/photos/services/settings";
import { logoutUserDetails } from "ente-new/photos/services/user-details";
import { uploadManager } from "./upload-manager";

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

    // - Workers

    // Terminate any workers that might access the DB before clearing persistent
    // state. See: [Note: Caching IDB instances in separate execution contexts].

    try {
        await terminateMLWorker();
    } catch (e) {
        ignoreError("ML/worker", e);
    }

    // - Remote logout and clear state

    await accountLogout();

    // - Photos specific logout

    log.info("logout (photos)");

    try {
        await clearFilesDB();
    } catch (e) {
        ignoreError("Files DB", e);
    }

    try {
        logoutSettings();
    } catch (e) {
        ignoreError("Settings", e);
    }

    try {
        logoutUserDetails();
    } catch (e) {
        ignoreError("User details", e);
    }

    try {
        resetUploadState();
    } catch (e) {
        ignoreError("Upload", e);
    }

    try {
        uploadManager.logout();
    } catch (e) {
        ignoreError("Upload", e);
    }

    try {
        downloadManager.logout();
    } catch (e) {
        ignoreError("Download", e);
    }

    try {
        logoutSearch();
    } catch (e) {
        ignoreError("Search", e);
    }

    try {
        resetVideoState();
    } catch (e) {
        ignoreError("Video", e);
    }

    try {
        logoutFileViewerDataSource();
    } catch (e) {
        ignoreError("File viewer", e);
    }

    // - Desktop

    const electron = globalThis.electron;
    if (electron) {
        try {
            await logoutML();
        } catch (e) {
            ignoreError("ML", e);
        }

        try {
            exportService.disableContinuousExport();
        } catch (e) {
            ignoreError("Export", e);
        }

        try {
            await electron.logout();
        } catch (e) {
            ignoreError("Electron", e);
        }
    }

    // Clear the DB again to discard any in-flight completions that might've
    // happened since we started.

    await logoutClearStateAgain();

    try {
        await clearFilesDB();
    } catch (e) {
        ignoreError("Files DB", e);
    }

    // [Note: Full reload on logout]
    //
    // Do a full reload to discard any in-flight requests that might still
    // remain.

    window.location.replace("/");
};
