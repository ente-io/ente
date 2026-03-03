import { systemPreferences } from "electron/main";
import type { NativeDeviceLockCapability } from "../../types/ipc";
import log from "../log";

/**
 * Return native device lock capability for the current platform.
 *
 * Electron currently exposes native prompt APIs only on macOS (Touch ID).
 */
export const getNativeDeviceLockCapability = (): NativeDeviceLockCapability => {
    switch (process.platform) {
        case "darwin":
            try {
                if (systemPreferences.canPromptTouchID()) {
                    return { available: true, provider: "touchid" };
                }

                return {
                    available: false,
                    provider: "none",
                    reason: "touchid-not-enrolled",
                };
            } catch (e) {
                log.warn(
                    "Failed to determine native device lock availability",
                    e,
                );
                return {
                    available: false,
                    provider: "none",
                    reason: "touchid-api-error",
                };
            }

        default:
            return {
                available: false,
                provider: "none",
                reason: "unsupported-platform",
            };
    }
};

/**
 * Prompt the user to unlock using native device authentication.
 *
 * Returns true on successful authentication. Returns false if unavailable,
 * cancelled, or failed.
 */
export const promptDeviceLock = async (reason: string) => {
    const capability = getNativeDeviceLockCapability();

    if (!capability.available || capability.provider !== "touchid") {
        log.warn("Native device lock prompt is unavailable on this OS");
        return false;
    }

    try {
        await systemPreferences.promptTouchID(reason);
        return true;
    } catch (e) {
        log.info("Native device lock prompt not completed", e);
        return false;
    }
};
