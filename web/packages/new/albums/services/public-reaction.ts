import { decryptBox, encryptBox } from "ente-base/crypto";
import {
    authenticatedPublicAlbumsRequestHeaders,
    ensureOk,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { z } from "zod";

/**
 * Fixed length for padded reaction types.
 * All reactions are padded to this length before encryption to prevent
 * length-based analysis of the ciphertext.
 * Max emoji name is ~70 chars, so 100 provides a safe buffer.
 */
const paddedReactionLength = 100;

/**
 * Pad a reaction type to a fixed length using null bytes.
 */
const padReaction = (reactionType: string): string =>
    reactionType.padEnd(paddedReactionLength, "\0");

/**
 * Remove null byte padding from a decrypted reaction type.
 */
const unpadReaction = (paddedReaction: string): string =>
    paddedReaction.replace(/\0+$/, "");

/**
 * Anonymous user identity returned when creating an anon identity.
 */
export interface AnonIdentity {
    anonUserID: string;
    token: string;
    expiresAt: number;
}

/**
 * Storage key for anonymous identity in local storage.
 */
const ANON_IDENTITY_STORAGE_KEY = "ente_anon_identity";

/**
 * Get the stored anonymous identity from local storage, if any.
 */
export const getStoredAnonIdentity = (): AnonIdentity | undefined => {
    if (typeof window === "undefined") return undefined;
    const stored = localStorage.getItem(ANON_IDENTITY_STORAGE_KEY);
    if (!stored) return undefined;
    try {
        return JSON.parse(stored) as AnonIdentity;
    } catch {
        return undefined;
    }
};

/**
 * Store the anonymous identity in local storage.
 */
export const storeAnonIdentity = (identity: AnonIdentity): void => {
    if (typeof window === "undefined") return;
    localStorage.setItem(ANON_IDENTITY_STORAGE_KEY, JSON.stringify(identity));
};

/**
 * Clear the stored anonymous identity from local storage.
 */
export const clearAnonIdentity = (): void => {
    if (typeof window === "undefined") return;
    localStorage.removeItem(ANON_IDENTITY_STORAGE_KEY);
};

/**
 * Create an anonymous identity for a public album.
 *
 * The server will return a unique anonymous user ID and a token that can be
 * used to authenticate future requests (reactions, comments) from this
 * anonymous user.
 *
 * @param credentials Public album credentials (access token).
 * @param userName The name entered by the user.
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns The anonymous identity containing anonUserID and token.
 */
export const createAnonIdentity = async (
    credentials: PublicAlbumsCredentials,
    userName: string,
    collectionKey: string,
): Promise<AnonIdentity> => {
    // Encrypt the user name using the collection key
    const { encryptedData: cipher, nonce } = await encryptBox(
        new TextEncoder().encode(JSON.stringify({ userName })),
        collectionKey,
    );

    const res = await fetch(await apiURL("/public-collection/anon-identity"), {
        method: "POST",
        headers: {
            ...authenticatedPublicAlbumsRequestHeaders(credentials),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ cipher, nonce }),
    });
    ensureOk(res);
    const identity = AnonIdentityResponse.parse(await res.json());

    // Store the identity for future use
    storeAnonIdentity(identity);

    return identity;
};

const AnonIdentityResponse = z.object({
    anonUserID: z.string(),
    token: z.string(),
    expiresAt: z.number(),
});

/**
 * Add a reaction to a file in a public album (as an anonymous user).
 *
 * @param credentials Public album credentials (access token).
 * @param fileID The ID of the file to react to.
 * @param reactionType The type of reaction (e.g., "green_heart").
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @param anonIdentity Optional anonymous identity. If not provided, will use stored identity.
 * @returns The ID of the created reaction.
 */
export const addPublicReaction = async (
    credentials: PublicAlbumsCredentials,
    fileID: number,
    reactionType: string,
    collectionKey: string,
    anonIdentity?: AnonIdentity,
): Promise<string> => {
    const identity = anonIdentity ?? getStoredAnonIdentity();
    if (!identity) {
        throw new Error("No anonymous identity available");
    }

    const { encryptedData: cipher, nonce } = await encryptBox(
        new TextEncoder().encode(padReaction(reactionType)),
        collectionKey,
    );

    const res = await fetch(await apiURL("/public-collection/reactions"), {
        method: "POST",
        headers: {
            ...authenticatedPublicAlbumsRequestHeaders(credentials),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            fileID,
            cipher,
            nonce,
            anonUserID: identity.anonUserID,
            anonToken: identity.token,
        }),
    });
    ensureOk(res);
    const { id } = UpsertReactionResponse.parse(await res.json());
    return id;
};

/**
 * Delete a reaction from a public album (as an anonymous user).
 *
 * @param credentials Public album credentials (access token).
 * @param reactionID The ID of the reaction to delete.
 * @param anonIdentity Optional anonymous identity. If not provided, will use stored identity.
 */
export const deletePublicReaction = async (
    credentials: PublicAlbumsCredentials,
    reactionID: string,
    anonIdentity?: AnonIdentity,
): Promise<void> => {
    const identity = anonIdentity ?? getStoredAnonIdentity();
    if (!identity) {
        throw new Error("No anonymous identity available");
    }

    const res = await fetch(
        await apiURL(`/public-collection/reactions/${reactionID}`),
        {
            method: "DELETE",
            headers: {
                ...authenticatedPublicAlbumsRequestHeaders(credentials),
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                anonUserID: identity.anonUserID,
                anonToken: identity.token,
            }),
        },
    );
    ensureOk(res);
};

const UpsertReactionResponse = z.object({ id: z.string() });

/**
 * A decrypted public reaction.
 */
export interface PublicReaction {
    id: string;
    fileID: number;
    commentID?: string;
    reactionType: string;
    userID: number;
    anonUserID?: string;
    isDeleted: boolean;
    createdAt: number;
    updatedAt: number;
}

/**
 * Get reactions for a file in a public album.
 *
 * @param credentials Public album credentials (access token).
 * @param fileID The ID of the file to get reactions for.
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns Array of decrypted reactions for the file.
 */
export const getPublicFileReactions = async (
    credentials: PublicAlbumsCredentials,
    fileID: number,
    collectionKey: string,
): Promise<PublicReaction[]> => {
    const res = await fetch(
        await apiURL("/public-collection/reactions/diff", {
            fileID,
            sinceTime: 0,
            limit: 100,
        }),
        {
            headers: authenticatedPublicAlbumsRequestHeaders(credentials),
        },
    );
    ensureOk(res);
    const { reactions } = GetPublicReactionsResponse.parse(await res.json());

    const decryptedReactions: PublicReaction[] = [];
    for (const reaction of reactions) {
        // Skip deleted reactions (they have null cipher/nonce)
        if (reaction.isDeleted || !reaction.cipher || !reaction.nonce) continue;
        try {
            const decryptedB64 = await decryptBox(
                { encryptedData: reaction.cipher, nonce: reaction.nonce },
                collectionKey,
            );
            const reactionType = unpadReaction(
                new TextDecoder().decode(
                    Uint8Array.from(atob(decryptedB64), (c) => c.charCodeAt(0)),
                ),
            );
            decryptedReactions.push({
                id: reaction.id,
                fileID: reaction.fileID,
                commentID: reaction.commentID ?? undefined,
                reactionType,
                userID: reaction.userID,
                anonUserID: reaction.anonUserID ?? undefined,
                isDeleted: reaction.isDeleted,
                createdAt: reaction.createdAt,
                updatedAt: reaction.updatedAt,
            });
        } catch {
            // Skip reactions that fail to decrypt
        }
    }
    return decryptedReactions;
};

const RemotePublicReaction = z.object({
    id: z.string(),
    collectionID: z.number(),
    fileID: z.number(),
    commentID: z.string().nullish(),
    userID: z.number(),
    anonUserID: z.string().nullish(),
    cipher: z.string().nullish(),
    nonce: z.string().nullish(),
    isDeleted: z.boolean(),
    createdAt: z.number(),
    updatedAt: z.number(),
});

const GetPublicReactionsResponse = z.object({
    reactions: z.array(RemotePublicReaction),
    hasMore: z.boolean(),
});
