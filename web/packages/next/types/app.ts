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
 * Client "package names" for each of the apps.
 *
 * These are used as the identifier in the user agent strings that we send to
 * our own servers.
 */
export const clientPackageName: Record<AppName, string> = {
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
