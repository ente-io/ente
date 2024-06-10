import type { AppName } from "@/next/types/app";
import { AUTH_PAGES, PHOTOS_PAGES } from "@ente/shared/constants/pages";

/**
 * The default page ("home route") for each of our apps.
 *
 * This is where we redirect to after successful authentication.
 */
export const appHomeRoute = (appName: AppName): string => {
    switch (appName) {
        case "accounts":
            return "/passkeys";
        case "auth":
            return AUTH_PAGES.AUTH;
        case "photos":
            return PHOTOS_PAGES.GALLERY;
    }
};
