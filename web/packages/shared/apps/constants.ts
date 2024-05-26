import { ACCOUNTS_PAGES, AUTH_PAGES, PHOTOS_PAGES } from "../constants/pages";

/**
 * Arbitrary names that we used as keys for indexing various constants
 * corresponding to our apps.
 */
export type AppName = "account" | "albums" | "auth" | "photos";

/**
 * The "home" route for each of our apps.
 *
 * This is where we redirect to, e.g, after successful authentication.
 */
export const appHomeRoute: Record<AppName, string> = {
    account: ACCOUNTS_PAGES.PASSKEYS,
    albums: "/",
    auth: AUTH_PAGES.AUTH,
    photos: PHOTOS_PAGES.GALLERY,
};

export enum APPS {
    PHOTOS = "PHOTOS",
    AUTH = "AUTH",
    ALBUMS = "ALBUMS",
    ACCOUNTS = "ACCOUNTS",
}

export const CLIENT_PACKAGE_NAMES = new Map([
    [APPS.ALBUMS, "io.ente.albums.web"],
    [APPS.PHOTOS, "io.ente.photos.web"],
    [APPS.AUTH, "io.ente.auth.web"],
    [APPS.ACCOUNTS, "io.ente.accounts.web"],
]);

export const clientPackageNamePhotosDesktop = "io.ente.photos.desktop";

export const APP_TITLES = new Map([
    [APPS.ALBUMS, "Ente Albums"],
    [APPS.PHOTOS, "Ente Photos"],
    [APPS.AUTH, "Ente Auth"],
    [APPS.ACCOUNTS, "Ente Accounts"],
]);

export const APP_HOMES = new Map([
    [APPS.ALBUMS, "/"],
    [APPS.PHOTOS, PHOTOS_PAGES.GALLERY],
    [APPS.AUTH, AUTH_PAGES.AUTH],
    [APPS.ACCOUNTS, ACCOUNTS_PAGES.PASSKEYS],
]);

export const OTT_CLIENTS = new Map([
    [APPS.PHOTOS, "web"],
    [APPS.AUTH, "totp"],
]);
