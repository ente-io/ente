import { savedKeyAttributes } from "ente-accounts/services/accounts-db";
import { boxSeal } from "ente-base/crypto";
import { authenticatedRequestHeaders } from "ente-base/http";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import type { Collection } from "ente-media/collection";

/**
 * Service for handling the join album flow for public collections.
 * This manages the process of joining a public album, including:
 * - Storing album context before authentication
 * - Auto-joining after authentication
 * - Cleaning up stored context
 */

const JOIN_ALBUM_CONTEXT_KEY = "ente_join_album_context";

export interface JoinAlbumContext {
    accessToken: string;
    collectionKey: string; // Base64 encoded collection key for API calls
    collectionKeyHash: string; // Original hash value from URL (base58 or hex)
    collectionID: number;
    accessTokenJWT?: string; // JWT token for password-protected albums
}

/**
 * Store the album context before redirecting to auth.
 * This preserves the album information across the authentication flow.
 */
export const storeJoinAlbumContext = async (
    accessToken: string,
    collectionKey: string,
    collectionKeyHash: string,
    collection: Collection,
) => {
    // Import the function to get saved JWT token for password-protected albums
    const { savedPublicCollectionAccessTokenJWT } = await import(
        "./public-albums-fdb"
    );

    // Get the JWT token if this is a password-protected album
    const accessTokenJWT =
        await savedPublicCollectionAccessTokenJWT(accessToken);

    log.info("[Join Album] Retrieving JWT from storage:", {
        accessToken,
        storageKey: `public-${accessToken}-passkey`,
        hasJWT: !!accessTokenJWT,
        jwtLength: accessTokenJWT?.length,
        jwtPreview: accessTokenJWT
            ? accessTokenJWT.substring(0, 20) + "..."
            : null,
    });

    const context: JoinAlbumContext = {
        accessToken,
        collectionKey,
        collectionKeyHash,
        collectionID: collection.id,
    };

    // Add JWT token if present
    if (accessTokenJWT) {
        context.accessTokenJWT = accessTokenJWT;
    }

    const serializedContext = JSON.stringify(context);
    log.info("[Join Album] Storing serialized context:", {
        contextKeys: Object.keys(context),
        hasJWTInContext: "accessTokenJWT" in context,
        serializedLength: serializedContext.length,
    });

    localStorage.setItem(JOIN_ALBUM_CONTEXT_KEY, serializedContext);
};

/**
 * Retrieve stored album context after authentication.
 * Checks localStorage for the stored context.
 */
export const getJoinAlbumContext = (): JoinAlbumContext | null => {
    const stored = localStorage.getItem(JOIN_ALBUM_CONTEXT_KEY);
    if (!stored) {
        log.info("[Join Album] No stored context found");
        return null;
    }

    try {
        const context = JSON.parse(stored) as JoinAlbumContext;
        log.info("[Join Album] Retrieved context:", {
            contextKeys: Object.keys(context),
            hasJWTInContext: "accessTokenJWT" in context,
            jwtLength: context.accessTokenJWT?.length,
            storedLength: stored.length,
        });
        return context;
    } catch (error) {
        log.error("[Join Album] Failed to parse stored context", error);
        return null;
    }
};

/**
 * Clear the stored album context after successful join or timeout.
 */
export const clearJoinAlbumContext = () => {
    localStorage.removeItem(JOIN_ALBUM_CONTEXT_KEY);
};

/**
 * Check if there's a pending album to join.
 */
export const hasPendingAlbumToJoin = (): boolean => {
    return getJoinAlbumContext() !== null;
};

/**
 * Join a public album by sending the encrypted collection key to the server.
 * This adds the album to the user's collection.
 */
export const joinPublicAlbum = async (
    accessToken: string,
    collectionID: number,
    encryptedKey: string,
    accessTokenJWT?: string,
): Promise<void> => {
    const authHeaders = await authenticatedRequestHeaders();
    const url = await apiURL("/collections/join-link");

    const headers = {
        "Content-Type": "application/json",
        ...authHeaders,
        "X-Auth-Access-Token": accessToken,
        ...(accessTokenJWT && { "X-Auth-Access-Token-JWT": accessTokenJWT }), // Include JWT for password-protected albums
    };

    log.info("[Join Album] API Request:", {
        collectionID,
        hasAccessToken: !!accessToken,
        hasJWT: !!accessTokenJWT,
        jwtLength: accessTokenJWT?.length,
        jwtPreview: accessTokenJWT
            ? accessTokenJWT.substring(0, 20) + "..."
            : null,
        headers: Object.keys(headers),
        hasJWTHeader: "X-Auth-Access-Token-JWT" in headers,
    });

    const response = await fetch(url, {
        method: "POST",
        headers,
        body: JSON.stringify({ collectionID, encryptedKey }),
    });

    if (!response.ok) {
        let errorMessage = `Failed to join album (status: ${response.status})`;
        try {
            const errorData = (await response.json()) as {
                message?: string;
                code?: string;
            };
            errorMessage = errorData.message ?? errorMessage;
        } catch {
            // Ignore parse error, use default message
        }
        throw new Error(errorMessage);
    }
};

/**
 * Process the pending album join after authentication.
 * This should be called after successful sign-in/sign-up.
 *
 * @returns The collection ID if an album was successfully joined, null otherwise
 */
export const processPendingAlbumJoin = async (): Promise<number | null> => {
    const context = getJoinAlbumContext();

    if (!context) {
        return null;
    }

    log.info("[Join Album] Processing with context:", {
        hasAccessToken: !!context.accessToken,
        hasJWT: !!context.accessTokenJWT,
        jwtLength: context.accessTokenJWT?.length,
        collectionID: context.collectionID,
    });

    // If collectionID is 0 (placeholder), we need to fetch the actual collection first
    let collectionID = context.collectionID;
    if (collectionID === 0) {
        // Import the pullCollection function dynamically from the correct module
        const { pullCollection } = await import("./public-collection");
        const { collection } = await pullCollection(
            context.accessToken,
            context.collectionKey,
        );
        collectionID = collection.id;

        // Update the context with the actual collection ID
        const updatedContext = { ...context, collectionID };
        localStorage.setItem(
            "ente_join_album_context",
            JSON.stringify(updatedContext),
        );
    }

    // Get user's key attributes from local storage
    const keyAttributes = savedKeyAttributes();
    if (!keyAttributes) {
        throw new Error(
            "Key attributes not found. Please try logging in again.",
        );
    }

    const publicKey = keyAttributes.publicKey;

    // Encrypt the collection key with user's public key
    // The collection key is already base64 encoded, and boxSeal expects base64
    const encryptedKey = await boxSeal(context.collectionKey, publicKey);

    // Join the album (include JWT token if present for password-protected albums)
    await joinPublicAlbum(
        context.accessToken,
        collectionID,
        encryptedKey,
        context.accessTokenJWT,
    );

    // Clear the context after successful join
    // Note: If any error occurs above, this won't execute and context will be preserved for retry
    clearJoinAlbumContext();

    return collectionID;
};

/**
 * Get the redirect URL for authentication with join album context.
 * This preserves the intent to join an album across the auth flow.
 *
 * Uses albums.ente.io with action=join parameter, which triggers App Links/Universal Links
 * on mobile to automatically open the app if installed. If opened in browser (desktop or
 * app not installed), the web page detects action=join and redirects to web.ente.io for auth.
 */
export const getAuthRedirectURL = (): string => {
    const context = getJoinAlbumContext();
    if (!context) {
        return "/";
    }

    // In development, use localhost
    // In production, use albums.ente.io (configured as App Link/Universal Link)
    const isDevelopment = window.location.hostname === "localhost";
    const albumsAppURL = isDevelopment
        ? "http://localhost:3000"
        : "https://albums.ente.io";

    // Use action=join to indicate this is a join flow
    // For password-protected albums, include JWT as a query parameter
    // The collectionKeyHash is the original hash value from the URL (base58 or hex)
    const jwtParam = context.accessTokenJWT
        ? `&jwt=${encodeURIComponent(context.accessTokenJWT)}`
        : "";
    const redirectURL = `${albumsAppURL}/?action=join&t=${context.accessToken}${jwtParam}#${context.collectionKeyHash}`;

    return redirectURL;
};
