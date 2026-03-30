import { savedKeyAttributes } from "ente-accounts/services/accounts-db";
import { boxSeal, fromB64 } from "ente-base/crypto";
import { authenticatedRequestHeaders } from "ente-base/http";
import {
    clearJoinAlbumContext,
    getJoinAlbumContext,
} from "ente-base/join-album";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";

/**
 * The expected length in bytes for a collection key.
 *
 * This matches SecretBoxKeyBytes (crypto_secretbox_KEYBYTES) in libsodium,
 * which is 32 bytes (256 bits).
 */
const collectionKeyBytes = 32;

const joinPublicAlbum = async (
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
        ...(accessTokenJWT && { "X-Auth-Access-Token-JWT": accessTokenJWT }),
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
        const collectionID = context.collectionID;

        // Get user's key attributes from local storage
        const keyAttributes = savedKeyAttributes();
        if (!keyAttributes) {
            throw new Error(
                "Key attributes not found. Please try logging in again.",
            );
        }

        const publicKey = keyAttributes.publicKey;

        // Validate the collection key is exactly 32 bytes (256 bits)
        // This matches SecretBoxKeyBytes on the server and prevents processing
        // malformed join album URLs
        const collectionKeyBytes_ = await fromB64(context.collectionKey);
        if (collectionKeyBytes_.length !== collectionKeyBytes) {
            log.warn("Invalid collection key length in join album context");
            clearJoinAlbumContext();
            return null;
        }

        // Encrypt the collection key with user's public key
        // The collection key is already base64 encoded, and boxSeal expects base64
        const encryptedKey = await boxSeal(context.collectionKey, publicKey);

        // Join the album (include JWT token if present for password-protected albums)
        // Server validates ownership and returns error if user is the album owner
        await joinPublicAlbum(
            context.accessToken,
            collectionID,
            encryptedKey,
            context.accessTokenJWT,
        );

        // Clear the context after successful join
        clearJoinAlbumContext();

        return collectionID;
    } catch (error) {
        // Clear the context on failure to avoid repeated attempts
        clearJoinAlbumContext();
        log.error("Failed to process pending album join", {
            collectionID: context.collectionID,
            error,
        });
        throw error;
    }
};
