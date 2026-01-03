import { encryptBox } from "ente-base/crypto";
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
