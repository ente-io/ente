import { sharedCryptoWorker } from "@/base/crypto";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { SUB_TYPE, type Collection } from "@/media/collection";
import { type EnteFile } from "@/media/file";
import { ItemVisibility } from "@/media/file-metadata";
import { batch } from "@/utils/array";
import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
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

export interface EncryptedFileKey {
    id: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
}

export interface AddToCollectionRequest {
    collectionID: number;
    files: EncryptedFileKey[];
}

export interface MoveToCollectionRequest {
    fromCollectionID: number;
    toCollectionID: number;
    files: EncryptedFileKey[];
}

export const addToCollection = async (
    collection: Collection,
    files: EnteFile[],
) => {
    try {
        const token = getToken();
        const batchedFiles = batch(files, requestBatchSize);
        for (const batch of batchedFiles) {
            const fileKeysEncryptedWithNewCollection =
                await encryptWithNewCollectionKey(collection, batch);

            const requestBody: AddToCollectionRequest = {
                collectionID: collection.id,
                files: fileKeysEncryptedWithNewCollection,
            };
            await HTTPService.post(
                await apiURL("/collections/add-files"),
                requestBody,
                null,
                {
                    "X-Auth-Token": token,
                },
            );
        }
    } catch (e) {
        log.error("Add to collection Failed ", e);
        throw e;
    }
};

export const restoreToCollection = async (
    collection: Collection,
    files: EnteFile[],
) => {
    try {
        const token = getToken();
        const batchedFiles = batch(files, requestBatchSize);
        for (const batch of batchedFiles) {
            const fileKeysEncryptedWithNewCollection =
                await encryptWithNewCollectionKey(collection, batch);

            const requestBody: AddToCollectionRequest = {
                collectionID: collection.id,
                files: fileKeysEncryptedWithNewCollection,
            };
            await HTTPService.post(
                await apiURL("/collections/restore-files"),
                requestBody,
                null,
                {
                    "X-Auth-Token": token,
                },
            );
        }
    } catch (e) {
        log.error("restore to collection Failed ", e);
        throw e;
    }
};
export const moveToCollection = async (
    fromCollectionID: number,
    toCollection: Collection,
    files: EnteFile[],
) => {
    try {
        const token = getToken();
        const batchedFiles = batch(files, requestBatchSize);
        for (const batch of batchedFiles) {
            const fileKeysEncryptedWithNewCollection =
                await encryptWithNewCollectionKey(toCollection, batch);

            const requestBody: MoveToCollectionRequest = {
                fromCollectionID: fromCollectionID,
                toCollectionID: toCollection.id,
                files: fileKeysEncryptedWithNewCollection,
            };
            await HTTPService.post(
                await apiURL("/collections/move-files"),
                requestBody,
                null,
                {
                    "X-Auth-Token": token,
                },
            );
        }
    } catch (e) {
        log.error("move to collection Failed ", e);
        throw e;
    }
};

const encryptWithNewCollectionKey = async (
    newCollection: Collection,
    files: EnteFile[],
): Promise<EncryptedFileKey[]> => {
    const fileKeysEncryptedWithNewCollection: EncryptedFileKey[] = [];
    const cryptoWorker = await sharedCryptoWorker();
    for (const file of files) {
        const newEncryptedKey = await cryptoWorker.encryptToB64(
            file.key,
            newCollection.key,
        );
        const encryptedKey = newEncryptedKey.encryptedData;
        const keyDecryptionNonce = newEncryptedKey.nonce;

        fileKeysEncryptedWithNewCollection.push({
            id: file.id,
            encryptedKey,
            keyDecryptionNonce,
        });
    }
    return fileKeysEncryptedWithNewCollection;
};
