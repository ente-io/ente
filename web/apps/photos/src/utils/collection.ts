import { ensureElectron } from "@/base/electron";
import { joinPath } from "@/base/file-name";
import log from "@/base/log";
import { updateMagicMetadata } from "@/gallery/services/magic-metadata";
import {
    COLLECTION_ROLE,
    type Collection,
    CollectionMagicMetadataProps,
    CollectionPublicMagicMetadataProps,
    CollectionType,
    SUB_TYPE,
} from "@/media/collection";
import { EnteFile } from "@/media/file";
import { ItemVisibility } from "@/media/file-metadata";
import {
    DEFAULT_HIDDEN_COLLECTION_USER_FACING_NAME,
    HIDDEN_ITEMS_SECTION,
    addToCollection,
    findDefaultHiddenCollectionIDs,
    isHiddenCollection,
    isIncomingShare,
    moveToCollection,
    restoreToCollection,
} from "@/new/photos/services/collection";
import {
    getAllLocalCollections,
    getLocalCollections,
} from "@/new/photos/services/collections";
import { getAllLocalFiles, getLocalFiles } from "@/new/photos/services/files";
import { safeDirectoryName } from "@/new/photos/utils/native-fs";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";
import { t } from "i18next";
import {
    createAlbum,
    removeFromCollection,
    unhideToCollection,
    updateCollectionMagicMetadata,
    updatePublicCollectionMagicMetadata,
    updateSharedCollectionMagicMetadata,
} from "services/collectionService";
import {
    SetFilesDownloadProgressAttributes,
    type SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import { downloadFilesWithProgress } from "utils/file";

export enum COLLECTION_OPS_TYPE {
    ADD,
    MOVE,
    REMOVE,
    RESTORE,
    UNHIDE,
}
export async function handleCollectionOps(
    type: COLLECTION_OPS_TYPE,
    collection: Collection,
    selectedFiles: EnteFile[],
    selectedCollectionID: number,
) {
    switch (type) {
        case COLLECTION_OPS_TYPE.ADD:
            await addToCollection(collection, selectedFiles);
            break;
        case COLLECTION_OPS_TYPE.MOVE:
            await moveToCollection(
                selectedCollectionID,
                collection,
                selectedFiles,
            );
            break;
        case COLLECTION_OPS_TYPE.REMOVE:
            await removeFromCollection(collection.id, selectedFiles);
            break;
        case COLLECTION_OPS_TYPE.RESTORE:
            await restoreToCollection(collection, selectedFiles);
            break;
        case COLLECTION_OPS_TYPE.UNHIDE:
            await unhideToCollection(collection, selectedFiles);
            break;
        default:
            throw Error("Invalid collection operation");
    }
}

export function getSelectedCollection(
    collectionID: number,
    collections: Collection[],
) {
    return collections.find((collection) => collection.id === collectionID);
}

export async function downloadCollectionHelper(
    collectionID: number,
    setFilesDownloadProgressAttributes: SetFilesDownloadProgressAttributes,
) {
    try {
        const allFiles = await getAllLocalFiles();
        const collectionFiles = allFiles.filter(
            (file) => file.collectionID === collectionID,
        );
        const allCollections = await getAllLocalCollections();
        const collection = allCollections.find(
            (collection) => collection.id === collectionID,
        );
        if (!collection) {
            throw Error("collection not found");
        }
        await downloadCollectionFiles(
            collection.name,
            collectionFiles,
            setFilesDownloadProgressAttributes,
        );
    } catch (e) {
        log.error("download collection failed ", e);
    }
}

export async function downloadDefaultHiddenCollectionHelper(
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator,
) {
    try {
        const hiddenCollections = await getLocalCollections("hidden");
        const defaultHiddenCollectionsIds =
            findDefaultHiddenCollectionIDs(hiddenCollections);
        const hiddenFiles = await getLocalFiles("hidden");
        const defaultHiddenCollectionFiles = hiddenFiles.filter((file) =>
            defaultHiddenCollectionsIds.has(file.collectionID),
        );
        const setFilesDownloadProgressAttributes =
            setFilesDownloadProgressAttributesCreator(
                DEFAULT_HIDDEN_COLLECTION_USER_FACING_NAME,
                HIDDEN_ITEMS_SECTION,
                true,
            );

        await downloadCollectionFiles(
            DEFAULT_HIDDEN_COLLECTION_USER_FACING_NAME,
            defaultHiddenCollectionFiles,
            setFilesDownloadProgressAttributes,
        );
    } catch (e) {
        log.error("download hidden files failed ", e);
    }
}

export async function downloadCollectionFiles(
    collectionName: string,
    collectionFiles: EnteFile[],
    setFilesDownloadProgressAttributes: SetFilesDownloadProgressAttributes,
) {
    if (!collectionFiles.length) {
        return;
    }
    let downloadDirPath: string;
    const electron = globalThis.electron;
    if (electron) {
        const selectedDir = await electron.selectDirectory();
        if (!selectedDir) {
            return;
        }
        downloadDirPath = await createCollectionDownloadFolder(
            selectedDir,
            collectionName,
        );
    }
    await downloadFilesWithProgress(
        collectionFiles,
        downloadDirPath,
        setFilesDownloadProgressAttributes,
    );
}

async function createCollectionDownloadFolder(
    downloadDirPath: string,
    collectionName: string,
) {
    const fs = ensureElectron().fs;
    const collectionDownloadName = await safeDirectoryName(
        downloadDirPath,
        collectionName,
        fs.exists,
    );
    const collectionDownloadPath = joinPath(
        downloadDirPath,
        collectionDownloadName,
    );
    await fs.mkdirIfNeeded(collectionDownloadPath);
    return collectionDownloadPath;
}

const _intSelectOption = (i: number) => {
    const label = i === 0 ? t("none") : i.toString();
    return { label, value: i };
};

export function getDeviceLimitOptions() {
    return [0, 2, 5, 10, 25, 50].map((i) => _intSelectOption(i));
}

export const changeCollectionVisibility = async (
    collection: Collection,
    visibility: ItemVisibility,
) => {
    try {
        const updatedMagicMetadataProps: CollectionMagicMetadataProps = {
            visibility,
        };

        const user: User = getData(LS_KEYS.USER);
        if (collection.owner.id === user.id) {
            const updatedMagicMetadata = await updateMagicMetadata(
                updatedMagicMetadataProps,
                collection.magicMetadata,
                collection.key,
            );

            await updateCollectionMagicMetadata(
                collection,
                updatedMagicMetadata,
            );
        } else {
            const updatedMagicMetadata = await updateMagicMetadata(
                updatedMagicMetadataProps,
                collection.sharedMagicMetadata,
                collection.key,
            );
            await updateSharedCollectionMagicMetadata(
                collection,
                updatedMagicMetadata,
            );
        }
    } catch (e) {
        log.error("change collection visibility failed", e);
        throw e;
    }
};

export const changeCollectionSortOrder = async (
    collection: Collection,
    asc: boolean,
) => {
    try {
        const updatedPublicMagicMetadataProps: CollectionPublicMagicMetadataProps =
            { asc };

        const updatedPubMagicMetadata = await updateMagicMetadata(
            updatedPublicMagicMetadataProps,
            collection.pubMagicMetadata,
            collection.key,
        );

        await updatePublicCollectionMagicMetadata(
            collection,
            updatedPubMagicMetadata,
        );
    } catch (e) {
        log.error("change collection sort order failed", e);
    }
};

export const changeCollectionOrder = async (
    collection: Collection,
    order: number,
) => {
    try {
        const updatedMagicMetadataProps: CollectionMagicMetadataProps = {
            order,
        };

        const updatedMagicMetadata = await updateMagicMetadata(
            updatedMagicMetadataProps,
            collection.magicMetadata,
            collection.key,
        );

        await updateCollectionMagicMetadata(collection, updatedMagicMetadata);
    } catch (e) {
        log.error("change collection order failed", e);
    }
};

export const changeCollectionSubType = async (
    collection: Collection,
    subType: SUB_TYPE,
) => {
    try {
        const updatedMagicMetadataProps: CollectionMagicMetadataProps = {
            subType: subType,
        };

        const updatedMagicMetadata = await updateMagicMetadata(
            updatedMagicMetadataProps,
            collection.magicMetadata,
            collection.key,
        );
        await updateCollectionMagicMetadata(collection, updatedMagicMetadata);
    } catch (e) {
        log.error("change collection subType failed", e);
        throw e;
    }
};

export const getUserOwnedCollections = (collections: Collection[]) => {
    const user: User = getData(LS_KEYS.USER);
    if (!user?.id) {
        throw Error("user missing");
    }
    return collections.filter((collection) => collection.owner.id === user.id);
};

export const isQuickLinkCollection = (collection: Collection) =>
    collection.magicMetadata?.data.subType === SUB_TYPE.QUICK_LINK_COLLECTION;

export function isIncomingViewerShare(collection: Collection, user: User) {
    const sharee = collection.sharees?.find((sharee) => sharee.id === user.id);
    return sharee?.role === COLLECTION_ROLE.VIEWER;
}

export function isValidMoveTarget(
    sourceCollectionID: number,
    targetCollection: Collection,
    user: User,
) {
    return (
        sourceCollectionID !== targetCollection.id &&
        !isHiddenCollection(targetCollection) &&
        !isQuickLinkCollection(targetCollection) &&
        !isIncomingShare(targetCollection, user)
    );
}

export function isValidReplacementAlbum(
    collection: Collection,
    user: User,
    wantedCollectionName: string,
) {
    return (
        collection.name === wantedCollectionName &&
        (collection.type === CollectionType.album ||
            collection.type === CollectionType.folder ||
            collection.type === CollectionType.uncategorized) &&
        !isHiddenCollection(collection) &&
        !isQuickLinkCollection(collection) &&
        !isIncomingShare(collection, user)
    );
}

export const getOrCreateAlbum = async (
    albumName: string,
    existingCollections: Collection[],
) => {
    const user: User = getData(LS_KEYS.USER);
    if (!user?.id) {
        throw Error("user missing");
    }
    for (const collection of existingCollections) {
        if (isValidReplacementAlbum(collection, user, albumName)) {
            log.info(
                `Found existing album ${albumName} with id ${collection.id}`,
            );
            return collection;
        }
    }
    const album = await createAlbum(albumName);
    log.info(`Created new album ${albumName} with id ${album.id}`);
    return album;
};
