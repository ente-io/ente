import { ensureElectron } from "@/base/electron";
import log from "@/base/log";
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
    findDefaultHiddenCollectionIDs,
    isHiddenCollection,
    isIncomingShare,
} from "@/new/photos/services/collection";
import { getAllLocalFiles, getLocalFiles } from "@/new/photos/services/files";
import { updateMagicMetadata } from "@/new/photos/services/magic-metadata";
import { safeDirectoryName } from "@/new/photos/utils/native-fs";
import { CustomError } from "@ente/shared/error";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { getUnixTimeInMicroSecondsWithDelta } from "@ente/shared/time";
import type { User } from "@ente/shared/user/types";
import bs58 from "bs58";
import { t } from "i18next";
import {
    addToCollection,
    createAlbum,
    getAllLocalCollections,
    getLocalCollections,
    moveToCollection,
    removeFromCollection,
    restoreToCollection,
    unhideToCollection,
    updateCollectionMagicMetadata,
    updatePublicCollectionMagicMetadata,
    updateSharedCollectionMagicMetadata,
} from "services/collectionService";
import { SetFilesDownloadProgressAttributes } from "types/gallery";
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
            throw Error(CustomError.INVALID_COLLECTION_OPERATION);
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
    setFilesDownloadProgressAttributes: SetFilesDownloadProgressAttributes,
) {
    try {
        const hiddenCollections = await getLocalCollections("hidden");
        const defaultHiddenCollectionsIds =
            findDefaultHiddenCollectionIDs(hiddenCollections);
        const hiddenFiles = await getLocalFiles("hidden");
        const defaultHiddenCollectionFiles = hiddenFiles.filter((file) =>
            defaultHiddenCollectionsIds.has(file.collectionID),
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
    const collectionDownloadPath = `${downloadDirPath}/${collectionDownloadName}`;
    await fs.mkdirIfNeeded(collectionDownloadPath);
    return collectionDownloadPath;
}

export function appendCollectionKeyToShareURL(
    url: string,
    collectionKey: string,
) {
    if (!url) {
        return null;
    }

    const sharableURL = new URL(url);

    const bytes = Buffer.from(collectionKey, "base64");
    sharableURL.hash = bs58.encode(bytes);
    return sharableURL.href;
}

const _intSelectOption = (i: number) => {
    const label = i === 0 ? t("NO_DEVICE_LIMIT") : i.toString();
    return { label, value: i };
};

export function getDeviceLimitOptions() {
    return [0, 2, 5, 10, 25, 50].map((i) => _intSelectOption(i));
}

export const shareExpiryOptions = () => [
    { label: t("NEVER"), value: () => 0 },
    {
        label: t("AFTER_TIME.HOUR"),
        value: () => getUnixTimeInMicroSecondsWithDelta({ hours: 1 }),
    },
    {
        label: t("AFTER_TIME.DAY"),
        value: () => getUnixTimeInMicroSecondsWithDelta({ days: 1 }),
    },
    {
        label: t("AFTER_TIME.WEEK"),
        value: () => getUnixTimeInMicroSecondsWithDelta({ days: 7 }),
    },
    {
        label: t("AFTER_TIME.MONTH"),
        value: () => getUnixTimeInMicroSecondsWithDelta({ months: 1 }),
    },
    {
        label: t("AFTER_TIME.YEAR"),
        value: () => getUnixTimeInMicroSecondsWithDelta({ years: 1 }),
    },
];

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
            {
                asc,
            };

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

export function getCollectionNameMap(
    collections: Collection[],
): Map<number, string> {
    return new Map<number, string>(
        collections.map((collection) => [collection.id, collection.name]),
    );
}

export function getNonHiddenCollections(
    collections: Collection[],
): Collection[] {
    return collections.filter((collection) => !isHiddenCollection(collection));
}

export function getHiddenCollections(collections: Collection[]): Collection[] {
    return collections.filter((collection) => isHiddenCollection(collection));
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
