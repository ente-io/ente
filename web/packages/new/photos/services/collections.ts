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
import HTTPService from "@ente/shared/network/HTTPService";
import localForage from "@ente/shared/storage/localForage";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
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
            // @ts-expect-error TODO fixme
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
            {
                sinceTime,
            },
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
            // @ts-expect-error TODO fixme
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
            // @ts-expect-error TODO fixme
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
            // @ts-expect-error TODO fixme
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
        // @ts-expect-error TODO fixme
        magicMetadata: collectionMagicMetadata,
        // @ts-expect-error TODO fixme
        pubMagicMetadata: collectionPublicMagicMetadata,
        // @ts-expect-error TODO fixme
        sharedMagicMetadata: collectionShareeMagicMetadata,
    };
};

export const getCollection = async (
    collectionID: number,
): Promise<Collection> => {
    try {
        const token = getToken();
        if (!token) {
            // @ts-expect-error TODO fixme
            return;
        }
        const resp = await HTTPService.get(
            await apiURL(`/collections/${collectionID}`),
            // @ts-expect-error TODO fixme
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
