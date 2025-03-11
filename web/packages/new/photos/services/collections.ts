/* eslint-disable @typescript-eslint/no-unsafe-call */
// TODO: Audit this file
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
/* eslint-disable @typescript-eslint/prefer-nullish-coalescing */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { sharedCryptoWorker } from "@/base/crypto";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import {
    type Collection,
    type CollectionMagicMetadata,
    type CollectionPublicMagicMetadata,
    type CollectionShareeMagicMetadata,
    type EncryptedCollection,
} from "@/media/collection";
import {
    decryptFile,
    type EncryptedTrashItem,
    type EnteFile,
    type Trash,
} from "@/media/file";
import {
    getLocalTrash,
    getTrashedFiles,
    TRASH,
} from "@/new/photos/services/files";
import HTTPService from "@ente/shared/network/HTTPService";
import localForage from "@ente/shared/storage/localForage";
import { getData, LS_KEYS } from "@ente/shared/storage/localStorage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { getActualKey } from "@ente/shared/user";
import { isHiddenCollection } from "./collection";

const COLLECTION_TABLE = "collections";
const HIDDEN_COLLECTION_IDS = "hidden-collection-ids";
const COLLECTION_UPDATION_TIME = "collection-updation-time";

export const getLocalCollections = async (
    type: "normal" | "hidden" = "normal",
): Promise<Collection[]> => {
    const collections = await getAllLocalCollections();
    return type == "normal"
        ? collections.filter((c) => !isHiddenCollection(c))
        : collections.filter((c) => isHiddenCollection(c));
};

export const getAllLocalCollections = async (): Promise<Collection[]> => {
    const collections: Collection[] =
        (await localForage.getItem(COLLECTION_TABLE)) ?? [];
    return collections;
};

export const getCollectionLastSyncTime = async (collection: Collection) =>
    (await localForage.getItem<number>(`${collection.id}-time`)) ?? 0;

export const setCollectionLastSyncTime = async (
    collection: Collection,
    time: number,
) => await localForage.setItem<number>(`${collection.id}-time`, time);

export const removeCollectionLastSyncTime = async (collection: Collection) =>
    await localForage.removeItem(`${collection.id}-time`);

export const getHiddenCollectionIDs = async (): Promise<number[]> =>
    (await localForage.getItem<number[]>(HIDDEN_COLLECTION_IDS)) ?? [];

export const getCollectionUpdationTime = async (): Promise<number> =>
    (await localForage.getItem<number>(COLLECTION_UPDATION_TIME)) ?? 0;

export const getLatestCollections = async (
    type: "normal" | "hidden" = "normal",
): Promise<Collection[]> => {
    const collections = await getAllLatestCollections();
    return type == "normal"
        ? collections.filter((c) => !isHiddenCollection(c))
        : collections.filter((c) => isHiddenCollection(c));
};

export const getAllLatestCollections = async (): Promise<Collection[]> => {
    const collections = await syncCollections();
    return collections;
};

export const syncCollections = async () => {
    const localCollections = await getAllLocalCollections();
    let lastCollectionUpdationTime = await getCollectionUpdationTime();
    const hiddenCollectionIDs = await getHiddenCollectionIDs();
    const token = getToken();
    const key = await getActualKey();
    const updatedCollections =
        (await getCollections(token, lastCollectionUpdationTime, key)) ?? [];
    if (updatedCollections.length === 0) {
        return localCollections;
    }
    const allCollectionsInstances = [
        ...localCollections,
        ...updatedCollections,
    ];
    const latestCollectionsInstances = new Map<number, Collection>();
    allCollectionsInstances.forEach((collection) => {
        if (
            !latestCollectionsInstances.has(collection.id) ||
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            latestCollectionsInstances.get(collection.id).updationTime <
                collection.updationTime
        ) {
            latestCollectionsInstances.set(collection.id, collection);
        }
    });

    const collections: Collection[] = [];
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    for (const [_, collection] of latestCollectionsInstances) {
        const isDeletedCollection = collection.isDeleted;
        const isNewlyHiddenCollection =
            isHiddenCollection(collection) &&
            !hiddenCollectionIDs.includes(collection.id);
        const isNewlyUnHiddenCollection =
            !isHiddenCollection(collection) &&
            hiddenCollectionIDs.includes(collection.id);
        if (
            isDeletedCollection ||
            isNewlyHiddenCollection ||
            isNewlyUnHiddenCollection
        ) {
            await removeCollectionLastSyncTime(collection);
        }
        if (isDeletedCollection) {
            continue;
        }
        collections.push(collection);
        lastCollectionUpdationTime = Math.max(
            lastCollectionUpdationTime,
            collection.updationTime,
        );
    }

    const updatedHiddenCollectionIDs = collections
        .filter((collection) => isHiddenCollection(collection))
        .map((collection) => collection.id);

    await localForage.setItem(COLLECTION_TABLE, collections);
    await localForage.setItem(
        COLLECTION_UPDATION_TIME,
        lastCollectionUpdationTime,
    );
    await localForage.setItem(
        HIDDEN_COLLECTION_IDS,
        updatedHiddenCollectionIDs,
    );
    return collections;
};

const getCollections = async (
    token: string,
    sinceTime: number,
    key: string,
): Promise<Collection[]> => {
    try {
        const resp = await HTTPService.get(
            await apiURL("/collections/v2"),
            { sinceTime },
            { "X-Auth-Token": token },
        );
        const decryptedCollections: Collection[] = await Promise.all(
            resp.data.collections.map(
                async (collection: EncryptedCollection) => {
                    if (collection.isDeleted) {
                        return collection;
                    }
                    try {
                        return await getCollectionWithSecrets(collection, key);
                    } catch (e) {
                        log.error(
                            `decryption failed for collection with ID ${collection.id}`,
                            e,
                        );
                        return collection;
                    }
                },
            ),
        );
        // only allow deleted or collection with key, filtering out collection whose decryption failed
        const collections = decryptedCollections.filter(
            (collection) => collection.isDeleted || collection.key,
        );
        return collections;
    } catch (e) {
        log.error("getCollections failed", e);
        throw e;
    }
};

export const getCollectionWithSecrets = async (
    collection: EncryptedCollection,
    masterKey: string,
): Promise<Collection> => {
    const cryptoWorker = await sharedCryptoWorker();
    const userID = getData(LS_KEYS.USER).id;
    let collectionKey: string;
    if (collection.owner.id === userID) {
        collectionKey = await cryptoWorker.decryptB64(
            collection.encryptedKey,
            collection.keyDecryptionNonce,
            masterKey,
        );
    } else {
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const secretKey = await cryptoWorker.decryptB64(
            keyAttributes.encryptedSecretKey,
            keyAttributes.secretKeyDecryptionNonce,
            masterKey,
        );
        collectionKey = await cryptoWorker.boxSealOpen(
            collection.encryptedKey,
            keyAttributes.publicKey,
            secretKey,
        );
    }
    const collectionName =
        collection.name ||
        (await cryptoWorker.decryptToUTF8(
            collection.encryptedName,
            collection.nameDecryptionNonce,
            collectionKey,
        ));

    let collectionMagicMetadata: CollectionMagicMetadata;
    if (collection.magicMetadata?.data) {
        collectionMagicMetadata = {
            ...collection.magicMetadata,
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            data: await cryptoWorker.decryptMetadataJSON({
                encryptedDataB64: collection.magicMetadata.data,
                decryptionHeaderB64: collection.magicMetadata.header,
                keyB64: collectionKey,
            }),
        };
    }
    let collectionPublicMagicMetadata: CollectionPublicMagicMetadata;
    if (collection.pubMagicMetadata?.data) {
        collectionPublicMagicMetadata = {
            ...collection.pubMagicMetadata,
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            data: await cryptoWorker.decryptMetadataJSON({
                encryptedDataB64: collection.pubMagicMetadata.data,
                decryptionHeaderB64: collection.pubMagicMetadata.header,
                keyB64: collectionKey,
            }),
        };
    }

    let collectionShareeMagicMetadata: CollectionShareeMagicMetadata;
    if (collection.sharedMagicMetadata?.data) {
        collectionShareeMagicMetadata = {
            ...collection.sharedMagicMetadata,
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            data: await cryptoWorker.decryptMetadataJSON({
                encryptedDataB64: collection.sharedMagicMetadata.data,
                decryptionHeaderB64: collection.sharedMagicMetadata.header,
                keyB64: collectionKey,
            }),
        };
    }

    return {
        ...collection,
        name: collectionName,
        key: collectionKey,
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        magicMetadata: collectionMagicMetadata,
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        pubMagicMetadata: collectionPublicMagicMetadata,
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        sharedMagicMetadata: collectionShareeMagicMetadata,
    };
};

export const getCollection = async (
    collectionID: number,
): Promise<Collection> => {
    try {
        const token = getToken();
        if (!token) {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            return;
        }
        const resp = await HTTPService.get(
            await apiURL(`/collections/${collectionID}`),
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            null,
            { "X-Auth-Token": token },
        );
        const key = await getActualKey();
        const collectionWithSecrets = await getCollectionWithSecrets(
            resp.data?.collection,
            key,
        );
        return collectionWithSecrets;
    } catch (e) {
        log.error("failed to get collection", e);
        throw e;
    }
};

const TRASH_TIME = "trash-time";
const DELETED_COLLECTION = "deleted-collection";

export async function getLocalDeletedCollections() {
    const trashedCollections: Collection[] =
        (await localForage.getItem<Collection[]>(DELETED_COLLECTION)) || [];
    const nonUndefinedCollections = trashedCollections.filter(
        (collection) => !!collection,
    );
    if (nonUndefinedCollections.length !== trashedCollections.length) {
        await localForage.setItem(DELETED_COLLECTION, nonUndefinedCollections);
    }
    return nonUndefinedCollections;
}

export async function cleanTrashCollections(fileTrash: Trash) {
    const trashedCollections = await getLocalDeletedCollections();
    const neededTrashCollections = new Set<number>(
        fileTrash.map((item) => item.file.collectionID),
    );
    const filterCollections = trashedCollections.filter((item) =>
        neededTrashCollections.has(item.id),
    );
    await localForage.setItem(DELETED_COLLECTION, filterCollections);
}

async function getLastTrashSyncTime() {
    return (await localForage.getItem<number>(TRASH_TIME)) ?? 0;
}
export async function syncTrash(
    collections: Collection[],
    setTrashedFiles: (fs: EnteFile[]) => void,
): Promise<void> {
    const trash = await getLocalTrash();
    collections = [...collections, ...(await getLocalDeletedCollections())];
    const collectionMap = new Map<number, Collection>(
        collections.map((collection) => [collection.id, collection]),
    );
    if (!getToken()) {
        return;
    }
    const lastSyncTime = await getLastTrashSyncTime();

    const updatedTrash = await updateTrash(
        collectionMap,
        lastSyncTime,
        setTrashedFiles,
        trash,
    );
    await cleanTrashCollections(updatedTrash);
}

export const updateTrash = async (
    collections: Map<number, Collection>,
    sinceTime: number,
    setTrashedFiles: (fs: EnteFile[]) => void,
    currentTrash: Trash,
): Promise<Trash> => {
    try {
        let updatedTrash: Trash = [...currentTrash];
        let time = sinceTime;

        let resp;
        do {
            const token = getToken();
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                await apiURL("/trash/v2/diff"),
                { sinceTime: time },
                { "X-Auth-Token": token },
            );
            // #Perf: This can be optimized by running the decryption in parallel
            for (const trashItem of resp.data.diff as EncryptedTrashItem[]) {
                const collectionID = trashItem.file.collectionID;
                let collection = collections.get(collectionID);
                if (!collection) {
                    collection = await getCollection(collectionID);
                    collections.set(collectionID, collection);
                    await localForage.setItem(DELETED_COLLECTION, [
                        ...collections.values(),
                    ]);
                }
                if (!trashItem.isDeleted && !trashItem.isRestored) {
                    const decryptedFile = await decryptFile(
                        trashItem.file,
                        collection.key,
                    );
                    updatedTrash.push({ ...trashItem, file: decryptedFile });
                } else {
                    updatedTrash = updatedTrash.filter(
                        (item) => item.file.id !== trashItem.file.id,
                    );
                }
            }

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updatedAt;
            }

            setTrashedFiles(getTrashedFiles(updatedTrash));
            await localForage.setItem(TRASH, updatedTrash);
            await localForage.setItem(TRASH_TIME, time);
        } while (resp.data.hasMore);
        return updatedTrash;
    } catch (e) {
        log.error("Get trash files failed", e);
    }
    return currentTrash;
};

export const emptyTrash = async () => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        const lastUpdatedAt = await getLastTrashSyncTime();

        await HTTPService.post(
            await apiURL("/trash/empty"),
            { lastUpdatedAt },
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            null,
            { "X-Auth-Token": token },
        );
    } catch (e) {
        log.error("empty trash failed", e);
        throw e;
    }
};

export const clearLocalTrash = async () => {
    await localForage.setItem(TRASH, []);
};
