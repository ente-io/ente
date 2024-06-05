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
