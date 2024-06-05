import type { AppName } from "@/next/types/app";
import { ACCOUNTS_PAGES, AUTH_PAGES, PHOTOS_PAGES } from "../constants/pages";

export enum APPS {
    PHOTOS = "PHOTOS",
    AUTH = "AUTH",
    ACCOUNTS = "ACCOUNTS",
}

export const appNameToAppNameOld = (appName: AppName): APPS => {
    switch (appName) {
        case "accounts":
            return APPS.ACCOUNTS;
        case "photos":
            return APPS.PHOTOS;
        case "auth":
            return APPS.AUTH;
    }
};

export const CLIENT_PACKAGE_NAMES = new Map([
    [APPS.PHOTOS, "io.ente.photos.web"],
    [APPS.AUTH, "io.ente.auth.web"],
    [APPS.ACCOUNTS, "io.ente.accounts.web"],
]);

export const clientPackageNamePhotosDesktop = "io.ente.photos.desktop";

export const APP_HOMES = new Map([
    [APPS.PHOTOS, PHOTOS_PAGES.GALLERY as string],
    [APPS.AUTH, AUTH_PAGES.AUTH],
    [APPS.ACCOUNTS, ACCOUNTS_PAGES.PASSKEYS],
]);

export const OTT_CLIENTS = new Map([
    [APPS.PHOTOS, "web"],
    [APPS.AUTH, "totp"],
]);
