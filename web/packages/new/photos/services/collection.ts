import { encryptBoxB64 } from "@/base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { apiURL } from "@/base/origins";
import { SUB_TYPE, type Collection } from "@/media/collection";
import { type EnteFile } from "@/media/file";
import { ItemVisibility } from "@/media/file-metadata";
import { batch } from "@/utils/array";
import type { User } from "@ente/shared/user/types";

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
    collection.magicMetadata?.data.subType === SUB_TYPE.DEFAULT_HIDDEN;

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
            const box = await encryptBoxB64(file.key, collection.key);
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
