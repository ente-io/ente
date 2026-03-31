import log from "ente-base/log";
import { isTauriAppRuntime } from "services/secure-storage";

const oneDay = 24 * 60 * 60 * 1000;

let intervalId: number | undefined;
let inFlightUpdateCheck: Promise<void> | undefined;

const checkForAppUpdates = async () => {
    if (!isTauriAppRuntime()) return;
    if (inFlightUpdateCheck) return inFlightUpdateCheck;

    const run = async () => {
        try {
            const [{ checkUpdate, installUpdate }, { relaunch }] =
                await Promise.all([
                    import("@tauri-apps/api/updater"),
                    import("@tauri-apps/api/process"),
                ]);

            const update = await checkUpdate();
            if (!update.shouldUpdate) {
                log.debug(() => "Ensu is already on the latest version");
                return;
            }

            const version = update.manifest?.version ?? "unknown";
            log.info(`Installing Ensu update ${version}`);
            await installUpdate();
            log.info(`Installed Ensu update ${version}, relaunching`);
            await relaunch();
        } catch (e) {
            log.error("Failed to auto-update Ensu", e);
        }
    };

    inFlightUpdateCheck = run().finally(() => {
        inFlightUpdateCheck = undefined;
    });

    return inFlightUpdateCheck;
};

export const setupAutoAppUpdates = () => {
    if (
        !isTauriAppRuntime() ||
        process.env.NODE_ENV !== "production" ||
        intervalId
    ) {
        return () => {};
    }

    void checkForAppUpdates();
    intervalId = window.setInterval(() => {
        void checkForAppUpdates();
    }, oneDay);

    return () => {
        if (intervalId) {
            window.clearInterval(intervalId);
            intervalId = undefined;
        }
    };
};
