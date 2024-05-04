import { FILE_TYPE } from "@/media/file-type";
import { isNonWebImageFileExtension } from "@/media/formats";
import { decodeLivePhoto } from "@/media/live-photo";
import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import { ensureString } from "@/utils/ensure";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { CustomError, parseSharingErrorCodes } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getCastFileURL, getEndpoint } from "@ente/shared/network/api";
import localForage from "@ente/shared/storage/localForage";
import { detectMediaMIMEType } from "services/detect-type";
import { Collection, CollectionPublicMagicMetadata } from "types/collection";
import {
    EncryptedEnteFile,
    EnteFile,
    FileMagicMetadata,
    FilePublicMagicMetadata,
} from "types/file";

export interface SavedCollectionFiles {
    collectionLocalID: string;
    files: EnteFile[];
}

const ENDPOINT = getEndpoint();
const COLLECTION_FILES_TABLE = "collection-files";
const COLLECTIONS_TABLE = "collections";

/**
 * Save the data received after pairing with a sender into local storage.
 *
 * We will read in back when we start the slideshow.
 */
export const storeCastData = (payload: unknown) => {
    if (!payload || typeof payload != "object")
        throw new Error("Unexpected cast data");

    // Iterate through all the keys of the payload object and save them to
    // localStorage. We don't validate here, we'll validate when we read these
    // values back in `readCastData`.
    for (const key in payload) {
        window.localStorage.setItem(key, payload[key]);
    }
};

interface CastData {
    /** A key to decrypt the collection we are casting. */
    collectionKey: string;
    /** A credential to use for fetching media files for this cast session. */
    castToken: string;
}

/**
 * Read back the cast data we got after pairing.
 *
 * Sibling of {@link storeCastData}. It throws an error if the expected data is
 * not present in localStorage.
 */
export const readCastData = (): CastData => {
    const collectionKey = ensureString(localStorage.getItem("collectionKey"));
    const castToken = ensureString(localStorage.getItem("castToken"));
    return { collectionKey, castToken };
};

type RenderableImageURLPair = [url: string, nextURL: string];

/**
 * An async generator function that loops through all the files in the
 * collection, returning renderable URLs to each that can be displayed in a
 * slideshow.
 *
 * Each time it resolves with a pair of URLs (a {@link RenderableImageURLPair}),
 * one for the current slideshow image, and one for the slideshow image that
 * will be displayed next.
 *
 * If there are no renderable image in the collection, the sequence ends by
 * yielding `{done: true}`.
 *
 * Once it reaches the end of the collection, it starts from the beginning
 * again. So the sequence will continue indefinitely for non-empty collections.
 *
 * It ignores errors in the fetching and decoding of individual images in the
 * collection, and just moves onward to the next one. It will however throw if
 * there are errors when getting the collection itself.
 *
 * @param castData The collection to show and credentials to fetch the files
 * within it.
 */
export const renderableImageURLs = async function* (castData: CastData) {
    const { collectionKey, castToken } = castData;
    let previousURL: string | undefined;
    while (true) {
        const collection = await getCollection(castToken, collectionKey);
        await syncPublicFiles(castToken, collection, () => {});
        const allFiles = await getLocalFiles(String(collection.id));
        const files = allFiles.filter((file) => isFileEligibleForCast(file));

        if (!files.length) return;

        for (const file of files) {
            if (!previousURL) {
                previousURL = await createRenderableURL(castToken, file);
                continue;
            }

            const url = await createRenderableURL(castToken, file);
            const urls: RenderableImageURLPair = [previousURL, url];
            previousURL = url;
            yield urls;
        }
    }
};

const getLastSyncKey = (collectionUID: string) => `${collectionUID}-time`;

export const getLocalFiles = async (
    collectionUID: string,
): Promise<EnteFile[]> => {
    const localSavedcollectionFiles =
        (await localForage.getItem<SavedCollectionFiles[]>(
            COLLECTION_FILES_TABLE,
        )) || [];
    const matchedCollection = localSavedcollectionFiles.find(
        (item) => item.collectionLocalID === collectionUID,
    );
    return matchedCollection?.files || [];
};

const savecollectionFiles = async (
    collectionUID: string,
    files: EnteFile[],
) => {
    const collectionFiles =
        (await localForage.getItem<SavedCollectionFiles[]>(
            COLLECTION_FILES_TABLE,
        )) || [];
    await localForage.setItem(
        COLLECTION_FILES_TABLE,
        dedupeCollectionFiles([
            { collectionLocalID: collectionUID, files },
            ...collectionFiles,
        ]),
    );
};

export const getLocalCollections = async (collectionKey: string) => {
    const localCollections =
        (await localForage.getItem<Collection[]>(COLLECTIONS_TABLE)) || [];
    const collection =
        localCollections.find(
            (localSavedPublicCollection) =>
                localSavedPublicCollection.key === collectionKey,
        ) || null;
    return collection;
};

const saveCollection = async (collection: Collection) => {
    const collections =
        (await localForage.getItem<Collection[]>(COLLECTIONS_TABLE)) ?? [];
    await localForage.setItem(
        COLLECTIONS_TABLE,
        dedupeCollections([collection, ...collections]),
    );
};

const dedupeCollections = (collections: Collection[]) => {
    const keySet = new Set([]);
    return collections.filter((collection) => {
        if (!keySet.has(collection.key)) {
            keySet.add(collection.key);
            return true;
        } else {
            return false;
        }
    });
};

const dedupeCollectionFiles = (collectionFiles: SavedCollectionFiles[]) => {
    const keySet = new Set([]);
    return collectionFiles.filter(({ collectionLocalID: collectionUID }) => {
        if (!keySet.has(collectionUID)) {
            keySet.add(collectionUID);
            return true;
        } else {
            return false;
        }
    });
};

async function getSyncTime(collectionUID: string): Promise<number> {
    const lastSyncKey = getLastSyncKey(collectionUID);
    const lastSyncTime = await localForage.getItem<number>(lastSyncKey);
    return lastSyncTime ?? 0;
}

const updateSyncTime = async (collectionUID: string, time: number) =>
    await localForage.setItem(getLastSyncKey(collectionUID), time);

const syncPublicFiles = async (
    castToken: string,
    collection: Collection,
    setPublicFiles: (files: EnteFile[]) => void,
) => {
    try {
        let files: EnteFile[] = [];
        const sortAsc = collection?.pubMagicMetadata?.data.asc ?? false;
        const collectionUID = String(collection.id);
        const localFiles = await getLocalFiles(collectionUID);
        files = [...files, ...localFiles];
        try {
            const lastSyncTime = await getSyncTime(collectionUID);
            if (collection.updationTime === lastSyncTime) {
                return sortFiles(files, sortAsc);
            }
            const fetchedFiles = await fetchFiles(
                castToken,
                collection,
                lastSyncTime,
                files,
                setPublicFiles,
            );

            files = [...files, ...fetchedFiles];
            const latestVersionFiles = new Map<string, EnteFile>();
            files.forEach((file) => {
                const uid = `${file.collectionID}-${file.id}`;
                if (
                    !latestVersionFiles.has(uid) ||
                    latestVersionFiles.get(uid).updationTime < file.updationTime
                ) {
                    latestVersionFiles.set(uid, file);
                }
            });
            files = [];
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            for (const [_, file] of latestVersionFiles) {
                if (file.isDeleted) {
                    continue;
                }
                files.push(file);
            }
            await savecollectionFiles(collectionUID, files);
            await updateSyncTime(collectionUID, collection.updationTime);
            setPublicFiles([...sortFiles(mergeMetadata(files), sortAsc)]);
        } catch (e) {
            const parsedError = parseSharingErrorCodes(e);
            log.error("failed to sync shared collection files", e);
            if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                throw e;
            }
        }
        return [...sortFiles(mergeMetadata(files), sortAsc)];
    } catch (e) {
        log.error("failed to get local  or sync shared collection files", e);
        throw e;
    }
};

const fetchFiles = async (
    castToken: string,
    collection: Collection,
    sinceTime: number,
    files: EnteFile[],
    setPublicFiles: (files: EnteFile[]) => void,
): Promise<EnteFile[]> => {
    try {
        let decryptedFiles: EnteFile[] = [];
        let time = sinceTime;
        let resp;
        const sortAsc = collection?.pubMagicMetadata?.data.asc ?? false;
        do {
            if (!castToken) {
                break;
            }
            resp = await HTTPService.get(
                `${ENDPOINT}/cast/diff`,
                {
                    sinceTime: time,
                },
                {
                    "Cache-Control": "no-cache",
                    "X-Cast-Access-Token": castToken,
                },
            );
            decryptedFiles = [
                ...decryptedFiles,
                ...(await Promise.all(
                    resp.data.diff.map(async (file: EncryptedEnteFile) => {
                        if (!file.isDeleted) {
                            return await decryptFile(file, collection.key);
                        } else {
                            return file;
                        }
                    }) as Promise<EnteFile>[],
                )),
            ];

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
            setPublicFiles(
                sortFiles(
                    mergeMetadata(
                        [...(files || []), ...decryptedFiles].filter(
                            (item) => !item.isDeleted,
                        ),
                    ),
                    sortAsc,
                ),
            );
        } while (resp.data.hasMore);
        return decryptedFiles;
    } catch (e) {
        log.error("Get cast files failed", e);
        throw e;
    }
};

const getCollection = async (
    castToken: string,
    collectionKey: string,
): Promise<Collection> => {
    try {
        const resp = await HTTPService.get(`${ENDPOINT}/cast/info`, null, {
            "Cache-Control": "no-cache",
            "X-Cast-Access-Token": castToken,
        });
        const fetchedCollection = resp.data.collection;

        const cryptoWorker = await ComlinkCryptoWorker.getInstance();

        const collectionName = (fetchedCollection.name =
            fetchedCollection.name ||
            (await cryptoWorker.decryptToUTF8(
                fetchedCollection.encryptedName,
                fetchedCollection.nameDecryptionNonce,
                collectionKey,
            )));

        let collectionPublicMagicMetadata: CollectionPublicMagicMetadata;
        if (fetchedCollection.pubMagicMetadata?.data) {
            collectionPublicMagicMetadata = {
                ...fetchedCollection.pubMagicMetadata,
                data: await cryptoWorker.decryptMetadata(
                    fetchedCollection.pubMagicMetadata.data,
                    fetchedCollection.pubMagicMetadata.header,
                    collectionKey,
                ),
            };
        }

        const collection = {
            ...fetchedCollection,
            name: collectionName,
            key: collectionKey,
            pubMagicMetadata: collectionPublicMagicMetadata,
        };
        await saveCollection(collection);
        return collection;
    } catch (e) {
        log.error("failed to get cast collection", e);
        throw e;
    }
};

export function sortFiles(files: EnteFile[], sortAsc = false) {
    // sort based on the time of creation time of the file,
    // for files with same creation time, sort based on the time of last modification
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
}

export async function decryptFile(
    file: EncryptedEnteFile,
    collectionKey: string,
): Promise<EnteFile> {
    try {
        const worker = await ComlinkCryptoWorker.getInstance();
        const {
            encryptedKey,
            keyDecryptionNonce,
            metadata,
            magicMetadata,
            pubMagicMetadata,
            ...restFileProps
        } = file;
        const fileKey = await worker.decryptB64(
            encryptedKey,
            keyDecryptionNonce,
            collectionKey,
        );
        const fileMetadata = await worker.decryptMetadata(
            metadata.encryptedData,
            metadata.decryptionHeader,
            fileKey,
        );
        let fileMagicMetadata: FileMagicMetadata;
        let filePubMagicMetadata: FilePublicMagicMetadata;
        if (magicMetadata?.data) {
            fileMagicMetadata = {
                ...file.magicMetadata,
                data: await worker.decryptMetadata(
                    magicMetadata.data,
                    magicMetadata.header,
                    fileKey,
                ),
            };
        }
        if (pubMagicMetadata?.data) {
            filePubMagicMetadata = {
                ...pubMagicMetadata,
                data: await worker.decryptMetadata(
                    pubMagicMetadata.data,
                    pubMagicMetadata.header,
                    fileKey,
                ),
            };
        }
        return {
            ...restFileProps,
            key: fileKey,
            metadata: fileMetadata,
            magicMetadata: fileMagicMetadata,
            pubMagicMetadata: filePubMagicMetadata,
        };
    } catch (e) {
        log.error("file decryption failed", e);
        throw e;
    }
}

export function mergeMetadata(files: EnteFile[]): EnteFile[] {
    return files.map((file) => {
        if (file.pubMagicMetadata?.data.editedTime) {
            file.metadata.creationTime = file.pubMagicMetadata.data.editedTime;
        }
        if (file.pubMagicMetadata?.data.editedName) {
            file.metadata.title = file.pubMagicMetadata.data.editedName;
        }

        return file;
    });
}

/**
 * Create and return a new data URL that can be used to show the given
 * {@link file} in our slideshow image viewer.
 *
 * Once we're done showing the file, the URL should be revoked using
 * {@link URL.revokeObjectURL} to free up browser resources.
 */
export const createRenderableURL = async (castToken: string, file: EnteFile) =>
    URL.createObjectURL(await getPreviewableImage(castToken, file));

export const getPreviewableImage = async (
    castToken: string,
    file: EnteFile,
): Promise<Blob> => {
    try {
        let fileBlob = await downloadFile(castToken, file);
        if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
            const { imageData } = await decodeLivePhoto(
                file.metadata.title,
                fileBlob,
            );
            fileBlob = new Blob([imageData]);
        }
        const mimeType = await detectMediaMIMEType(
            new File([fileBlob], file.metadata.title),
        );
        if (!mimeType) return undefined;
        fileBlob = new Blob([fileBlob], { type: mimeType });
        return fileBlob;
    } catch (e) {
        log.error("failed to download file", e);
    }
};

export const isFileEligibleForCast = (file: EnteFile) => {
    if (!isImageOrLivePhoto(file)) return false;
    if (file.info.fileSize > 100 * 1024 * 1024) return false;

    const [, extension] = nameAndExtension(file.metadata.title);
    if (isNonWebImageFileExtension(extension)) return false;

    return true;
};

const isImageOrLivePhoto = (file: EnteFile) => {
    const fileType = file.metadata.fileType;
    return fileType == FILE_TYPE.IMAGE || fileType == FILE_TYPE.LIVE_PHOTO;
};

const downloadFile = async (castToken: string, file: EnteFile) => {
    if (!isImageOrLivePhoto(file))
        throw new Error("Can only cast images and live photos");

    const url = getCastFileURL(file.id);
    const resp = await HTTPService.get(
        url,
        null,
        {
            "X-Cast-Access-Token": castToken,
        },
        { responseType: "arraybuffer" },
    );
    if (resp.data === undefined) throw new Error(`Failed to get ${url}`);

    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const decrypted = await cryptoWorker.decryptFile(
        new Uint8Array(resp.data),
        await cryptoWorker.fromB64(file.file.decryptionHeader),
        file.key,
    );
    return new Response(decrypted).blob();
};
