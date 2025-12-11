import { decryptBox, encryptBox } from "ente-base/crypto";
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
 * Remove null byte padding from a decrypted reaction type.
 */
const unpadReaction = (paddedReaction: string): string =>
    paddedReaction.replace(/\0+$/, "");

/**
 * A decrypted reaction.
 */
export interface Reaction {
    id: string;
    fileID: number;
    reactionType: string;
    userID: number;
    isDeleted: boolean;
}

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
 * Get reactions for a file in a collection.
 *
 * @param collectionID The ID of the collection containing the file.
 * @param fileID The ID of the file to get reactions for.
 * @param collectionKey The decrypted collection key (base64 encoded).
 * @returns Array of decrypted reactions for the file.
 */
export const getFileReactions = async (
    collectionID: number,
    fileID: number,
    collectionKey: string,
): Promise<Reaction[]> => {
    const res = await fetch(
        await apiURL("/reactions/diff", {
            collectionID,
            fileID,
            sinceTime: 0,
            limit: 100,
        }),
        { headers: await authenticatedRequestHeaders() },
    );
    ensureOk(res);
    const { reactions } = GetReactionsResponse.parse(await res.json());

    const decryptedReactions: Reaction[] = [];
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
                reactionType,
                userID: reaction.userID,
                isDeleted: reaction.isDeleted,
            });
        } catch {
            // Skip reactions that fail to decrypt
        }
    }
    return decryptedReactions;
};

const UpsertReactionResponse = z.object({ id: z.string() });

const RemoteReaction = z.object({
    id: z.string(),
    collectionID: z.number(),
    fileID: z.number(),
    userID: z.number(),
    // cipher and nonce are missing/null for deleted reactions
    cipher: z.string().nullish(),
    nonce: z.string().nullish(),
    isDeleted: z.boolean(),
    createdAt: z.number(),
    updatedAt: z.number(),
});

const GetReactionsResponse = z.object({
    reactions: z.array(RemoteReaction),
    hasMore: z.boolean(),
});

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
