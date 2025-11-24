import { useIsTouchscreen } from "ente-base/components/utils/hooks";
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
    currentHash: string,
    jwtToken?: string,
): string => {
    const webAppURL = photosAppOrigin();
    const jwtParam = jwtToken ? `&jwt=${encodeURIComponent(jwtToken)}` : "";
    return `${webAppURL}/?joinAlbum=${accessToken}${jwtParam}#${currentHash}`;
};

/**
 * Handle the fallback flow when the native app doesn't open.
 * Redirects to web app with all join context in the URL.
 */
const handleWebFallback = (
    accessToken: string,
    currentHash: string,
    jwtToken?: string,
): void => {
    // Redirect to web app with joinAlbum parameter
    // The URL contains all necessary context (token, JWT, hash) which will be
    // stored on web.ente.io after the domain transition
    const redirectURL = buildWebRedirectURL(accessToken, currentHash, jwtToken);
    window.location.href = redirectURL;
};

/**
 * Attempt to open the native app via deep link, with fallback to web.
 * Returns a cleanup function to clear the timeout if needed.
 */
const tryDeepLinkWithFallback = (
    deepLinkURL: string,
    fallbackFn: () => void | Promise<void>,
    options: {
        /** Check this condition before executing fallback (always true for iOS) */
        shouldFallback?: () => boolean;
    } = {},
): (() => void) => {
    const { shouldFallback = () => true } = options;

    // Try to open the app using the deep link
    window.location.href = deepLinkURL;

    // Set a timeout to check if the app opened
    const timeoutId = setTimeout(() => {
        if (shouldFallback()) {
            void fallbackFn();
        }
    }, 2500);

    // Return cleanup function
    return () => clearTimeout(timeoutId);
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
    const isTouchscreen = useIsTouchscreen();

    const handleJoinAlbum = () => {
        if (!publicCollection || !accessToken || !collectionKey) {
            return;
        }

        // Get the original hash directly from the current URL
        const currentHash = window.location.hash.slice(1);
        const jwtToken = credentials?.current?.accessTokenJWT;

        // Create fallback function for mobile deep linking
        const fallbackToWeb = () => {
            handleWebFallback(accessToken, currentHash, jwtToken);
        };

        // Check if on mobile and try deep link first
        if (isTouchscreen) {
            // Extract hostname from albumsAppOrigin for deep linking
            const albumsHost = new URL(albumsAppOrigin()).host;

            // For all mobile devices, use custom scheme with action=join parameter
            // Format: ente://HOST/?action=join&t=TOKEN#HASH
            const deepLinkURL = `ente://${albumsHost}/?action=join&t=${encodeURIComponent(accessToken)}#${currentHash}`;

            tryDeepLinkWithFallback(deepLinkURL, fallbackToWeb, {
                // Only fallback if page is still visible (app didn't open)
                shouldFallback: () =>
                    document.visibilityState === "visible",
            });
        } else {
            // Desktop: use the standard web flow directly
            handleWebFallback(accessToken, currentHash, jwtToken);
        }
    };

    return { handleJoinAlbum };
};
