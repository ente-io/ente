import type { AppName } from "@/next/types/app";

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
