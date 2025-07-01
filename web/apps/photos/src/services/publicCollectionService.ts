import { sharedCryptoWorker } from "ente-base/crypto";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { sortFiles } from "ente-gallery/utils/file";
import type {
    Collection,
    CollectionPublicMagicMetadataData,
} from "ente-media/collection";
import type { EnteFile, RemoteEnteFile } from "ente-media/file";
import { decryptRemoteFile } from "ente-media/file";
import {
    savedPublicCollectionFiles,
    savedPublicCollections,
    savePublicCollectionFiles,
} from "ente-new/albums/services/public-albums-fdb";
import { CustomError, parseSharingErrorCodes } from "ente-shared/error";
import HTTPService from "ente-shared/network/HTTPService";
import localForage from "ente-shared/storage/localForage";

const PUBLIC_COLLECTION_FILES_TABLE = "public-collection-files";
const PUBLIC_COLLECTIONS_TABLE = "public-collections";
const PUBLIC_REFERRAL_CODE = "public-referral-code";

// Fix this once we can trust the types.
// eslint-disable-next-line @typescript-eslint/no-unnecessary-template-expression
export const getPublicCollectionUID = (token: string) => `${token}`;

const getPublicCollectionLastSyncTimeKey = (collectionUID: string) =>
    `public-${collectionUID}-time`;

const getPublicCollectionPasswordKey = (collectionUID: string) =>
    `public-${collectionUID}-passkey`;

const getPublicCollectionUploaderNameKey = (collectionUID: string) =>
    `public-${collectionUID}-uploaderName`;

export const getPublicCollectionUploaderName = async (collectionUID: string) =>
    await localForage.getItem<string>(
        getPublicCollectionUploaderNameKey(collectionUID),
    );

export const savePublicCollectionUploaderName = async (
    collectionUID: string,
    uploaderName: string,
) =>
    await localForage.setItem(
        getPublicCollectionUploaderNameKey(collectionUID),
        uploaderName,
    );

export interface LocalSavedPublicCollectionFiles {
    collectionUID: string;
    files: EnteFile[];
}

export const getLocalPublicCollectionPassword = async (
    collectionUID: string,
): Promise<string> => {
    return (
        (await localForage.getItem<string>(
            getPublicCollectionPasswordKey(collectionUID),
        )) || ""
    );
};

export const savePublicCollectionPassword = async (
    collectionUID: string,
    passToken: string,
): Promise<string> => {
    return await localForage.setItem<string>(
        getPublicCollectionPasswordKey(collectionUID),
        passToken,
    );
};

export const getLocalPublicCollection = async (collectionKey: string) => {
    const localCollections = await savedPublicCollections();
    const publicCollection =
        localCollections.find(
            (localSavedPublicCollection) =>
                localSavedPublicCollection.key === collectionKey,
        ) || null;
    return publicCollection;
};

export const savePublicCollection = async (collection: Collection) => {
    const publicCollections = await savedPublicCollections();
    await localForage.setItem(
        PUBLIC_COLLECTIONS_TABLE,
        dedupeCollections([collection, ...publicCollections]),
    );
};

export const getReferralCode = async () => {
    return await localForage.getItem<string>(PUBLIC_REFERRAL_CODE);
};

export const saveReferralCode = async (code: string) => {
    if (!code) {
        localForage.removeItem(PUBLIC_REFERRAL_CODE);
    }
    await localForage.setItem(PUBLIC_REFERRAL_CODE, code);
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

const getPublicCollectionLastSyncTime = async (collectionUID: string) =>
    (await localForage.getItem<number>(
        getPublicCollectionLastSyncTimeKey(collectionUID),
    )) ?? 0;

const savePublicCollectionLastSyncTime = async (
    collectionUID: string,
    time: number,
) =>
    await localForage.setItem(
        getPublicCollectionLastSyncTimeKey(collectionUID),
        time,
    );

export const syncPublicFiles = async (
    token: string,
    passwordToken: string,
    collection: Collection,
    setPublicFiles: (files: EnteFile[]) => void,
) => {
    try {
        let files: EnteFile[] = [];
        const sortAsc = collection?.pubMagicMetadata?.data.asc ?? false;
        const collectionUID = getPublicCollectionUID(token);
        const localFiles = await savedPublicCollectionFiles(collectionUID);

        files = [...files, ...localFiles];
        try {
            if (!token) {
                return sortFiles(files, sortAsc);
            }
            const lastSyncTime =
                await getPublicCollectionLastSyncTime(collectionUID);
            if (collection.updationTime === lastSyncTime) {
                return sortFiles(files, sortAsc);
            }
            const fetchedFiles = await getPublicFiles(
                token,
                passwordToken,
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
                // TODO(RE):
                if ("isDeleted" in file && file.isDeleted) {
                    continue;
                }
                files.push(file);
            }
            await savePublicCollectionFiles(collectionUID, files);
            await savePublicCollectionLastSyncTime(
                collectionUID,
                collection.updationTime,
            );
            setPublicFiles([...sortFiles(files, sortAsc)]);
        } catch (e) {
            const parsedError = parseSharingErrorCodes(e);
            log.error("failed to sync shared collection files", e);
            if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                throw e;
            }
        }
        return [...sortFiles(files, sortAsc)];
    } catch (e) {
        log.error("failed to get local  or sync shared collection files", e);
        throw e;
    }
};

const getPublicFiles = async (
    token: string,
    passwordToken: string,
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
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                await apiURL("/public-collection/diff"),
                { sinceTime: time },
                {
                    "X-Auth-Access-Token": token,
                    ...(passwordToken && {
                        "X-Auth-Access-Token-JWT": passwordToken,
                    }),
                },
            );
            decryptedFiles = [
                ...decryptedFiles,
                ...(await Promise.all(
                    resp.data.diff.map(async (file: RemoteEnteFile) => {
                        if (!file.isDeleted) {
                            return await decryptRemoteFile(
                                file,
                                collection.key,
                            );
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
                    [...(files || []), ...decryptedFiles].filter(
                        // TODO(RE):
                        // (item) => !item.isDeleted,
                        (file) => !("isDeleted" in file && file.isDeleted),
                    ),
                    sortAsc,
                ),
            );
        } while (resp.data.hasMore);
        return decryptedFiles;
    } catch (e) {
        log.error("Get public  files failed", e);
        throw e;
    }
};

export interface MagicMetadataCore<T> {
    version: number;
    count: number;
    header: string;
    data: T;
}

export const getPublicCollection = async (
    token: string,
    collectionKey: string,
): Promise<[Collection, string]> => {
    try {
        if (!token) {
            return;
        }
        const resp = await HTTPService.get(
            await apiURL("/public-collection/info"),
            null,
            { "X-Auth-Access-Token": token },
        );
        const fetchedCollection = resp.data.collection;
        const referralCode = resp.data.referralCode ?? "";

        const cryptoWorker = await sharedCryptoWorker();

        const collectionName = (fetchedCollection.name =
            fetchedCollection.name ||
            new TextDecoder().decode(
                await cryptoWorker.decryptBoxBytes(
                    {
                        encryptedData: fetchedCollection.encryptedName,
                        nonce: fetchedCollection.nameDecryptionNonce,
                    },
                    collectionKey,
                ),
            ));

        let collectionPublicMagicMetadata: MagicMetadataCore<CollectionPublicMagicMetadataData>;
        if (fetchedCollection.pubMagicMetadata?.data) {
            collectionPublicMagicMetadata = {
                ...fetchedCollection.pubMagicMetadata,
                data: await cryptoWorker.decryptMetadataJSON(
                    {
                        encryptedData: fetchedCollection.pubMagicMetadata.data,
                        decryptionHeader:
                            fetchedCollection.pubMagicMetadata.header,
                    },
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
        await savePublicCollection(collection);
        await saveReferralCode(referralCode);
        return [collection, referralCode];
    } catch (e) {
        log.error("failed to get public collection", e);
        throw e;
    }
};

export const removePublicCollectionWithFiles = async (
    collectionUID: string,
    collectionKey: string,
) => {
    const publicCollections = await savedPublicCollections();
    await localForage.setItem(
        PUBLIC_COLLECTIONS_TABLE,
        publicCollections.filter(
            (collection) => collection.key !== collectionKey,
        ),
    );
    await removePublicFiles(collectionUID);
};

export const removePublicFiles = async (collectionUID: string) => {
    await localForage.removeItem(getPublicCollectionPasswordKey(collectionUID));
    await localForage.removeItem(
        getPublicCollectionLastSyncTimeKey(collectionUID),
    );

    const publicCollectionFiles =
        (await localForage.getItem<LocalSavedPublicCollectionFiles[]>(
            PUBLIC_COLLECTION_FILES_TABLE,
        )) ?? [];
    await localForage.setItem(
        PUBLIC_COLLECTION_FILES_TABLE,
        publicCollectionFiles.filter(
            (collectionFiles) =>
                collectionFiles.collectionUID !== collectionUID,
        ),
    );
};
