import { savedKeyAttributes } from "ente-accounts/services/accounts-db";
import { boxSeal } from "ente-base/crypto";
import { authenticatedRequestHeaders } from "ente-base/http";
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
}

/**
 * Store the album context before redirecting to auth.
 * This preserves the album information across the authentication flow.
 */
export const storeJoinAlbumContext = (
    accessToken: string,
    collectionKey: string,
    collectionKeyHash: string,
    collection: Collection,
) => {
    const context: JoinAlbumContext = {
        accessToken,
        collectionKey,
        collectionKeyHash,
        collectionID: collection.id,
    };

    localStorage.setItem(JOIN_ALBUM_CONTEXT_KEY, JSON.stringify(context));
};

/**
 * Retrieve stored album context after authentication.
 * Checks localStorage for the stored context.
 */
export const getJoinAlbumContext = (): JoinAlbumContext | null => {
    const stored = localStorage.getItem(JOIN_ALBUM_CONTEXT_KEY);
    if (!stored) return null;

    try {
        const context = JSON.parse(stored) as JoinAlbumContext;
        return context;
    } catch (error) {
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
): Promise<void> => {
    const authHeaders = await authenticatedRequestHeaders();
    const url = await apiURL("/collections/join-link");

    const response = await fetch(url, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            ...authHeaders,
            "X-Auth-Access-Token": accessToken,
        },
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

    try {
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

        // Join the album
        await joinPublicAlbum(context.accessToken, collectionID, encryptedKey);

        // Clear the context after successful join
        clearJoinAlbumContext();

        return collectionID;
    } catch (error) {
        // Don't clear context on error - let user retry
        throw error;
    }
};

/**
 * Get the redirect URL for authentication with join album context.
 * This preserves the intent to join an album across the auth flow.
 */
export const getAuthRedirectURL = (): string => {
    const context = getJoinAlbumContext();
    if (!context) {
        return "/";
    }

    // In development, redirect to the photos app on port 3000
    // In production, this would be https://web.ente.io or the custom endpoint
    const isDevelopment = window.location.hostname === "localhost";
    const photosAppURL = isDevelopment
        ? "http://localhost:3000"
        : window.location.origin.replace("albums.", "web.");

    // Use the simplified URL format: joinAlbum?=accessToken#collectionKeyHash
    // The collectionKeyHash is the original hash value from the URL (base58 or hex)
    const redirectURL = `${photosAppURL}/?joinAlbum=${context.accessToken}#${context.collectionKeyHash}`;

    return redirectURL;
};
