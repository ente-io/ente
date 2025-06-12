import type { User } from "ente-accounts/services/user";
import { boxSeal, encryptBox } from "ente-base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import {
    CollectionSubType,
    type Collection,
    type CollectionNewParticipantRole,
} from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { ItemVisibility } from "ente-media/file-metadata";
import { batch } from "ente-utils/array";
import { getPublicKey } from "./user";

/**
 * An reasonable but otherwise arbitrary number of items (e.g. files) to include
 * in a single API request.
 *
 * Remote will reject too big payloads, and requests which affect multiple items
 * (e.g. files when moving files to a collection) are expected to be batched to
 * keep each request of a reasonable size. By default, we break the request into
 * batches of 1000.
 */
const requestBatchSize = 1000;

export const ARCHIVE_SECTION = -1;
export const TRASH_SECTION = -2;
export const DUMMY_UNCATEGORIZED_COLLECTION = -3;
export const HIDDEN_ITEMS_SECTION = -4;
export const ALL_SECTION = 0;

/**
 * Return true if this is a default hidden collection.
 *
 * See also: [Note: Multiple "default" hidden collections].
 */
export const isDefaultHiddenCollection = (collection: Collection) =>
    // TODO: Need to audit the types
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    collection.magicMetadata?.data.subType == CollectionSubType.defaultHidden;

/**
 * Extract the IDs of all the "default" hidden collections.
 *
 * [Note: Multiple "default" hidden collections].
 *
 * Normally, there is only expected to be one such collection. But to provide
 * clients laxity in synchronization, we don't enforce this and instead allow
 * for multiple such default hidden collections to exist.
 */
export const findDefaultHiddenCollectionIDs = (collections: Collection[]) =>
    new Set<number>(
        collections
            .filter(isDefaultHiddenCollection)
            .map((collection) => collection.id),
    );

/**
 * Return true if this is a collection that the user doesn't own.
 */
export const isIncomingShare = (collection: Collection, user: User) =>
    collection.owner.id !== user.id;

export const isHiddenCollection = (collection: Collection) =>
    // TODO: Need to audit the types
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    collection.magicMetadata?.data.visibility === ItemVisibility.hidden;

export const DEFAULT_HIDDEN_COLLECTION_USER_FACING_NAME = "Hidden";

/**
 * Return the "user facing" name of the given collection.
 *
 * Usually this is the same as the collection name, but it might be a different
 * string for special collections like default hidden collections.
 */
export const getCollectionUserFacingName = (collection: Collection) => {
    if (isDefaultHiddenCollection(collection)) {
        return DEFAULT_HIDDEN_COLLECTION_USER_FACING_NAME;
    }
    return collection.name;
};

/**
 * Create a new collection on remote, and return its local representation.
 *
 * Remote only, does not modify local state.
 *
 * @param name The name of the new collection.
 *
 * @param type The type of the new collection.
 *
 * @param magicMetadata Optional metadata to use as the collection's private
 * mutable metadata when creating the new collection.
 */
export const createCollection => {

}

/**
 * Return a map of the (user-facing) collection name, indexed by collection ID.
 */
export const createCollectionNameByID = (collections: Collection[]) =>
    new Map(collections.map((c) => [c.id, getCollectionUserFacingName(c)]));

/**
 * A CollectionFileItem represents a file in a API request to add, move or
 * restore files to a particular collection.
 */
interface CollectionFileItem {
    /**
     * The file's ID.
     */
    id: number;
    /**
     * The file's key (as a base64 string), encrypted with the key of the
     * collection to which it is being added or moved.
     */
    encryptedKey: string;
    /**
     * The nonce (as a base64 string) that was used during the encryption of
     * {@link encryptedKey}.
     */
    keyDecryptionNonce: string;
}

export interface AddToCollectionRequest {
    collectionID: number;
    files: CollectionFileItem[];
}

export interface MoveToCollectionRequest {
    fromCollectionID: number;
    toCollectionID: number;
    files: CollectionFileItem[];
}

/**
 * Make a remote request to add the given {@link files} to the given
 * {@link collection}.
 *
 * Does not modify local state.
 */
export const addToCollection = async (
    collection: Collection,
    files: EnteFile[],
) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
        const encryptedFileKeys = await encryptWithCollectionKey(
            collection,
            batchFiles,
        );
        ensureOk(
            await fetch(await apiURL("/collections/add-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    collectionID: collection.id,
                    files: encryptedFileKeys,
                }),
            }),
        );
    }
};

/**
 * Make a remote request to restore the given {@link files} to the given
 * {@link collection}.
 *
 * Does not modify local state.
 */
export const restoreToCollection = async (
    collection: Collection,
    files: EnteFile[],
) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
        const encryptedFileKeys = await encryptWithCollectionKey(
            collection,
            batchFiles,
        );
        ensureOk(
            await fetch(await apiURL("/collections/restore-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    collectionID: collection.id,
                    files: encryptedFileKeys,
                }),
            }),
        );
    }
};

/**
 * Make a remote request to move the given {@link files} from a collection (as
 * identified by its {@link fromCollectionID}) to the given
 * {@link toCollection}.
 *
 * Does not modify local state.
 */
export const moveToCollection = async (
    fromCollectionID: number,
    toCollection: Collection,
    files: EnteFile[],
) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
        const encryptedFileKeys = await encryptWithCollectionKey(
            toCollection,
            batchFiles,
        );
        ensureOk(
            await fetch(await apiURL("/collections/move-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    fromCollectionID: fromCollectionID,
                    toCollectionID: toCollection.id,
                    files: encryptedFileKeys,
                }),
            }),
        );
    }
};

/**
 * Return an array of {@link CollectionFileItem}s, one for each file in
 * {@link files}, containing the corresponding file' ID and keys, but this time
 * encrypted using the key of the given {@link collection}.
 */
const encryptWithCollectionKey = async (
    collection: Collection,
    files: EnteFile[],
): Promise<CollectionFileItem[]> =>
    Promise.all(
        files.map(async (file) => {
            const box = await encryptBox(file.key, collection.key);
            return {
                id: file.id,
                encryptedKey: box.encryptedData,
                keyDecryptionNonce: box.nonce,
            };
        }),
    );

/**
 * Make a remote request to move the given {@link files} to trash.
 *
 * @param files The {@link EnteFile}s to move to trash. The API request needs
 * both a file ID and a collection ID, but there should be at most one entry for
 * a particular fileID in this array.
 *
 * Does not modify local state.
 */
export const moveToTrash = async (files: EnteFile[]) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
        ensureOk(
            await fetch(await apiURL("/files/trash"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    items: batchFiles.map((file) => ({
                        fileID: file.id,
                        collectionID: file.collectionID,
                    })),
                }),
            }),
        );
    }
};

/**
 * Make a remote request to delete the given {@link fileIDs} from trash.
 *
 * Does not modify local state.
 */
export const deleteFromTrash = async (fileIDs: number[]) => {
    for (const batchIDs of batch(fileIDs, requestBatchSize)) {
        ensureOk(
            await fetch(await apiURL("/trash/delete"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({ fileIDs: batchIDs }),
            }),
        );
    }
};

/**
 * Share the provided collection with another Ente user.
 *
 * Remote only, does not modify local state.
 *
 * @param collection The {@link Collection} to share.
 *
 * @param withUserEmail The email of the Ente user with whom to share it.
 *
 * @param role The desired role for the new participant.
 */
export const shareCollection = async (
    collection: Collection,
    withUserEmail: string,
    role: CollectionNewParticipantRole,
) => {
    const publicKey = await getPublicKey(withUserEmail);
    const encryptedKey = await boxSeal(collection.key, publicKey);

    const res = await fetch(await apiURL("/collections/share"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({
            collectionID: collection.id,
            email: withUserEmail,
            role: role,
            encryptedKey,
        }),
    });
    ensureOk(res);
};

/**
 * Delete the public link for the collection with given {@link collectionID}.
 *
 * Remote only, does not modify local state.
 */
export const deleteShareURL = async (collectionID: number) =>
    ensureOk(
        await fetch(await apiURL(`/collections/share-url/${collectionID}`), {
            method: "DELETE",
            headers: await authenticatedRequestHeaders(),
        }),
    );

/**
 * Leave a collection which had previously been shared with the user.
 *
 * Remote only, does not modify local state.
 *
 * @param collectionID The ID of the shared collection to leave.
 */
export const leaveSharedCollection = async (collectionID: number) =>
    ensureOk(
        await fetch(await apiURL(`/collections/leave/${collectionID}`), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
        }),
    );
