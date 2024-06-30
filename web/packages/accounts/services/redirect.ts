import { appName } from "@/next/types/app";
import { AUTH_PAGES, PHOTOS_PAGES } from "@ente/shared/constants/pages";

/**
 * The default page ("home route") for each of our apps.
 *
 * This is where we redirect to after successful authentication.
 */
export const appHomeRoute = {
    accounts: "/passkeys",
    auth: AUTH_PAGES.AUTH,
    photos: PHOTOS_PAGES.GALLERY,
}[appName];
