import { systemPreferences } from "electron/main";
import log from "../log";

/**
 * Return true if native device lock authentication is available.
 *
 * Currently this uses macOS Touch ID prompt APIs from Electron.
 */
export const isDeviceLockSupported = () => {
    if (process.platform !== "darwin") return false;

    try {
        return systemPreferences.canPromptTouchID();
    } catch (e) {
        log.warn("Failed to determine native device lock availability", e);
        return false;
    }
};

/**
 * Prompt the user to unlock using native device authentication.
 *
 * Returns true on successful authentication. Returns false if unavailable,
 * cancelled, or failed.
 */
export const promptDeviceLock = async (reason: string) => {
    if (!isDeviceLockSupported()) return false;

    try {
        await systemPreferences.promptTouchID(reason);
        return true;
    } catch (e) {
        log.info("Native device lock prompt not completed", e);
        return false;
    }
};
