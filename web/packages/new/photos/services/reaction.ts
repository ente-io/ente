import { encryptBox } from "ente-base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
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
 * Add a reaction to a file in a collection.
 *
 * @param collectionID The ID of the collection containing the file.
 * @param fileID The ID of the file to react to.
 * @param reactionType The type of reaction (e.g., "green_heart").
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns The ID of the created reaction.
 */
export const addReaction = async (
    collectionID: number,
    fileID: number,
    reactionType: string,
    collectionKey: string,
): Promise<string> => {
    const { encryptedData: cipher, nonce } = await encryptBox(
        new TextEncoder().encode(padReaction(reactionType)),
        collectionKey,
    );

    const res = await fetch(await apiURL("/reactions"), {
        method: "PUT",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ collectionID, fileID, cipher, nonce }),
    });
    ensureOk(res);
    const { id } = UpsertReactionResponse.parse(await res.json());
    return id;
};

/**
 * Add a reaction to a comment in a collection.
 *
 * @param collectionID The ID of the collection containing the comment.
 * @param commentID The ID of the comment to react to.
 * @param reactionType The type of reaction (e.g., "green_heart").
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @param fileID Optional file ID, required for file-scoped comments.
 * @returns The ID of the created reaction.
 */
export const addCommentReaction = async (
    collectionID: number,
    commentID: string,
    reactionType: string,
    collectionKey: string,
    fileID?: number,
): Promise<string> => {
    const { encryptedData: cipher, nonce } = await encryptBox(
        new TextEncoder().encode(padReaction(reactionType)),
        collectionKey,
    );

    const res = await fetch(await apiURL("/reactions"), {
        method: "PUT",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            collectionID,
            commentID,
            fileID,
            cipher,
            nonce,
        }),
    });
    ensureOk(res);
    const { id } = UpsertReactionResponse.parse(await res.json());
    return id;
};

const UpsertReactionResponse = z.object({ id: z.string() });

/**
 * Delete a reaction by its ID.
 *
 * @param reactionID The ID of the reaction to delete.
 */
export const deleteReaction = async (reactionID: string): Promise<void> => {
    const res = await fetch(await apiURL(`/reactions/${reactionID}`), {
        method: "DELETE",
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
};
