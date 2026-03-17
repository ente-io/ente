import { isDesktop } from "ente-base/app";
import type { AppLockState } from "ente-new/photos/services/app-lock";
import { useRouter } from "next/router";
import { useEffect } from "react";

const APP_LOCK_ROUTE = "/lock";
const APP_LOCK_RETURN_TO_KEY = "appLock.returnToPath";

interface DesktopAppLockRouteState {
    showLockPage: boolean;
    shouldBlockAppLockRouteTransition: boolean;
}

/**
 * Since the app lock has its own separate page, when navigating there,
 * we save the user's current location so they can return to the same
 * page on unlock.
 */
const rememberAppLockReturnTo = (path: string) => {
    if (path === APP_LOCK_ROUTE) return;
    sessionStorage.setItem(APP_LOCK_RETURN_TO_KEY, path);
};

/**
 * Once the user has unlocked the application, navigate them back to the page
 * they were previously on (i.e., the page that was saved when the app locked).
 */

const consumeAppLockReturnTo = (): string | null => {
    const returnTo = sessionStorage.getItem(APP_LOCK_RETURN_TO_KEY);
    sessionStorage.removeItem(APP_LOCK_RETURN_TO_KEY);
    return returnTo;
};

export const useDesktopAppLockRoute = (
    isAppLockReady: boolean,
    isLocked: AppLockState["isLocked"],
    lockScreenMode: AppLockState["lockScreenMode"],
): DesktopAppLockRouteState => {
    const router = useRouter();
    const showLockPage = isDesktop && isLocked && lockScreenMode === "lock";

    /**
     * This useEffect runs when you are not in the /lock route,
     * it saves the current route in sessionStorage
     * and redirects the app to the /lock page.
     */
    useEffect(() => {
        /**
         * Since the app lock is currently available only on desktop,
         * ensure that it is ready before navigating to the lock page.
         */
        if (!isDesktop || !isAppLockReady || !showLockPage) return;

        // if the current page is not of the applock then saving it before navigation.
        if (router.asPath !== APP_LOCK_ROUTE) {
            rememberAppLockReturnTo(router.asPath);
        }

        // if the current page is not applock, then navgiating to the applock page.
        if (router.pathname !== APP_LOCK_ROUTE) {
            void router.replace(APP_LOCK_ROUTE);
        }
    }, [isAppLockReady, showLockPage, router, router.asPath, router.pathname]);

    /**
     * This useEffect is just returning you to the page in which you where before
     * the app lock happened.
     */
    useEffect(() => {
        if (
            !isDesktop ||
            !isAppLockReady ||
            showLockPage ||
            router.pathname !== APP_LOCK_ROUTE
        ) {
            return;
        }

        const returnTo = consumeAppLockReturnTo();
        void router.replace(
            returnTo && returnTo !== APP_LOCK_ROUTE ? returnTo : "/gallery",
        );
    }, [isAppLockReady, showLockPage, router, router.pathname]);

    return {
        showLockPage,
        shouldBlockAppLockRouteTransition:
            isDesktop &&
            isAppLockReady &&
            ((showLockPage && router.pathname !== APP_LOCK_ROUTE) ||
                (!showLockPage && router.pathname === APP_LOCK_ROUTE)),
    };
};
