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
    collectionKey: string;
    collectionID: number;
    collectionName?: string;
    timestamp: number;
}

/**
 * Store the album context before redirecting to auth.
 * This preserves the album information across the authentication flow.
 */
export const storeJoinAlbumContext = (
    accessToken: string,
    collectionKey: string,
    collection: Collection,
) => {
    const context: JoinAlbumContext = {
        accessToken,
        collectionKey,
        collectionID: collection.id,
        collectionName: collection.name || undefined,
        timestamp: Date.now(),
    };

    localStorage.setItem(JOIN_ALBUM_CONTEXT_KEY, JSON.stringify(context));
};

/**
 * Retrieve stored album context after authentication.
 */
export const getJoinAlbumContext = (): JoinAlbumContext | null => {
    const stored = localStorage.getItem(JOIN_ALBUM_CONTEXT_KEY);
    if (!stored) return null;

    try {
        const context = JSON.parse(stored) as JoinAlbumContext;
        // Check if context is still valid (24 hours)
        const isValid = Date.now() - context.timestamp < 24 * 60 * 60 * 1000;
        return isValid ? context : null;
    } catch {
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

    const response = await fetch(await apiURL("/collections/join-link"), {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            ...authHeaders,
            "X-Auth-Access-Token": accessToken,
        },
        body: JSON.stringify({ collectionID, encryptedKey }),
    });

    if (!response.ok) {
        const errorData = (await response.json()) as { message?: string };
        throw new Error(errorData.message ?? "Failed to join album");
    }
};

/**
 * Process the pending album join after authentication.
 * This should be called after successful sign-in/sign-up.
 *
 * @returns true if an album was successfully joined, false otherwise
 */
export const processPendingAlbumJoin = async (): Promise<boolean> => {
    const context = getJoinAlbumContext();
    if (!context) return false;

    try {
        // Fetch user's key attributes to get public key
        const authHeaders = await authenticatedRequestHeaders();
        const response = await fetch(await apiURL("/users/key-attributes"), {
            headers: authHeaders,
        });

        if (!response.ok) {
            throw new Error("Failed to fetch user key attributes");
        }

        const keyAttributes = (await response.json()) as { publicKey: string };
        const publicKey = keyAttributes.publicKey;

        // Encrypt the collection key with user's public key
        // The collection key is already base64 encoded, and boxSeal expects base64
        const encryptedKey = await boxSeal(context.collectionKey, publicKey);

        // Join the album
        await joinPublicAlbum(
            context.accessToken,
            context.collectionID,
            encryptedKey,
        );

        // Clear the context after successful join
        clearJoinAlbumContext();

        return true;
    } catch (error) {
        console.error("Failed to join album:", error);
        // Don't clear context on error - let user retry
        throw error;
    }
};

/**
 * Get the redirect URL for authentication with join album context.
 * This preserves the intent to join an album across the auth flow.
 */
export const getAuthRedirectURL = (): string => {
    // In development, redirect to the photos app on port 3000
    // In production, this would be https://web.ente.io or the custom endpoint
    const isDevelopment = window.location.hostname === "localhost";
    const photosAppURL = isDevelopment
        ? "http://localhost:3000"
        : window.location.origin.replace("albums.", "web.");

    return `${photosAppURL}/?joinAlbum=true`;
};
