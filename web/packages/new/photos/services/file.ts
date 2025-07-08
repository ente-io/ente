import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import type { EnteFile } from "ente-media/file";
import type {
    FilePrivateMagicMetadataData,
    FilePublicMagicMetadataData,
    ItemVisibility,
} from "ente-media/file-metadata";
import {
    createMagicMetadata,
    encryptMagicMetadata,
    type RemoteMagicMetadata,
} from "ente-media/magic-metadata";
import { batch } from "ente-utils/array";
import { savedHiddenCollections } from "./collection";
import { savedCollectionFiles } from "./photos-fdb";

/**
 * An reasonable but otherwise arbitrary number of items (e.g. files) to include
 * in a single API request.
 *
 * Remote will reject too big payloads, and requests which affect multiple items
 * (e.g. files when moving files to a collection, changing the visibility of
 * selected files) are expected to be batched to keep each request of a
 * reasonable size. By default, we break the request into batches of 1000.
 */
const requestBatchSize = 1000;

/**
 * Perform an operation on batches, serially.
 *
 * The given {@link items} are split into batches, each of
 * {@link requestBatchSize}. The provided operation is called on all these
 * batches, one after the other. When all the operations are complete, the
 * function returns with an array of results (one from each batch promise
 * resolution).
 *
 * @param items The arbitrary items to break into {@link requestBatchSize}
 * batches.
 *
 * @param op The operation to perform on each batch.
 *
 * @returns A promise for an array of results, one from each batch operation. If
 * any operations fails, then the promise rejects with its failure reason.
 */
export const batched = async <T, U>(
    items: T[],
    op: (batchItems: T[]) => Promise<U>,
): Promise<U[]> => {
    const result: U[] = [];
    for (const b of batch(items, requestBatchSize)) result.push(await op(b));
    return result;
};

/**
 * Return all normal (non-hidden) files present in our local database.
 *
 * The long name and the "compute" in it is to signal that this is not just a DB
 * read, and that it also does some potentially non-trivial computation.
 */
export const computeNormalCollectionFilesFromSaved = async () => {
    const hiddenCollections = await savedHiddenCollections();
    const hiddenCollectionIDs = new Set(hiddenCollections.map((c) => c.id));

    const collectionFiles = await savedCollectionFiles();
    const hiddenFileIDs = new Set(
        collectionFiles
            .filter((f) => hiddenCollectionIDs.has(f.collectionID))
            .map((f) => f.id),
    );

    return collectionFiles.filter((f) => !hiddenFileIDs.has(f.id));
};

/**
 * Change the visibility (normal, archived, hidden) of a list of files on
 * remote.
 *
 * Remote only, does not modify local state.
 *
 * The visibility of an {@link EnteFile} is stored in its private magic
 * metadata, so this function in effect updates the private magic metadata of
 * the given files on remote.
 *
 * @param files The list of files whose visibility we want to change. All the
 * files will get their visibility updated to the new, provided, value.
 *
 * @param visibility The new visibility (normal, archived, hidden).
 */
export const updateFilesVisibility = async (
    files: EnteFile[],
    visibility: ItemVisibility,
) => batched(files, (b) => updateFilesPrivateMagicMetadata(b, { visibility }));

/**
 * Update the private magic metadata of a list of files on remote.
 *
 * Remote only, does not modify local state.
 *
 * @param file The list of files whose magic metadata we want to update. The
 * same updates will be applied to the magic metadata of all the files.
 *
 * The existing magic metadata of the provided files is used both to obtain the
 * current magic metadata version, and the existing contents on top of which the
 * updates are applied, so it is imperative that both these values are up to
 * sync with remote otherwise the update will fail.
 *
 * @param updates A non-empty subset of {@link FilePrivateMagicMetadataData}
 * entries.
 *
 * See: [Note: Magic metadata data cannot have nullish values]
 */
const updateFilesPrivateMagicMetadata = async (
    files: EnteFile[],
    updates: FilePrivateMagicMetadataData,
) =>
    putFilesMagicMetadata({
        metadataList: await Promise.all(
            files.map(async ({ id, key, magicMetadata }) => ({
                id,
                magicMetadata: await encryptMagicMetadata(
                    createMagicMetadata(
                        { ...magicMetadata?.data, ...updates },
                        magicMetadata?.version,
                    ),
                    key,
                ),
            })),
        ),
    });

/**
 * The payload of the remote requests for updating the magic metadata of a
 * single item (file or collection).
 */
export interface UpdateMagicMetadataRequest {
    /**
     * File or collection ID
     */
    id: number;
    /**
     * The updated magic metadata.
     *
     * Remote usually enforces the following constraints when we're trying to
     * update already existing data.
     *
     * - The version should be same as the existing version.
     * - The count should be greater than or equal to the existing count.
     */
    magicMetadata: RemoteMagicMetadata;
}

/**
 * The payload of the remote requests for updating the magic metadata of a
 * multiple items.
 *
 * Currently this is only used by endpoints that update magic metadata for a
 * list of files.
 */
export interface UpdateMultipleMagicMetadataRequest {
    metadataList: UpdateMagicMetadataRequest[];
}

/**
 * Update the private magic metadata of a list of files on remote.
 */
const putFilesMagicMetadata = async (
    updateRequest: UpdateMultipleMagicMetadataRequest,
) =>
    ensureOk(
        await fetch(await apiURL("/files/magic-metadata"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(updateRequest),
        }),
    );

/**
 * Update the file name of the provided file on remote.
 *
 * Remote only, does not modify local state.
 *
 * The file name of an {@link EnteFile} is stored in its public magic metadata,
 * so this function in effect updates the public magic metadata of the given
 * file on remote.
 *
 * @param file The file whose file name we want to change.
 *
 * @param newFileName The new file name of the file.
 */
export const updateFileFileName = (file: EnteFile, newFileName: string) =>
    updateFilePublicMagicMetadata(file, { editedName: newFileName });

/**
 * Update the caption associated with the provided file on remote.
 *
 * Remote only, does not modify local state.
 *
 * The caption of an {@link EnteFile} is stored in its public magic metadata, so
 * this function in effect updates the public magic metadata of the given file
 * on remote.
 *
 * @param file The file whose file name we want to change.
 *
 * @param caption The caption associated with the file.
 *
 * Fields in magic metadata cannot be removed after being added, so to reset the
 * caption to the default (no value) state pass a blank string.
 */
export const updateFileCaption = (file: EnteFile, caption: string) =>
    updateFilePublicMagicMetadata(file, { caption });

/**
 * Update the public magic metadata of a file on remote.
 *
 * Remote only, does not modify local state.
 *
 * @param file The list of files whose magic metadata we want to update.
 *
 * @param updates A non-empty but otherwise arbitrary subset of
 * {@link FilePrivateMagicMetadataData} entries.
 *
 * See: [Note: Magic metadata data cannot have nullish values]
 */
export const updateFilePublicMagicMetadata = async (
    file: EnteFile,
    updates: FilePublicMagicMetadataData,
) => updateFilesPublicMagicMetadata([file], updates);

/**
 * Update the public magic metadata of a list of files on remote.
 *
 * Remote only, does not modify local state.
 *
 * This is a variant of {@link updateFilePrivateMagicMetadata} that works with
 * the {@link pubMagicMetadata} of the given files.
 */
const updateFilesPublicMagicMetadata = async (
    files: EnteFile[],
    updates: FilePublicMagicMetadataData,
) =>
    putFilesPublicMagicMetadata({
        metadataList: await Promise.all(
            files.map(async ({ id, key, pubMagicMetadata }) => ({
                id,
                magicMetadata: await encryptMagicMetadata(
                    createMagicMetadata(
                        { ...pubMagicMetadata?.data, ...updates },
                        pubMagicMetadata?.version,
                    ),
                    key,
                ),
            })),
        ),
    });

/**
 * Update the public magic metadata of a list of files on remote.
 */
const putFilesPublicMagicMetadata = async (
    updateRequest: UpdateMultipleMagicMetadataRequest,
) =>
    ensureOk(
        await fetch(await apiURL("/files/public-magic-metadata"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(updateRequest),
        }),
    );
