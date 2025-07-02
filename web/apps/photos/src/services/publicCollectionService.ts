import {
    removePublicCollectionAccessTokenJWT,
    removePublicCollectionByKey,
    removePublicCollectionFiles,
    removePublicCollectionLastSyncTime,
} from "ente-new/albums/services/public-albums-fdb";

// Fix this once we can trust the types.
// eslint-disable-next-line @typescript-eslint/no-unnecessary-template-expression
export const getPublicCollectionUID = (token: string) => `${token}`;

export const removePublicCollectionWithFiles = async (
    collectionUID: string,
    collectionKey: string,
) => {
    await removePublicCollectionByKey(collectionKey);
    await removePublicFiles(collectionUID);
};

export const removePublicFiles = async (collectionUID: string) => {
    await removePublicCollectionAccessTokenJWT(collectionUID);
    await removePublicCollectionLastSyncTime(collectionUID);
    await removePublicCollectionFiles(collectionUID);
};
