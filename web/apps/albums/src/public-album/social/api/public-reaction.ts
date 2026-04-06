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
 * Storage key prefix for anonymous identity in local storage.
 * The full key is `${prefix}_${collectionID}`.
 */
const ANON_IDENTITY_STORAGE_KEY_PREFIX = "ente_anon_identity";

/**
 * Get the storage key for a specific collection's anonymous identity.
 */
const getStorageKey = (collectionID: number): string =>
    `${ANON_IDENTITY_STORAGE_KEY_PREFIX}_${collectionID}`;

/**
 * Get the stored anonymous identity for a specific collection from local storage.
 *
 * Returns undefined if no identity is stored or if the stored identity has expired.
 * Expired identities are automatically cleared from storage.
 *
 * @param collectionID The collection ID to get the identity for.
 */
export const getStoredAnonIdentity = (
    collectionID: number,
): AnonIdentity | undefined => {
    if (typeof window === "undefined") return undefined;
    const stored = localStorage.getItem(getStorageKey(collectionID));
    if (!stored) return undefined;
    try {
        const identity = JSON.parse(stored) as AnonIdentity;
        // Check if the identity has expired.
        // Server returns expiresAt in microseconds, Date.now() returns milliseconds.
        const nowMicroseconds = Date.now() * 1000;
        if (identity.expiresAt && nowMicroseconds > identity.expiresAt) {
            // Clear expired identity so user can create a fresh one
            clearAnonIdentity(collectionID);
            return undefined;
        }
        return identity;
    } catch {
        return undefined;
    }
};

/**
 * Store the anonymous identity for a specific collection in local storage.
 *
 * @param collectionID The collection ID to store the identity for.
 * @param identity The anonymous identity to store.
 */
export const storeAnonIdentity = (
    collectionID: number,
    identity: AnonIdentity,
): void => {
    if (typeof window === "undefined") return;
    localStorage.setItem(getStorageKey(collectionID), JSON.stringify(identity));
};

/**
 * Clear the stored anonymous identity for a specific collection from local storage.
 *
 * @param collectionID The collection ID to clear the identity for.
 */
export const clearAnonIdentity = (collectionID: number): void => {
    if (typeof window === "undefined") return;
    localStorage.removeItem(getStorageKey(collectionID));
};

/**
 * Create an anonymous identity for a public album.
 *
 * The server will return a unique anonymous user ID and a token that can be
 * used to authenticate future requests (reactions, comments) from this
 * anonymous user.
 *
 * @param credentials Public album credentials (access token).
 * @param collectionID The collection ID this identity is for.
 * @param userName The name entered by the user.
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns The anonymous identity containing anonUserID and token.
 */
export const createAnonIdentity = async (
    credentials: PublicAlbumsCredentials,
    collectionID: number,
    userName: string,
    collectionKey: string,
): Promise<AnonIdentity> => {
    // Encrypt the user name using the collection key
    const { encryptedData: cipher, nonce } = await encryptBox(
        new TextEncoder().encode(userName),
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

    // Store the identity for this collection
    storeAnonIdentity(collectionID, identity);

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
 * @param collectionID The collection ID for looking up stored identity.
 * @param fileID The ID of the file to react to.
 * @param reactionType The type of reaction (e.g., "green_heart").
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @param anonIdentity Optional anonymous identity. If not provided, will use stored identity.
 * @returns The ID of the created reaction.
 */
export const addPublicReaction = async (
    credentials: PublicAlbumsCredentials,
    collectionID: number,
    fileID: number,
    reactionType: string,
    collectionKey: string,
    anonIdentity?: AnonIdentity,
): Promise<string> => {
    const identity = anonIdentity ?? getStoredAnonIdentity(collectionID);
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
 * Add a reaction to a comment in a public album (as an anonymous user).
 *
 * @param credentials Public album credentials (access token).
 * @param collectionID The collection ID for looking up stored identity.
 * @param commentID The ID of the comment to react to.
 * @param reactionType The type of reaction (e.g., "green_heart").
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @param anonIdentity Optional anonymous identity. If not provided, will use stored identity.
 * @param fileID Optional file ID, required for file-scoped comments.
 * @returns The ID of the created reaction.
 */
export const addPublicCommentReaction = async (
    credentials: PublicAlbumsCredentials,
    collectionID: number,
    commentID: string,
    reactionType: string,
    collectionKey: string,
    anonIdentity?: AnonIdentity,
    fileID?: number,
): Promise<string> => {
    const identity = anonIdentity ?? getStoredAnonIdentity(collectionID);
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
            commentID,
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
 * @param collectionID The collection ID for looking up stored identity.
 * @param reactionID The ID of the reaction to delete.
 * @param anonIdentity Optional anonymous identity. If not provided, will use stored identity.
 */
export const deletePublicReaction = async (
    credentials: PublicAlbumsCredentials,
    collectionID: number,
    reactionID: string,
    anonIdentity?: AnonIdentity,
): Promise<void> => {
    const identity = anonIdentity ?? getStoredAnonIdentity(collectionID);
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
        { headers: authenticatedPublicAlbumsRequestHeaders(credentials) },
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
                fileID: reaction.fileID ?? fileID,
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
    fileID: z.number().nullish(),
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

/**
 * An anonymous user profile (encrypted).
 */
export interface AnonProfile {
    anonUserID: string;
    userName: string;
}

/**
 * Get anonymous user profiles for a public album.
 *
 * @param credentials Public album credentials (access token).
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns Map of anonUserID to decrypted userName.
 */
export const getPublicAnonProfiles = async (
    credentials: PublicAlbumsCredentials,
    collectionKey: string,
): Promise<Map<string, string>> => {
    const res = await fetch(await apiURL("/public-collection/anon-profiles"), {
        headers: authenticatedPublicAlbumsRequestHeaders(credentials),
    });
    ensureOk(res);
    const { profiles } = GetAnonProfilesResponse.parse(await res.json());

    const anonUserNames = new Map<string, string>();
    for (const profile of profiles) {
        if (!profile.cipher || !profile.nonce) continue;
        try {
            const decryptedB64 = await decryptBox(
                { encryptedData: profile.cipher, nonce: profile.nonce },
                collectionKey,
            );
            const userName = new TextDecoder().decode(
                Uint8Array.from(atob(decryptedB64), (c) => c.charCodeAt(0)),
            );
            if (userName) {
                anonUserNames.set(profile.anonUserID, userName);
            }
        } catch {
            // Skip profiles that fail to decrypt
        }
    }
    return anonUserNames;
};

const RemoteAnonProfile = z.object({
    anonUserID: z.string(),
    collectionID: z.number(),
    cipher: z.string().nullish(),
    nonce: z.string().nullish(),
    createdAt: z.number(),
    updatedAt: z.number(),
});

const GetAnonProfilesResponse = z.object({
    profiles: z
        .array(RemoteAnonProfile)
        .nullish()
        .transform((v) => v ?? []),
});

/**
 * A participant with masked email.
 */
export interface Participant {
    userID: number;
    emailMasked: string;
}

/**
 * Get registered participants' masked emails for a public album.
 *
 * This returns masked emails for registered users (album owner/collaborators)
 * who have interacted with the album (comments/reactions).
 *
 * @param credentials Public album credentials (access token).
 * @returns Map of userID to masked email.
 */
export const getPublicParticipantsMaskedEmails = async (
    credentials: PublicAlbumsCredentials,
): Promise<Map<number, string>> => {
    const res = await fetch(
        await apiURL("/public-collection/participants/masked-emails"),
        { headers: authenticatedPublicAlbumsRequestHeaders(credentials) },
    );
    ensureOk(res);
    const { participants } = GetParticipantsResponse.parse(await res.json());

    const userIDToEmail = new Map<number, string>();
    for (const participant of participants) {
        userIDToEmail.set(participant.userID, participant.emailMasked);
    }
    return userIDToEmail;
};

const RemoteParticipant = z.object({
    userID: z.number(),
    emailMasked: z.string(),
});

const GetParticipantsResponse = z.object({
    participants: z.array(RemoteParticipant),
});

// =============================================================================
// Unified Social Diff
// =============================================================================

/**
 * A decrypted public comment.
 */
export interface PublicComment {
    id: string;
    collectionID: number;
    fileID?: number;
    parentCommentID?: string;
    userID: number;
    anonUserID?: string;
    text: string;
    isDeleted: boolean;
    createdAt: number;
    updatedAt: number;
}

/**
 * Result of fetching unified social diff.
 */
export interface PublicSocialDiff {
    comments: PublicComment[];
    reactions: PublicReaction[];
}

/**
 * Get both comments and reactions for a file in a public album in a single API call.
 *
 * @param credentials Public album credentials (access token).
 * @param fileID The ID of the file to get social data for.
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns Object containing both decrypted comments and reactions.
 */
export const getPublicSocialDiff = async (
    credentials: PublicAlbumsCredentials,
    fileID: number,
    collectionKey: string,
): Promise<PublicSocialDiff> => {
    const res = await fetch(
        await apiURL("/public-collection/social/diff", {
            fileID,
            sinceTime: 0,
            limit: 1000,
        }),
        { headers: authenticatedPublicAlbumsRequestHeaders(credentials) },
    );
    ensureOk(res);
    const data = GetPublicSocialDiffResponse.parse(await res.json());

    // Decrypt comments
    const comments: PublicComment[] = [];
    for (const comment of data.comments) {
        // Include deleted comments with empty text
        if (comment.isDeleted || !comment.cipher || !comment.nonce) {
            comments.push({
                id: comment.id,
                collectionID: comment.collectionID,
                fileID: comment.fileID ?? undefined,
                parentCommentID: comment.parentCommentID ?? undefined,
                userID: comment.userID,
                anonUserID: comment.anonUserID ?? undefined,
                text: "",
                isDeleted: comment.isDeleted,
                createdAt: comment.createdAt,
                updatedAt: comment.updatedAt,
            });
            continue;
        }
        try {
            const decryptedB64 = await decryptBox(
                { encryptedData: comment.cipher, nonce: comment.nonce },
                collectionKey,
            );
            const text = new TextDecoder().decode(
                Uint8Array.from(atob(decryptedB64), (c) => c.charCodeAt(0)),
            );
            comments.push({
                id: comment.id,
                collectionID: comment.collectionID,
                fileID: comment.fileID ?? undefined,
                parentCommentID: comment.parentCommentID ?? undefined,
                userID: comment.userID,
                anonUserID: comment.anonUserID ?? undefined,
                text,
                isDeleted: comment.isDeleted,
                createdAt: comment.createdAt,
                updatedAt: comment.updatedAt,
            });
        } catch {
            // Skip comments that fail to decrypt
        }
    }

    // Decrypt reactions
    const reactions: PublicReaction[] = [];
    for (const reaction of data.reactions) {
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
            reactions.push({
                id: reaction.id,
                fileID: reaction.fileID ?? fileID,
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

    return { comments, reactions };
};

const RemotePublicComment = z.object({
    id: z.string(),
    collectionID: z.number(),
    fileID: z.number().nullish(),
    parentCommentID: z.string().nullish(),
    userID: z.number(),
    anonUserID: z.string().nullish(),
    cipher: z.string().nullish(),
    nonce: z.string().nullish(),
    isDeleted: z.boolean(),
    createdAt: z.number(),
    updatedAt: z.number(),
});

const GetPublicSocialDiffResponse = z.object({
    comments: z.array(RemotePublicComment),
    reactions: z.array(RemotePublicReaction),
    hasMoreComments: z.boolean(),
    hasMoreReactions: z.boolean(),
});

// =============================================================================
// Public Album Feed
// =============================================================================

/**
 * A public comment extended with isReply flag for feed processing.
 */
export interface PublicFeedComment extends PublicComment {
    /** True if this comment is a reply to another comment. */
    isReply: boolean;
}

/**
 * A public reaction extended with isCommentReply flag for feed processing.
 */
export interface PublicFeedReaction extends PublicReaction {
    /** True if this reaction is on a reply (comment with parent). */
    isCommentReply?: boolean;
}

/**
 * Result of fetching all social data for a public album feed.
 */
export interface PublicAlbumFeed {
    comments: PublicFeedComment[];
    reactions: PublicFeedReaction[];
}

/**
 * Get all comments and reactions for a public album (for the feed).
 *
 * Unlike getPublicSocialDiff which is per-file, this fetches ALL social data
 * for the entire album without filtering by file.
 *
 * @param credentials Public album credentials (access token).
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns Object containing all decrypted comments and reactions for the album.
 */
export const getPublicAlbumFeed = async (
    credentials: PublicAlbumsCredentials,
    collectionKey: string,
): Promise<PublicAlbumFeed> => {
    // Fetch all social data without fileID filter
    const res = await fetch(
        await apiURL("/public-collection/social/diff", {
            sinceTime: 0,
            limit: 1000,
        }),
        { headers: authenticatedPublicAlbumsRequestHeaders(credentials) },
    );
    ensureOk(res);
    const data = GetPublicSocialDiffResponse.parse(await res.json());

    // Build a map of comment IDs to their parent status for determining isCommentReply
    const commentParentMap = new Map<string, boolean>();

    // Decrypt comments
    const comments: PublicFeedComment[] = [];
    for (const comment of data.comments) {
        const isReply = !!comment.parentCommentID;
        commentParentMap.set(comment.id, isReply);

        // Include deleted comments with empty text
        if (comment.isDeleted || !comment.cipher || !comment.nonce) {
            comments.push({
                id: comment.id,
                collectionID: comment.collectionID,
                fileID: comment.fileID ?? undefined,
                parentCommentID: comment.parentCommentID ?? undefined,
                userID: comment.userID,
                anonUserID: comment.anonUserID ?? undefined,
                text: "",
                isDeleted: comment.isDeleted,
                createdAt: comment.createdAt,
                updatedAt: comment.updatedAt,
                isReply,
            });
            continue;
        }
        try {
            const decryptedB64 = await decryptBox(
                { encryptedData: comment.cipher, nonce: comment.nonce },
                collectionKey,
            );
            const text = new TextDecoder().decode(
                Uint8Array.from(atob(decryptedB64), (c) => c.charCodeAt(0)),
            );
            comments.push({
                id: comment.id,
                collectionID: comment.collectionID,
                fileID: comment.fileID ?? undefined,
                parentCommentID: comment.parentCommentID ?? undefined,
                userID: comment.userID,
                anonUserID: comment.anonUserID ?? undefined,
                text,
                isDeleted: comment.isDeleted,
                createdAt: comment.createdAt,
                updatedAt: comment.updatedAt,
                isReply,
            });
        } catch {
            // Skip comments that fail to decrypt
        }
    }

    // Decrypt reactions
    const reactions: PublicFeedReaction[] = [];
    for (const reaction of data.reactions) {
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

            // Determine if this reaction is on a reply by checking the comment's parent status
            let isCommentReply: boolean | undefined;
            if (reaction.commentID) {
                isCommentReply = commentParentMap.get(reaction.commentID);
            }

            reactions.push({
                id: reaction.id,
                fileID: reaction.fileID ?? 0,
                commentID: reaction.commentID ?? undefined,
                isCommentReply,
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

    return { comments, reactions };
};
