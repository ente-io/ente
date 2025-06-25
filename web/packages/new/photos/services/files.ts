import { blobCache } from "ente-base/blob-cache";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import type { Collection } from "ente-media/collection";
import {
    decryptRemoteFile,
    type EnteFile,
    type RemoteEnteFile,
} from "ente-media/file";
import { metadataHash } from "ente-media/file-metadata";
import HTTPService from "ente-shared/network/HTTPService";
import { getToken } from "ente-shared/storage/localStorage/helpers";
import {
    saveCollectionFiles,
    saveCollectionLastSyncTime,
    savedCollectionFiles,
    savedCollectionLastSyncTime,
} from "./photos-fdb";

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
export const pullCollectionFiles = async (
    collections: Collection[],
    onSetCollectionFiles: ((files: EnteFile[]) => void) | undefined,
    onAugmentCollectionFiles: ((files: EnteFile[]) => void) | undefined,
) => {
    const localFiles = await savedCollectionFiles();
    let files = removeDeletedCollectionFiles(collections, localFiles);
    let didUpdateFiles = false;
    if (files.length !== localFiles.length) {
        await saveCollectionFiles(files);
        onSetCollectionFiles?.(files);
        didUpdateFiles = true;
    }
    for (const collection of collections) {
        if (!getToken()) {
            continue;
        }
        const lastSyncTime =
            (await savedCollectionLastSyncTime(collection)) ?? 0;
        if (collection.updationTime === lastSyncTime) {
            continue;
        }

        const newFiles = await getFiles(
            collection,
            lastSyncTime,
            onAugmentCollectionFiles,
        );
        await clearCachedThumbnailsIfChanged(localFiles, newFiles);
        files = getLatestVersionFiles([...files, ...newFiles]);
        await saveCollectionFiles(files);
        didUpdateFiles = true;
        await saveCollectionLastSyncTime(collection, collection.updationTime);
    }
    return didUpdateFiles;
};

export const getFiles = async (
    collection: Collection,
    sinceTime: number,
    onFetchFiles: ((fs: EnteFile[]) => void) | undefined,
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
                resp.data.diff.map(async (file: RemoteEnteFile) => {
                    if (!file.isDeleted) {
                        return await decryptRemoteFile(file, collection.key);
                    } else {
                        return file;
                    }
                }) as Promise<EnteFile>[],
            );
            decryptedFiles = [...decryptedFiles, ...newDecryptedFilesBatch];

            onFetchFiles?.(decryptedFiles);
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
const clearCachedThumbnailsIfChanged = async (
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

export function getLatestVersionFiles(files: EnteFile[]) {
    const latestVersionFiles = new Map<string, EnteFile>();
    files.forEach((file) => {
        const uid = `${file.collectionID}-${file.id}`;
        const existingFile = latestVersionFiles.get(uid);
        if (!existingFile || existingFile.updationTime < file.updationTime) {
            latestVersionFiles.set(uid, file);
        }
    });
    return Array.from(latestVersionFiles.values()).filter(
        // TODO(RE):
        // (file) => !file.isDeleted,
        (file) => !("isDeleted" in file && file.isDeleted),
    );
}
