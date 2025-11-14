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
    collectionKeyHash: string;  // Original hash value from URL (base58 or hex) - MUST preserve original
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
    console.log("[Join Album] storeJoinAlbumContext called with:", {
        accessToken: accessToken.substring(0, 10) + "...",
        collectionKey: collectionKey.substring(0, 10) + "...",
        collectionKeyHash: collectionKeyHash.substring(0, 10) + "...",
        collectionKeyEndsWithEquals: collectionKey.endsWith("="),
        collectionKeyHashEndsWithEquals: collectionKeyHash.endsWith("="),
        collectionKeyLength: collectionKey.length,
        collectionKeyHashLength: collectionKeyHash.length,
        fullCollectionKey: collectionKey,
        fullCollectionKeyHash: collectionKeyHash,
    });

    // Validate that we're not accidentally using the base64 key as the hash
    if (collectionKey === collectionKeyHash) {
        console.error("[Join Album] ERROR: collectionKey and collectionKeyHash are the same! This is likely a bug.");
        console.error("collectionKey (should be base64):", collectionKey);
        console.error("collectionKeyHash (should be original hash):", collectionKeyHash);
    }

    // Validation: Check if parameters are in correct order
    // Base64 contains +, /, = characters. Base58 doesn't contain these.
    // Hex only contains 0-9, a-f characters
    const isBase64 = (str: string): boolean => {
        return /[+/=]/.test(str) || (str.length === 44 && /^[A-Za-z0-9+/]+=*$/.test(str));
    };

    const isBase58 = (str: string): boolean => {
        // Base58 doesn't contain 0, O, I, l, +, /, =
        return !/[0OIl+/=]/.test(str) && /^[1-9A-HJ-NP-Za-km-z]+$/.test(str);
    };

    const collectionKeyIsBase64 = isBase64(collectionKey);
    const collectionKeyHashIsBase64 = isBase64(collectionKeyHash);
    const collectionKeyIsBase58 = isBase58(collectionKey);
    const collectionKeyHashIsBase58 = isBase58(collectionKeyHash);

    console.log("[Join Album] Validation check:", {
        collectionKeyIsBase64,
        collectionKeyHashIsBase64,
        collectionKeyIsBase58,
        collectionKeyHashIsBase58,
    });

    // IMPORTANT: collectionKey should be base64 (for API), collectionKeyHash should be original (base58/hex)
    if (collectionKeyHashIsBase64 && collectionKeyIsBase58) {
        console.warn("[Join Album] WARNING: Parameters appear to be swapped!");
        console.warn("collectionKey should be base64, but appears to be base58:", collectionKey.substring(0, 20) + "...");
        console.warn("collectionKeyHash should be base58/hex, but appears to be base64:", collectionKeyHash.substring(0, 20) + "...");
        // Swap them to fix the issue
        const temp = collectionKey;
        collectionKey = collectionKeyHash;
        collectionKeyHash = temp;
        console.log("[Join Album] After swap - fixed:", {
            collectionKey: collectionKey.substring(0, 10) + "... (now base64)",
            collectionKeyHash: collectionKeyHash.substring(0, 10) + "... (now base58)",
        });
    } else if (!collectionKeyIsBase64 && !collectionKeyHashIsBase64) {
        // Neither appears to be base64 - might both be base58 or hex
        console.warn("[Join Album] WARNING: Neither value appears to be base64!");
        console.warn("This might indicate an issue with parameter passing.");
    } else if (collectionKeyIsBase64 && collectionKeyHashIsBase64) {
        // Both appear to be base64 - this is wrong
        console.error("[Join Album] ERROR: Both values appear to be base64!");
        console.error("The collectionKeyHash should be the original hash from the URL.");
    }

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
        collectionKeyPreview: context.collectionKey.substring(0, 10) + "...",
        collectionKeyHashPreview: context.collectionKeyHash.substring(0, 10) + "...",
        collectionKeyIsBase64: context.collectionKey.endsWith("="),
        collectionKeyHashIsBase58: !context.collectionKeyHash.endsWith("="),
        fullCollectionKeyHash: context.collectionKeyHash,
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

    console.log("[Join Album] Generating auth redirect URL with context:", {
        accessToken: context.accessToken,
        collectionKeyPreview: context.collectionKey.substring(0, 10) + "...",
        collectionKeyHashPreview: context.collectionKeyHash.substring(0, 10) + "...",
        collectionKeyIsBase64: context.collectionKey.endsWith("="),
        collectionKeyHashIsBase58: !context.collectionKeyHash.endsWith("="),
        collectionKeyLength: context.collectionKey.length,
        collectionKeyHashLength: context.collectionKeyHash.length,
        fullCollectionKey: context.collectionKey,
        fullCollectionKeyHash: context.collectionKeyHash,
    });

    // In development, redirect to the photos app on port 3000
    // In production, this would be https://web.ente.io or the custom endpoint
    const isDevelopment = window.location.hostname === "localhost";
    const photosAppURL = isDevelopment
        ? "http://localhost:3000"
        : window.location.origin.replace("albums.", "web.");

    // Use the simplified URL format: joinAlbum?=accessToken#collectionKeyHash
    // The collectionKeyHash is the original hash value from the URL (base58 or hex)
    const redirectURL = `${photosAppURL}/?joinAlbum=${context.accessToken}#${context.collectionKeyHash}`;

    console.log("[Join Album] Generated redirect URL:", redirectURL);

    return redirectURL;
};
