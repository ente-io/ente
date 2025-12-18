import { decryptBox, encryptBox } from "ente-base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { z } from "zod";

/**
 * A decrypted comment.
 */
export interface Comment {
    id: string;
    collectionID: number;
    fileID?: number;
    parentCommentID?: string;
    /** User ID of the parent comment's author (only in feed responses). */
    parentCommentUserID?: number;
    userID: number;
    anonUserID?: string;
    /** The decrypted comment text. */
    text: string;
    isDeleted: boolean;
    createdAt: number;
    updatedAt: number;
}

/**
 * Get comments for a file in a collection.
 *
 * @param collectionID The ID of the collection containing the file.
 * @param fileID The ID of the file to get comments for.
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns Array of decrypted comments for the file.
 */
export const getFileComments = async (
    collectionID: number,
    fileID: number,
    collectionKey: string,
): Promise<Comment[]> => {
    const res = await fetch(
        await apiURL("/comments/diff", {
            collectionID,
            fileID,
            sinceTime: 0,
            limit: 1000,
        }),
        { headers: await authenticatedRequestHeaders() },
    );
    ensureOk(res);
    const { comments } = GetCommentsResponse.parse(await res.json());

    const decryptedComments: Comment[] = [];
    for (const comment of comments) {
        // Skip deleted comments (they have null cipher/nonce)
        if (comment.isDeleted || !comment.cipher || !comment.nonce) {
            decryptedComments.push({
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
            const decryptedComment = {
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
            };
            decryptedComments.push(decryptedComment);
        } catch (e) {
            // Log and skip comments that fail to decrypt
            console.error("Failed to decrypt comment", comment.id, e);
        }
    }
    return decryptedComments;
};

/**
 * Add a comment to a file in a collection.
 *
 * @param collectionID The ID of the collection containing the file.
 * @param fileID The ID of the file to comment on.
 * @param text The comment text to encrypt.
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @param parentCommentID Optional parent comment ID for replies.
 * @returns The ID of the created comment.
 */
export const addComment = async (
    collectionID: number,
    fileID: number,
    text: string,
    collectionKey: string,
    parentCommentID?: string,
): Promise<string> => {
    const { encryptedData: cipher, nonce } = await encryptBox(
        new TextEncoder().encode(text),
        collectionKey,
    );

    const res = await fetch(await apiURL("/comments"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            collectionID,
            fileID,
            cipher,
            nonce,
            parentCommentID,
        }),
    });
    ensureOk(res);
    const { id } = CreateCommentResponse.parse(await res.json());
    return id;
};

/**
 * Update a comment's content.
 *
 * @param commentID The ID of the comment to update.
 * @param text The new comment text.
 * @param collectionKey The decrypted collection key (base64 encoded).
 */
export const updateComment = async (
    commentID: string,
    text: string,
    collectionKey: string,
): Promise<void> => {
    const { encryptedData: cipher, nonce } = await encryptBox(
        new TextEncoder().encode(text),
        collectionKey,
    );

    const res = await fetch(await apiURL(`/comments/${commentID}`), {
        method: "PATCH",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ cipher, nonce }),
    });
    ensureOk(res);
};

/**
 * Delete a comment by its ID.
 *
 * @param commentID The ID of the comment to delete.
 */
export const deleteComment = async (commentID: string): Promise<void> => {
    const res = await fetch(await apiURL(`/comments/${commentID}`), {
        method: "DELETE",
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
};

const CreateCommentResponse = z.object({ id: z.string() });

const RemoteComment = z.object({
    id: z.string(),
    collectionID: z.number(),
    fileID: z.number().nullish(),
    parentCommentID: z.string().nullish(),
    userID: z.number(),
    anonUserID: z.string().nullish(),
    // cipher and nonce are missing/null for deleted comments
    cipher: z.string().nullish(),
    nonce: z.string().nullish(),
    isDeleted: z.boolean(),
    createdAt: z.number(),
    updatedAt: z.number(),
});

const GetCommentsResponse = z.object({
    comments: z.array(RemoteComment),
    hasMore: z.boolean(),
});
