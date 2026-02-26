import type { PublicAlbumsCredentials } from "ente-base/http";
import { albumsAppOrigin, photosAppOrigin } from "ente-base/origins";
import type { Collection } from "ente-media/collection";

export interface UseJoinAlbumProps {
    /** Collection to join */
    publicCollection?: Collection;
    /** Access token for the public link */
    accessToken?: string;
    /** Collection key from URL (base64 encoded) */
    collectionKey?: string;
    /** Credentials ref for JWT token access */
    credentials?: React.RefObject<PublicAlbumsCredentials | undefined>;
}

export interface UseJoinAlbumReturn {
    /** Handler for join album action */
    handleJoinAlbum: () => void;
}

/**
 * Build the web app redirect URL for joining an album.
 */
const buildWebRedirectURL = (
    accessToken: string,
    collectionId: number,
    currentHash: string,
    jwtToken?: string,
): string => {
    const webAppURL = photosAppOrigin();
    const jwtParam = jwtToken ? `&jwt=${encodeURIComponent(jwtToken)}` : "";
    return `${webAppURL}/?joinAlbum=${accessToken}&collectionId=${collectionId}${jwtParam}#${currentHash}`;
};

/**
 * Handle the fallback flow when the native app doesn't open.
 * Redirects to web app with all join context in the URL.
 */
const handleWebFallback = (
    accessToken: string,
    collectionId: number,
    currentHash: string,
    jwtToken?: string,
): void => {
    // Redirect to web app with joinAlbum parameter
    // The URL contains all necessary context (token, collectionId, JWT, hash) which will be
    // stored on web.ente.io after the domain transition
    const redirectURL = buildWebRedirectURL(
        accessToken,
        collectionId,
        currentHash,
        jwtToken,
    );
    window.location.href = redirectURL;
};

/**
 * Attempt to open the native app via deep link, with fallback to web.
 * Returns a cleanup function to clear the timeout if needed.
 */
const tryDeepLinkWithFallback = (
    deepLinkURL: string,
    fallbackFn: () => void | Promise<void>,
    timeoutMs = 2500,
): (() => void) => {
    let appOpened = false;

    // Track visibility changes - app opening will hide the page
    const onVisibilityChange = () => {
        if (document.visibilityState === "hidden") {
            appOpened = true;
        }
    };

    // Track page hide - more reliable on some Android browsers
    const onPageHide = () => {
        appOpened = true;
    };

    document.addEventListener("visibilitychange", onVisibilityChange);
    window.addEventListener("pagehide", onPageHide);

    // Try to open the app using the deep link
    // Use assign() instead of href for better compatibility with iOS Safari/PWAs
    window.location.assign(deepLinkURL);

    // Set a timeout to check if the app opened
    const timeoutId = setTimeout(() => {
        if (!appOpened) {
            void fallbackFn();
        }
        cleanup();
    }, timeoutMs);

    const cleanup = () => {
        clearTimeout(timeoutId);
        document.removeEventListener("visibilitychange", onVisibilityChange);
        window.removeEventListener("pagehide", onPageHide);
    };

    // Return cleanup function
    return cleanup;
};

/**
 * Custom hook that provides join album logic and handlers.
 * Components can use this hook and apply their own button styling.
 */
export const useJoinAlbum = ({
    publicCollection,
    accessToken,
    collectionKey,
    credentials,
}: UseJoinAlbumProps): UseJoinAlbumReturn => {
    const handleJoinAlbum = () => {
        if (!publicCollection || !accessToken || !collectionKey) {
            return;
        }

        // Get the original hash directly from the current URL
        const currentHash = window.location.hash.slice(1);
        const jwtToken = credentials?.current?.accessTokenJWT;
        const collectionId = publicCollection.id;

        // Create fallback function for mobile deep linking
        const fallbackToWeb = () => {
            handleWebFallback(accessToken, collectionId, currentHash, jwtToken);
        };

        // Check if on Android and try deep link with custom scheme with action=join parameter.
        // Skip deep linking on iOS - custom URL schemes show an error
        // dialog when the app isn't installed. On iOS Safari, if the photos app
        // is installed, a banner already appears at the top prompting to open in app.
        if (navigator.userAgent.includes("Android")) {
            const albumsHost = new URL(albumsAppOrigin()).host;
            const deepLinkURL = `ente://${albumsHost}/?action=join&t=${encodeURIComponent(accessToken)}#${currentHash}`;

            tryDeepLinkWithFallback(deepLinkURL, fallbackToWeb);
        } else {
            // Desktop and iOS: use the standard web flow directly
            handleWebFallback(accessToken, collectionId, currentHash, jwtToken);
        }
    };

    return { handleJoinAlbum };
};
