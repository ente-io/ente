import { appName } from "@/base/app";
import { AUTH_PAGES, PHOTOS_PAGES } from "@ente/shared/constants/pages";

/**
 * The default page ("home route") for each of our apps.
 *
 * This is where we redirect to after successful authentication.
 */
export const appHomeRoute: string = {
    accounts: "/passkeys",
    auth: AUTH_PAGES.AUTH,
    cast: "/" /* The cast app doesn't use this, this is an arbitrary value. */,
    photos: PHOTOS_PAGES.GALLERY,
}[appName];
