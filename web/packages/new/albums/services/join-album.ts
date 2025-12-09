import { savedKeyAttributes } from "ente-accounts/services/accounts-db";
import { ensureLocalUser } from "ente-accounts/services/user";
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

export const JOIN_ALBUM_CONTEXT_KEY = "ente_join_album_context";

export interface JoinAlbumContext {
    accessToken: string;
    collectionKey: string; // Base64 encoded collection key for API calls
    collectionKeyHash: string; // Original hash value from URL (base58 or hex)
    collectionID: number;
    accessTokenJWT?: string; // JWT token for password-protected albums
}

/**
 * Retrieve stored album context after authentication.
 * Checks sessionStorage for the stored context.
 */
export const getJoinAlbumContext = (): JoinAlbumContext | null => {
    const stored = sessionStorage.getItem(JOIN_ALBUM_CONTEXT_KEY);
    if (!stored) {
        return null;
    }

    try {
        const context = JSON.parse(stored) as JoinAlbumContext;
        return context;
    } catch {
        return null;
    }
};

/**
 * Clear the stored album context after successful join or timeout.
 */
export const clearJoinAlbumContext = () => {
    sessionStorage.removeItem(JOIN_ALBUM_CONTEXT_KEY);
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

    const response = await fetch(url, {
        method: "POST",
        headers,
        body: JSON.stringify({ collectionID, encryptedKey }),
    });

    if (!response.ok) {
        log.error("Album join API failed", {
            collectionID,
            status: response.status,
        });
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

    try {
        // If collectionID is 0 (placeholder), we need to fetch the actual collection first
        let collectionID = context.collectionID;
        let collection: Collection | undefined;
        if (collectionID === 0) {
            // Import the pullCollection function dynamically from the correct module
            const { pullCollection } = await import("./public-collection");
            const result = await pullCollection(
                context.accessToken,
                context.collectionKey,
            );
            collection = result.collection;
            collectionID = collection.id;

            // Update the context with the actual collection ID
            const updatedContext = { ...context, collectionID };
            sessionStorage.setItem(
                JOIN_ALBUM_CONTEXT_KEY,
                JSON.stringify(updatedContext),
            );
        } else {
            // Fetch the collection to check ownership
            const { pullCollection } = await import("./public-collection");
            const result = await pullCollection(
                context.accessToken,
                context.collectionKey,
            );
            collection = result.collection;
        }

        // Check if the user is the owner of the album
        const currentUser = ensureLocalUser();
        if (collection.owner.id === currentUser.id) {
            clearJoinAlbumContext();
            return null;
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
    } catch (error) {
        log.error("Failed to process pending album join", {
            collectionID: context.collectionID,
            error,
        });
        throw error;
    }
};
