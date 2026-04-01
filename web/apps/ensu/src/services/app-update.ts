import type { MiniDialogAttributes } from "ente-base/components/MiniDialog";
import log from "ente-base/log";
import { isTauriAppRuntime } from "services/secure-storage";

const oneDay = 24 * 60 * 60 * 1000;

let intervalId: number | undefined;
let inFlightUpdateCheck: Promise<AppUpdateCheckResult> | undefined;
let promptedVersion: string | undefined;

type ShowMiniDialog = (attributes: MiniDialogAttributes) => void;

type AppUpdateCheckResult =
    | { kind: "not-supported" }
    | { kind: "up-to-date" }
    | { kind: "available"; version: string }
    | { kind: "error" };

export const checkForAppUpdates = async (): Promise<AppUpdateCheckResult> => {
    if (!isTauriAppRuntime()) return { kind: "not-supported" };
    if (inFlightUpdateCheck) return inFlightUpdateCheck;

    const run = async (): Promise<AppUpdateCheckResult> => {
        try {
            const { checkUpdate } = await import("@tauri-apps/api/updater");
            const update = await checkUpdate();
            if (!update.shouldUpdate) {
                log.debug(() => "Ensu is already on the latest version");
                return { kind: "up-to-date" };
            }

            const version = update.manifest?.version ?? "unknown";
            return { kind: "available", version };
        } catch (e) {
            log.error("Failed to auto-update Ensu", e);
            return { kind: "error" };
        }
    };

    inFlightUpdateCheck = run().finally(() => {
        inFlightUpdateCheck = undefined;
    });

    return inFlightUpdateCheck;
};

const installAppUpdate = async (version: string) => {
    const [{ installUpdate }, { relaunch }] = await Promise.all([
        import("@tauri-apps/api/updater"),
        import("@tauri-apps/api/process"),
    ]);

    log.info(`Installing Ensu update ${version}`);
    await installUpdate();
    log.info(`Installed Ensu update ${version}, relaunching`);
    await relaunch();
};

const showUpdatePrompt = (showMiniDialog: ShowMiniDialog, version: string) => {
    showMiniDialog({
        title: "Update available",
        message: `Ensu ${version} is available. Would you like to update now?`,
        continue: {
            text: "Update now",
            autoFocus: true,
            action: async () => {
                await installAppUpdate(version);
            },
        },
        cancel: "Later",
        buttonDirection: "row",
    });
};

const checkAndPromptForAppUpdates = async (showMiniDialog: ShowMiniDialog) => {
    const result = await checkForAppUpdates();
    if (result?.kind !== "available") return result;
    if (promptedVersion === result.version) return result;
    promptedVersion = result.version;
    showUpdatePrompt(showMiniDialog, result.version);
    return result;
};

export const handleManualAppUpdateCheck = async (
    showMiniDialog: ShowMiniDialog,
) => {
    const result = await checkForAppUpdates();
    if (!result || result.kind === "not-supported") return;

    if (result.kind === "up-to-date") {
        showMiniDialog({
            title: "Ensu is up to date",
            message: "You're already running the latest available version.",
        });
        return;
    }

    if (result.kind === "available") {
        promptedVersion = result.version;
        showUpdatePrompt(showMiniDialog, result.version);
        return;
    }

    showMiniDialog({
        title: "Update check failed",
        message:
            "We could not check for updates right now. Please try again in a moment.",
    });
};

export const setupAutoAppUpdates = (showMiniDialog: ShowMiniDialog) => {
    if (
        !isTauriAppRuntime() ||
        process.env.NODE_ENV !== "production" ||
        intervalId
    ) {
        return () => {};
    }

    void checkAndPromptForAppUpdates(showMiniDialog);
    intervalId = window.setInterval(() => {
        void checkAndPromptForAppUpdates(showMiniDialog);
    }, oneDay);

    return () => {
        if (intervalId) {
            window.clearInterval(intervalId);
            intervalId = undefined;
        }
    };
};
