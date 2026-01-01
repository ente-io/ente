import { decryptBox } from "ente-base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { z } from "zod";
import type { Comment } from "./comment";

/**
 * Remove null byte padding from a decrypted reaction type.
 */
const unpadReaction = (paddedReaction: string): string =>
    paddedReaction.replace(/\0+$/, "");

/**
 * A decrypted reaction from the unified diff endpoint.
 */
export interface UnifiedReaction {
    id: string;
    collectionID: number;
    fileID?: number;
    commentID?: string;
    /** True if this reaction is on a reply (only in feed responses). */
    isCommentReply?: boolean;
    reactionType: string;
    userID: number;
    anonUserID?: string;
    isDeleted: boolean;
    createdAt: number;
    updatedAt: number;
}

/**
 * Result from the unified social diff endpoint.
 */
export interface UnifiedSocialDiff {
    comments: Comment[];
    reactions: UnifiedReaction[];
    hasMoreComments: boolean;
    hasMoreReactions: boolean;
}

/**
 * Get comments and reactions for a file in a single request.
 *
 * @param collectionID The ID of the collection containing the file.
 * @param fileID The ID of the file to get social data for.
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns Comments and reactions for the file.
 */
export const getUnifiedSocialDiff = async (
    collectionID: number,
    fileID: number,
    collectionKey: string,
): Promise<UnifiedSocialDiff> => {
    const res = await fetch(
        await apiURL("/social/diff", {
            collectionID,
            fileID,
            sinceTime: 0,
            limit: 1000,
        }),
        { headers: await authenticatedRequestHeaders() },
    );
    ensureOk(res);
    return decryptSocialDiff(collectionKey, await res.json());
};

/**
 * Get album feed - comments and reactions relevant to the current user.
 *
 * This uses a server-side filtered endpoint that only returns:
 * - Comments on files owned by the user (excluding user's own comments)
 * - Replies to user's comments
 * - Reactions on files owned by the user
 * - Reactions on user's comments
 *
 * @param collectionID The ID of the collection.
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns Filtered comments and reactions for the user's feed.
 */
export const getAlbumFeed = async (
    collectionID: number,
    collectionKey: string,
): Promise<UnifiedSocialDiff> => {
    const res = await fetch(
        await apiURL("/social/album-feed", {
            collectionID,
            sinceTime: 0,
            limit: 1000,
        }),
        { headers: await authenticatedRequestHeaders() },
    );
    ensureOk(res);
    return decryptSocialDiff(collectionKey, await res.json());
};

/**
 * Decrypt comments and reactions from the unified diff endpoint response.
 */
const decryptSocialDiff = async (
    collectionKey: string,
    responseJson: unknown,
): Promise<UnifiedSocialDiff> => {
    const data = UnifiedDiffResponse.parse(responseJson);

    // Decrypt comments
    const comments: Comment[] = [];
    for (const comment of data.comments) {
        if (comment.isDeleted || !comment.cipher || !comment.nonce) {
            comments.push({
                id: comment.id,
                collectionID: comment.collectionID,
                fileID: comment.fileID ?? undefined,
                parentCommentID: comment.parentCommentID ?? undefined,
                parentCommentUserID: comment.parentCommentUserID ?? undefined,
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
            const decryptedComment = {
                id: comment.id,
                collectionID: comment.collectionID,
                fileID: comment.fileID ?? undefined,
                parentCommentID: comment.parentCommentID ?? undefined,
                parentCommentUserID: comment.parentCommentUserID ?? undefined,
                userID: comment.userID,
                anonUserID: comment.anonUserID ?? undefined,
                text,
                isDeleted: comment.isDeleted,
                createdAt: comment.createdAt,
                updatedAt: comment.updatedAt,
            };
            comments.push(decryptedComment);
        } catch {
            // Skip comments that fail to decrypt
        }
    }

    // Decrypt reactions
    const reactions: UnifiedReaction[] = [];
    for (const reaction of data.reactions) {
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
                collectionID: reaction.collectionID,
                fileID: reaction.fileID ?? undefined,
                commentID: reaction.commentID ?? undefined,
                isCommentReply: reaction.isCommentReply ?? undefined,
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

    const result = {
        comments,
        reactions,
        hasMoreComments: data.hasMoreComments,
        hasMoreReactions: data.hasMoreReactions,
    };
    return result;
};

const RemoteComment = z.object({
    id: z.string(),
    collectionID: z.number(),
    fileID: z.number().nullish(),
    parentCommentID: z.string().nullish(),
    parentCommentUserID: z.number().nullish(),
    userID: z.number(),
    anonUserID: z.string().nullish(),
    cipher: z.string().nullish(),
    nonce: z.string().nullish(),
    isDeleted: z.boolean(),
    createdAt: z.number(),
    updatedAt: z.number(),
});

const RemoteReaction = z.object({
    id: z.string(),
    collectionID: z.number(),
    fileID: z.number().nullish(),
    commentID: z.string().nullish(),
    isCommentReply: z.boolean().nullish(),
    userID: z.number(),
    anonUserID: z.string().nullish(),
    cipher: z.string().nullish(),
    nonce: z.string().nullish(),
    isDeleted: z.boolean(),
    createdAt: z.number(),
    updatedAt: z.number(),
});

const UnifiedDiffResponse = z.object({
    comments: z.array(RemoteComment),
    reactions: z.array(RemoteReaction),
    hasMoreComments: z.boolean(),
    hasMoreReactions: z.boolean(),
});

/**
 * Get anonymous user profiles for a collection.
 *
 * @param collectionID The ID of the collection.
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns Map of anonUserID to decrypted userName.
 */
export const getAnonProfiles = async (
    collectionID: number,
    collectionKey: string,
): Promise<Map<string, string>> => {
    const res = await fetch(
        await apiURL("/social/anon-profiles", { collectionID }),
        { headers: await authenticatedRequestHeaders() },
    );
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
