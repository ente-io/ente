import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import type { PublicAlbumsCredentials } from "ente-base/http";
import { photosAppOrigin } from "ente-base/origins";
import type { Collection } from "ente-media/collection";
import { storeJoinAlbumContext } from "ente-new/albums/services/join-album";
import { savePublicCollectionAccessTokenJWT } from "ente-new/albums/services/public-albums-fdb";
import { t } from "i18next";

export interface UseJoinAlbumProps {
    /** If true, enables "Join Album" functionality */
    enableJoin?: boolean;
    /** Collection to join (required if enableJoin is true) */
    publicCollection?: Collection;
    /** Access token for the public link */
    accessToken?: string;
    /** Collection key from URL (base64 encoded) */
    collectionKey?: string;
    /** Credentials ref for JWT token access */
    // eslint-disable-next-line @typescript-eslint/no-deprecated
    credentials?: React.MutableRefObject<PublicAlbumsCredentials | undefined>;
}

export interface UseJoinAlbumReturn {
    /** Handler for join album action */
    handleJoinAlbum: () => Promise<void>;
    /** Handler for sign up/install action */
    handleSignUpOrInstall: () => void;
    /** Text to display on the button */
    buttonText: string;
    /** Whether join album is enabled */
    isJoinEnabled: boolean;
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
 * Saves JWT if needed, stores album context, and redirects to web auth.
 */
const handleWebFallback = async (
    accessToken: string,
    collectionKey: string,
    currentHash: string,
    publicCollection: Collection,
    jwtToken?: string,
): Promise<void> => {
    // If this is a password-protected album and we have the JWT, ensure it's saved
    if (publicCollection.publicURLs[0]?.passwordEnabled && jwtToken) {
        await savePublicCollectionAccessTokenJWT(accessToken, jwtToken);
    }

    // Store the album context before redirecting to auth
    await storeJoinAlbumContext(
        accessToken,
        collectionKey,
        currentHash,
        publicCollection,
    );

    // Redirect to web app with joinAlbum parameter
    const redirectURL = buildWebRedirectURL(accessToken, currentHash, jwtToken);
    window.location.href = redirectURL;
};

/**
 * Attempt to open the native app via deep link, with fallback to web.
 * Returns a cleanup function to clear the timeout if needed.
 */
const tryDeepLinkWithFallback = (
    deepLinkURL: string,
    fallbackFn: () => Promise<void>,
    options: {
        /** Check this condition before executing fallback (always true for iOS) */
        shouldFallback?: () => boolean;
    } = {},
): (() => void) => {
    const { shouldFallback = () => true } = options;

    // Try to open the app using the deep link
    window.location.href = deepLinkURL;

    // Set a timeout to check if the app opened
    const timeoutId = setTimeout(async () => {
        if (shouldFallback()) {
            await fallbackFn();
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
    enableJoin,
    publicCollection,
    accessToken,
    collectionKey,
    credentials,
}: UseJoinAlbumProps): UseJoinAlbumReturn => {
    const isTouchscreen = useIsTouchscreen();

    const handleJoinAlbum = async () => {
        if (!publicCollection || !accessToken || !collectionKey) {
            return;
        }

        // Get the original hash directly from the current URL
        const currentHash = window.location.hash.slice(1);
        const jwtToken = credentials?.current?.accessTokenJWT;

        // Create fallback function for mobile deep linking
        const fallbackToWeb = async () => {
            await handleWebFallback(
                accessToken,
                collectionKey,
                currentHash,
                publicCollection,
                jwtToken,
            );
        };

        // Check if on mobile and try deep link first
        if (isTouchscreen) {
            const userAgent = navigator.userAgent || "";
            const isIOS =
                userAgent.includes("iPad") ||
                userAgent.includes("iPhone") ||
                userAgent.includes("iPod");
            const isAndroid = userAgent.includes("Android");

            if (isIOS) {
                // For iOS, use universal link (better for app detection)
                const universalLink = `${photosAppOrigin()}/shared-albums?accessToken=${encodeURIComponent(accessToken)}#${currentHash}`;

                tryDeepLinkWithFallback(universalLink, fallbackToWeb);
            } else if (isAndroid) {
                // For Android, use intent URL with automatic fallback
                const intentURL = `intent://shared-album?accessToken=${encodeURIComponent(accessToken)}#${currentHash}#Intent;scheme=ente;package=io.ente.photos;end`;

                tryDeepLinkWithFallback(intentURL, fallbackToWeb, {
                    // Only fallback if page is still visible (app didn't open)
                    shouldFallback: () =>
                        document.visibilityState === "visible",
                });
            } else {
                // For other mobile devices, use custom scheme
                const deepLinkURL = `ente://shared-album?accessToken=${encodeURIComponent(accessToken)}#${currentHash}`;

                tryDeepLinkWithFallback(deepLinkURL, fallbackToWeb, {
                    shouldFallback: () =>
                        document.visibilityState === "visible",
                });
            }
        } else {
            // Desktop: use the standard web flow directly
            await handleWebFallback(
                accessToken,
                collectionKey,
                currentHash,
                publicCollection,
                jwtToken,
            );
        }
    };

    const handleSignUpOrInstall = () => {
        if (typeof window === "undefined") return;

        if (isTouchscreen) {
            // For mobile devices, redirect to app stores
            const userAgent = navigator.userAgent || "";
            const isIOS =
                userAgent.includes("iPad") ||
                userAgent.includes("iPhone") ||
                userAgent.includes("iPod");
            const isAndroid = userAgent.includes("Android");

            if (isIOS) {
                window.open(
                    "https://apps.apple.com/app/id1542026904",
                    "_blank",
                    "noopener",
                );
            } else if (isAndroid) {
                window.open(
                    "https://play.google.com/store/apps/details?id=io.ente.photos",
                    "_blank",
                    "noopener",
                );
            } else {
                // For other touchscreen devices, fall back to web
                window.open(photosAppOrigin(), "_blank", "noopener");
            }
        } else {
            // For desktop or other platforms, redirect to photos app
            window.open(photosAppOrigin(), "_blank", "noopener");
        }
    };

    const buttonText = enableJoin
        ? t("join_album")
        : isTouchscreen
          ? t("install")
          : t("sign_up");

    return {
        handleJoinAlbum,
        handleSignUpOrInstall,
        buttonText,
        isJoinEnabled: !!enableJoin,
    };
};
