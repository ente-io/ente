import { photosAppOrigin } from "ente-base/origins";

/**
 * Get the appropriate URL for sign up or install based on platform.
 */
export const getSignUpOrInstallURL = (isTouchscreen: boolean): string => {
    if (isTouchscreen) {
        // For mobile devices, redirect to app stores
        const userAgent = navigator.userAgent || "";
        const isIOS =
            userAgent.includes("iPad") ||
            userAgent.includes("iPhone") ||
            userAgent.includes("iPod");
        const isAndroid = userAgent.includes("Android");

        if (isIOS) {
            return "https://apps.apple.com/app/id1542026904";
        } else if (isAndroid) {
            return "https://play.google.com/store/apps/details?id=io.ente.photos";
        }
        // For other touchscreen devices, fall back to web
    }
    // For desktop or other platforms, redirect to photos app
    return photosAppOrigin();
};
