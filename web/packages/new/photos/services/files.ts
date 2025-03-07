import { blobCache } from "@/base/blob-cache";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import type { Collection } from "@/media/collection";
import {
    decryptFile,
    mergeMetadata,
    type EncryptedEnteFile,
    type EnteFile,
    type Trash,
} from "@/media/file";
import { metadataHash } from "@/media/file-metadata";
import HTTPService from "@ente/shared/network/HTTPService";
import localForage from "@ente/shared/storage/localForage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import {
    getCollectionLastSyncTime,
    setCollectionLastSyncTime,
} from "./collections";

const FILES_TABLE = "files";
const HIDDEN_FILES_TABLE = "hidden-files";

/**
 * Return all files that we know about locally, both "normal" and "hidden".
 */
export const getAllLocalFiles = async () =>
    (await getLocalFiles("normal")).concat(await getLocalFiles("hidden"));

/**
 * Return all files that we know about locally. By default it returns only
 * "normal" (i.e. non-"hidden") files, but it can be passed the {@link type}
 * "hidden" to get it to instead return hidden files that we know about locally.
 */
export const getLocalFiles = async (type: "normal" | "hidden" = "normal") => {
    const tableName = type === "normal" ? FILES_TABLE : HIDDEN_FILES_TABLE;
    const files: EnteFile[] =
        (await localForage.getItem<EnteFile[]>(tableName)) ?? [];
    return files;
};

/**
 * Update the files that we know about locally.
 *
 * Sibling of {@link getLocalFiles}.
 */
export const setLocalFiles = async (
    type: "normal" | "hidden",
    files: EnteFile[],
) => {
    const tableName = type === "normal" ? FILES_TABLE : HIDDEN_FILES_TABLE;
    await localForage.setItem(tableName, files);
};

/**
 * Fetch all files of the given {@link type}, belonging to the given
 * {@link collections}, from remote and update our local database.
 *
 * If this is the initial read, or if the count of files we have differs from
 * the state of the local database (these two are expected to be the same case),
 * then the {@link onResetFiles} callback is invoked to give the caller a chance
 * to bring its state up to speed.
 *
 * In addition to updating the local database, it also calls the provided
 * {@link onFetchFiles} callback with the latest decrypted files after each
 * batch the new and/or updated files are received from remote.
 *
 * @returns true if one or more files were updated locally, false otherwise.
 */
export const syncFiles = async (
    type: "normal" | "hidden",
    collections: Collection[],
    onResetFiles: (fs: EnteFile[]) => void,
    onFetchFiles: (fs: EnteFile[]) => void,
) => {
    const localFiles = await getLocalFiles(type);
    let files = removeDeletedCollectionFiles(collections, localFiles);
    let didUpdateFiles = false;
    if (files.length !== localFiles.length) {
        await setLocalFiles(type, files);
        onResetFiles(files);
        didUpdateFiles = true;
    }
    for (const collection of collections) {
        if (!getToken()) {
            continue;
        }
        const lastSyncTime = await getCollectionLastSyncTime(collection);
        if (collection.updationTime === lastSyncTime) {
            continue;
        }

        const newFiles = await getFiles(collection, lastSyncTime, onFetchFiles);
        await clearCachedThumbnailsIfChanged(localFiles, newFiles);
        files = getLatestVersionFiles([...files, ...newFiles]);
        await setLocalFiles(type, files);
        didUpdateFiles = true;
        await setCollectionLastSyncTime(collection, collection.updationTime);
    }
    return didUpdateFiles;
};

export const getFiles = async (
    collection: Collection,
    sinceTime: number,
    onFetchFiles: (fs: EnteFile[]) => void,
): Promise<EnteFile[]> => {
    try {
        let decryptedFiles: EnteFile[] = [];
        let time = sinceTime;
        let resp;
        do {
            const token = getToken();
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                await apiURL("/collections/v2/diff"),
                { collectionID: collection.id, sinceTime: time },
                { "X-Auth-Token": token },
            );

            const newDecryptedFilesBatch = await Promise.all(
                // eslint-disable-next-line @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access
                resp.data.diff.map(async (file: EncryptedEnteFile) => {
                    if (!file.isDeleted) {
                        return await decryptFile(file, collection.key);
                    } else {
                        return file;
                    }
                }) as Promise<EnteFile>[],
            );
            decryptedFiles = [...decryptedFiles, ...newDecryptedFilesBatch];

            onFetchFiles(decryptedFiles);
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            if (resp.data.diff.length) {
                // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        } while (resp.data.hasMore);
        return decryptedFiles;
    } catch (e) {
        log.error("Get files failed", e);
        throw e;
    }
};

const removeDeletedCollectionFiles = (
    collections: Collection[],
    files: EnteFile[],
) => {
    const syncedCollectionIds = new Set<number>();
    for (const collection of collections) {
        syncedCollectionIds.add(collection.id);
    }
    files = files.filter((file) => syncedCollectionIds.has(file.collectionID));
    return files;
};

/**
 * Sort the given list of {@link EnteFile}s in place.
 *
 * Like the JavaScript Array#sort, this method modifies the {@link files}
 * argument. It sorts {@link files} in place, and then returns a reference to
 * the same mutated array.
 *
 * By default, files are sorted so that the newest one is first. The optional
 * {@link sortAsc} flag can be set to `true` to sort them so that the oldest one
 * is first.
 */
export const sortFiles = (files: EnteFile[], sortAsc = false) => {
    // Sort based on the time of creation time of the file.
    //
    // For files with same creation time, sort based on the time of last
    // modification.
    const factor = sortAsc ? -1 : 1;
    return files.sort((a, b) => {
        if (a.metadata.creationTime === b.metadata.creationTime) {
            return (
                factor *
                (b.metadata.modificationTime - a.metadata.modificationTime)
            );
        }
        return factor * (b.metadata.creationTime - a.metadata.creationTime);
    });
};

/**
 * [Note: Collection File]
 *
 * File IDs themselves are unique across all the files for the user (in fact,
 * they're unique across all the files in an Ente instance). However, we still
 * can have multiple entries for the same file ID in our local database because
 * the unit of account is not actually a file, but a "Collection File": a
 * collection and file pair.
 *
 * For example, if the same file is symlinked into two collections, then we will
 * have two "Collection File" entries for it, both with the same file ID, but
 * with different collection IDs.
 *
 * This function returns files such that only one of these entries is returned.
 * The entry that is returned is arbitrary in general, this function just picks
 * the first one for each unique file ID.
 *
 * If this function is invoked on a list on which {@link sortFiles} has already
 * been called, which by default sorts such that the newest file is first, then
 * this function's behaviour would be to return the newest file from among
 * multiple files with the same ID but different collections.
 */
export const uniqueFilesByID = (files: EnteFile[]) => {
    const seen = new Set<number>();
    return files.filter(({ id }) => {
        if (seen.has(id)) return false;
        seen.add(id);
        return true;
    });
};

export const TRASH = "file-trash";

export async function getLocalTrash() {
    const trash = (await localForage.getItem<Trash>(TRASH)) ?? [];
    return trash;
}

export async function getLocalTrashedFiles() {
    return getTrashedFiles(await getLocalTrash());
}

export function getTrashedFiles(trash: Trash): EnteFile[] {
    return sortTrashFiles(
        mergeMetadata(
            trash.map((trashedFile) => ({
                ...trashedFile.file,
                updationTime: trashedFile.updatedAt,
                deleteBy: trashedFile.deleteBy,
                isTrashed: true,
            })),
        ),
    );
}

const sortTrashFiles = (files: EnteFile[]) => {
    return files.sort((a, b) => {
        if (a.deleteBy === b.deleteBy) {
            if (a.metadata.creationTime === b.metadata.creationTime) {
                return (
                    b.metadata.modificationTime - a.metadata.modificationTime
                );
            }
            return b.metadata.creationTime - a.metadata.creationTime;
        }
        return (a.deleteBy ?? 0) - (b.deleteBy ?? 0);
    });
};

/**
 * Clear cached thumbnails for existing files if the thumbnail data has changed.
 *
 * This function in expected to be called when we are processing a collection
 * diff, updating our local state to reflect files that were updated on remote.
 * We use this as an opportune moment to invalidate any cached thumbnails which
 * have changed.
 *
 * An example of when such invalidation is necessary:
 *
 * 1. Take a photo on mobile, and let it sync via the mobile app to us (web).
 * 2. Edit the photo outside of Ente (e.g. using Apple Photos).
 * 3. When the Ente mobile client next comes into foreground, it'll update the
 *    remote thumbnail for the existing file to reflect the changes.
 *
 * @param existingFiles The {@link EnteFile}s we had in our local database
 * before processing the diff response.
 *
 * @param newFiles The {@link EnteFile}s which we got in the diff response.
 */
export const clearCachedThumbnailsIfChanged = async (
    existingFiles: EnteFile[],
    newFiles: EnteFile[],
) => {
    if (newFiles.length == 0) {
        // Fastpath to no-op if nothing changes.
        return;
    }

    // TODO: This should be constructed once, at the caller (currently the
    // caller doesn't need this, but we'll only know for sure after we
    // consolidate all processing that happens during a diff parse).
    const existingFileByID = new Map(existingFiles.map((f) => [f.id, f]));

    for (const newFile of newFiles) {
        const existingFile = existingFileByID.get(newFile.id);
        const m1 = existingFile?.metadata;
        const m2 = newFile.metadata;
        // TODO: Add an extra truthy check the EnteFile type is null safe
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (!m1 || !m2) continue;
        // Both files exist, have metadata, but their hashes differ, which
        // indicates that the change was in the file's contents, not the
        // metadata itself, and thus we should refresh the thumbnail.
        if (metadataHash(m1) != metadataHash(m2)) {
            // This is an infrequent occurrence, so we lazily get the cache.
            const thumbnailCache = await blobCache("thumbs");
            const key = newFile.id.toString();
            await thumbnailCache.delete(key);
        }
    }
};

/**
 * Segment the given {@link files} into lists indexed by their collection ID.
 *
 * Order is preserved.
 */
export const groupFilesByCollectionID = (files: EnteFile[]) =>
    files.reduce((result, file) => {
        const id = file.collectionID;
        let cfs = result.get(id);
        if (!cfs) result.set(id, (cfs = []));
        cfs.push(file);
        return result;
    }, new Map<number, EnteFile[]>());

/**
 * Construct a map from file IDs to the list of collections (IDs) to which the
 * file belongs.
 */
export const createFileCollectionIDs = (files: EnteFile[]) =>
    files.reduce((result, file) => {
        const id = file.id;
        let fs = result.get(id);
        if (!fs) result.set(id, (fs = []));
        fs.push(file.collectionID);
        return result;
    }, new Map<number, number[]>());

export function getLatestVersionFiles(files: EnteFile[]) {
    const latestVersionFiles = new Map<string, EnteFile>();
    files.forEach((file) => {
        const uid = `${file.collectionID}-${file.id}`;
        if (
            !latestVersionFiles.has(uid) ||
            // See: [Note: strict mode migration]
            //
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            latestVersionFiles.get(uid).updationTime < file.updationTime
        ) {
            latestVersionFiles.set(uid, file);
        }
    });
    return Array.from(latestVersionFiles.values()).filter(
        (file) => !file.isDeleted,
    );
}
