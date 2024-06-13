import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";

/**
 * Arbitrary names that we used as keys for indexing various constants
 * corresponding to our apps that rely on this package.
 */
export type AppName = "accounts" | "auth" | "photos";

/**
 * Static title for the app.
 *
 * This is shown until we have the localized version.
 */
export const appTitle: Record<AppName, string> = {
    accounts: "Ente Accounts",
    auth: "Ente Auth",
    photos: "Ente Photos",
};

/**
 * Client "package names" for each of our apps.
 *
 * These are used as the identifier in the user agent strings that we send to
 * our own servers.
 *
 * In cases where this code works for both a web and a desktop app for the same
 * app (currently only photos), return the platform specific package name.
 */
export const clientPackageName = (appName: AppName): string => {
    if (globalThis.electron) {
        if (appName != "photos")
            throw new Error(`Unsupported desktop appName ${appName}`);
        return clientPackageNamePhotosDesktop;
    }
    return _clientPackageName[appName];
};

export const _clientPackageName: Record<AppName, string> = {
    accounts: "io.ente.accounts.web",
    auth: "io.ente.auth.web",
    photos: "io.ente.photos.web",
};

/** Client package name for the Photos desktop app */
export const clientPackageNamePhotosDesktop = "io.ente.photos.desktop";

/**
 * Properties guaranteed to be present in the AppContext types for apps that are
 * listed in {@link AppName}.
 */
export interface BaseAppContextT {
    /** The unique key for the app. */
    appName: AppName;
    /** Perform the (possibly app specific) logout sequence. */
    logout: () => void;
    /** Show or hide the app's navigation bar. */
    showNavBar: (show: boolean) => void;
    isMobile: boolean;
    setDialogBoxAttributesV2: (attrs: DialogBoxAttributesV2) => void;
}
