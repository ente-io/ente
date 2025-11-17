import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import type { PublicAlbumsCredentials } from "ente-base/http";
import log from "ente-base/log";
import type { Collection } from "ente-media/collection";
import {
    getAuthRedirectURL,
    storeJoinAlbumContext,
} from "ente-new/albums/services/join-album";
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
            log.error("Missing required data for join album");
            return;
        }

        // Get the original hash directly from the current URL
        const currentHash = window.location.hash.slice(1);

        // Log the current state before attempting to store context
        const hasCredentialsJWT = credentials?.current
            ? !!credentials.current.accessTokenJWT
            : false;
        log.info("[Shared Albums] handleJoinAlbum called:", {
            accessToken,
            isPasswordProtected:
                !!publicCollection.publicURLs[0]?.passwordEnabled,
            hasCredentialsJWT,
        });

        // Check if on mobile and try deep link first
        if (isTouchscreen) {
            const userAgent = navigator.userAgent || "";
            const isIOS =
                userAgent.includes("iPad") ||
                userAgent.includes("iPhone") ||
                userAgent.includes("iPod");
            const isAndroid = userAgent.includes("Android");

            // Build the deep link URL
            // Format: ente://shared-album?accessToken={token}#{hash}
            const deepLinkURL = `ente://shared-album?accessToken=${encodeURIComponent(accessToken)}#${currentHash}`;

            if (isIOS) {
                // For iOS, try universal link first, then custom scheme
                // Universal links work better for app detection
                const universalLink = `https://web.ente.io/shared-albums?accessToken=${encodeURIComponent(accessToken)}#${currentHash}`;

                // Try to open the app using the universal link
                window.location.href = universalLink;

                // Set a timeout to check if we're still on the page
                // If we are, the app didn't open, so proceed with web flow
                setTimeout(async () => {
                    // If this is a password-protected album and we have the JWT, ensure it's saved
                    const jwtToken = credentials?.current?.accessTokenJWT;
                    if (
                        publicCollection.publicURLs[0]?.passwordEnabled &&
                        jwtToken
                    ) {
                        log.info(
                            "[Shared Albums] Ensuring JWT is saved before redirect (iOS)",
                        );
                        await savePublicCollectionAccessTokenJWT(
                            accessToken,
                            jwtToken,
                        );
                    }

                    // Store the album context before redirecting to auth
                    await storeJoinAlbumContext(
                        accessToken,
                        collectionKey,
                        currentHash,
                        publicCollection,
                    );

                    // Redirect to authentication page with join album flag
                    const redirectURL = getAuthRedirectURL();
                    window.location.href = redirectURL;
                }, 2500);
            } else if (isAndroid) {
                // For Android, use intent URL with fallback
                // This provides a smoother experience with automatic fallback
                const intentURL = `intent://shared-album?accessToken=${encodeURIComponent(accessToken)}#${currentHash}#Intent;scheme=ente;package=io.ente.photos;end`;

                // Try to open the app using the intent
                window.location.href = intentURL;

                // Set a timeout as fallback in case intent doesn't work
                setTimeout(async () => {
                    // Check if we're still on the page (app didn't open)
                    if (document.visibilityState === "visible") {
                        // If this is a password-protected album and we have the JWT, ensure it's saved
                        const jwtToken = credentials?.current?.accessTokenJWT;
                        if (
                            publicCollection.publicURLs[0]?.passwordEnabled &&
                            jwtToken
                        ) {
                            log.info(
                                "[Shared Albums] Ensuring JWT is saved before redirect (Android)",
                            );
                            await savePublicCollectionAccessTokenJWT(
                                accessToken,
                                jwtToken,
                            );
                        }

                        // Store the album context before redirecting to auth
                        await storeJoinAlbumContext(
                            accessToken,
                            collectionKey,
                            currentHash,
                            publicCollection,
                        );

                        // Redirect to authentication page with join album flag
                        const redirectURL = getAuthRedirectURL();
                        window.location.href = redirectURL;
                    }
                }, 2500);
            } else {
                // For other mobile devices, try the custom scheme with fallback
                window.location.href = deepLinkURL;

                setTimeout(async () => {
                    if (document.visibilityState === "visible") {
                        // If this is a password-protected album and we have the JWT, ensure it's saved
                        const jwtToken = credentials?.current?.accessTokenJWT;
                        if (
                            publicCollection.publicURLs[0]?.passwordEnabled &&
                            jwtToken
                        ) {
                            log.info(
                                "[Shared Albums] Ensuring JWT is saved before redirect (other mobile)",
                            );
                            await savePublicCollectionAccessTokenJWT(
                                accessToken,
                                jwtToken,
                            );
                        }

                        // Store the album context before redirecting to auth
                        await storeJoinAlbumContext(
                            accessToken,
                            collectionKey,
                            currentHash,
                            publicCollection,
                        );

                        // Redirect to authentication page with join album flag
                        const redirectURL = getAuthRedirectURL();
                        window.location.href = redirectURL;
                    }
                }, 2500);
            }
        } else {
            // Desktop or non-mobile: use the standard web flow
            // If this is a password-protected album and we have the JWT, ensure it's saved
            const jwtToken = credentials?.current?.accessTokenJWT;
            if (publicCollection.publicURLs[0]?.passwordEnabled && jwtToken) {
                log.info(
                    "[Shared Albums] Ensuring JWT is saved before redirect",
                );
                await savePublicCollectionAccessTokenJWT(accessToken, jwtToken);
            }

            // Store the album context before redirecting to auth
            await storeJoinAlbumContext(
                accessToken,
                collectionKey,
                currentHash,
                publicCollection,
            );

            // Redirect to authentication page with join album flag
            const redirectURL = getAuthRedirectURL();
            window.location.href = redirectURL;
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
                window.open("https://web.ente.io", "_blank", "noopener");
            }
        } else {
            // For desktop or other platforms, redirect to web.ente.io
            window.open("https://web.ente.io", "_blank", "noopener");
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
