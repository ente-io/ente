/**
 * Get the appropriate URL for "Get Ente" button based on platform.
 *
 * Returns app store URLs for iOS/Android devices, ente.io for desktop.
 */
export const getEnteURL = (isTouchscreen: boolean): string => {
    if (isTouchscreen) {
        // For mobile devices, redirect to app stores
        const userAgent = navigator.userAgent || "";
        const isIOS =
            userAgent.includes("iPad") ||
            userAgent.includes("iPhone") ||
            userAgent.includes("iPod");
        const isAndroid = userAgent.includes("Android");
        const isAltAndroidOS =
            /LineageOS|Graphene|Calyx|\/e\/|eOS|HarmonyOS|Huawei|Fire OS|Silk\//i.test(
                userAgent,
            );

        if (isIOS) {
            return "https://apps.apple.com/app/id1542026904";
        } else if (isAndroid) {
            // Play Store links can bounce or fail on non-Play Android variants.
            if (isAltAndroidOS) return "https://web.ente.io";
            return "https://play.google.com/store/apps/details?id=io.ente.photos";
        }
        // For other touchscreen devices, fall back to web
    }
    // For desktop or other platforms, redirect to ente.io
    return "https://web.ente.io";
};
