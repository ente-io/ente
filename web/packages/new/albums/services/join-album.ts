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
    collectionKey: string;  // Base64 encoded collection key for API calls
    collectionKeyHash: string;  // Original hash value from URL (base58 or hex)
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

    console.log("[Join Album] Storing context:", {
        collectionID: context.collectionID,
        hasAccessToken: !!context.accessToken,
        hasCollectionKey: !!context.collectionKey,
    });

    localStorage.setItem(JOIN_ALBUM_CONTEXT_KEY, JSON.stringify(context));
};

/**
 * Retrieve stored album context after authentication.
 * Checks localStorage for the stored context.
 */
export const getJoinAlbumContext = (): JoinAlbumContext | null => {
    // Check localStorage for stored context
    const stored = localStorage.getItem(JOIN_ALBUM_CONTEXT_KEY);
    console.log("[Join Album] Checking localStorage for context, found:", !!stored);

    if (!stored) return null;

    try {
        const context = JSON.parse(stored) as JoinAlbumContext;

        console.log("[Join Album] LocalStorage context retrieved:", {
            collectionID: context.collectionID,
        });

        return context;
    } catch (error) {
        console.error("[Join Album] Failed to parse localStorage context:", error);
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

    console.log("[Join Album] Making API request:", {
        url,
        collectionID,
        hasAccessToken: !!accessToken,
        hasEncryptedKey: !!encryptedKey,
    });

    const requestBody = { collectionID, encryptedKey };
    console.log("[Join Album] Request body:", {
        collectionID,
        encryptedKeyLength: encryptedKey.length,
        encryptedKeyPrefix: encryptedKey.substring(0, 20) + "...",
    });

    const response = await fetch(url, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            ...authHeaders,
            "X-Auth-Access-Token": accessToken,
        },
        body: JSON.stringify(requestBody),
    });

    console.log("[Join Album] API response status:", response.status);
    console.log("[Join Album] Response headers:", Object.fromEntries(response.headers.entries()));

    if (!response.ok) {
        let errorMessage = `Failed to join album (status: ${response.status})`;
        try {
            const errorData = (await response.json()) as { message?: string; code?: string };
            console.error("[Join Album] API error response:", errorData);
            errorMessage = errorData.message ?? errorMessage;
        } catch (e) {
            console.error("[Join Album] Failed to parse error response:", e);
        }
        throw new Error(errorMessage);
    }

    // Log successful response
    try {
        const responseData = await response.json();
        console.log("[Join Album] API success response:", responseData);
    } catch {
        console.log("[Join Album] API returned success with no JSON body");
    }
};

/**
 * Process the pending album join after authentication.
 * This should be called after successful sign-in/sign-up.
 *
 * @returns The collection ID if an album was successfully joined, null otherwise
 */
export const processPendingAlbumJoin = async (): Promise<number | null> => {
    console.log("[Join Album] Processing pending album join");
    const context = getJoinAlbumContext();

    if (!context) {
        console.log("[Join Album] No pending context found");
        return null;
    }

    console.log("[Join Album] Found pending join for collection:", context.collectionID);

    try {
        // Get user's key attributes from local storage
        console.log("[Join Album] Getting user key attributes from local storage");
        const keyAttributes = savedKeyAttributes();
        if (!keyAttributes) {
            console.error("[Join Album] Key attributes not found in local storage");
            throw new Error("Key attributes not found. Please try logging in again.");
        }

        const publicKey = keyAttributes.publicKey;
        console.log("[Join Album] Got public key, encrypting collection key");

        // Encrypt the collection key with user's public key
        // The collection key is already base64 encoded, and boxSeal expects base64
        const encryptedKey = await boxSeal(context.collectionKey, publicKey);
        console.log("[Join Album] Collection key encrypted");

        // Join the album
        console.log("[Join Album] Calling join API for collection:", context.collectionID);
        await joinPublicAlbum(
            context.accessToken,
            context.collectionID,
            encryptedKey,
        );

        console.log("[Join Album] Successfully joined album!");

        const collectionID = context.collectionID;

        // Clear the context after successful join
        clearJoinAlbumContext();

        return collectionID;
    } catch (error) {
        console.error("[Join Album] Failed to join album:", error);
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
        console.error("[Join Album] No context found when generating redirect URL");
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
    return `${photosAppURL}/?joinAlbum=${context.accessToken}#${context.collectionKeyHash}`;
};
