import type { User } from "ente-accounts/services/user";
import { ensureElectron } from "ente-base/electron";
import { joinPath } from "ente-base/file-name";
import log from "ente-base/log";
import { uniqueFilesByID } from "ente-gallery/utils/file";
import { type Collection, CollectionSubType } from "ente-media/collection";
import { EnteFile } from "ente-media/file";
import {
    createAlbum,
    defaultHiddenCollectionUserFacingName,
    findDefaultHiddenCollectionIDs,
    isHiddenCollection,
} from "ente-new/photos/services/collection";
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import {
    savedCollectionFiles,
    savedCollections,
} from "ente-new/photos/services/photos-fdb";
import { safeDirectoryName } from "ente-new/photos/utils/native-fs";
import { getData } from "ente-shared/storage/localStorage";
import {
    SetFilesDownloadProgressAttributes,
    type SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import { downloadFilesWithProgress } from "utils/file";

export async function downloadCollectionHelper(
    collectionID: number,
    setFilesDownloadProgressAttributes: SetFilesDownloadProgressAttributes,
) {
    try {
        const allFiles = await savedCollectionFiles();
        const collectionFiles = allFiles.filter(
            (file) => file.collectionID == collectionID,
        );
        const allCollections = await savedCollections();
        const collection = allCollections.find(
            (collection) => collection.id == collectionID,
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
        const defaultHiddenCollectionsIDs = findDefaultHiddenCollectionIDs(
            await savedCollections(),
        );
        const collectionFiles = await savedCollectionFiles();
        const defaultHiddenCollectionFiles = uniqueFilesByID(
            collectionFiles.filter((file) =>
                defaultHiddenCollectionsIDs.has(file.collectionID),
            ),
        );
        const setFilesDownloadProgressAttributes =
            setFilesDownloadProgressAttributesCreator(
                defaultHiddenCollectionUserFacingName,
                PseudoCollectionID.hiddenItems,
                true,
            );

        await downloadCollectionFiles(
            defaultHiddenCollectionUserFacingName,
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

const isQuickLinkCollection = (collection: Collection) =>
    collection.magicMetadata?.data.subType == CollectionSubType.quicklink;

export function isIncomingViewerShare(collection: Collection, user: User) {
    const sharee = collection.sharees?.find((sharee) => sharee.id === user.id);
    return sharee?.role == "VIEWER";
}

export function isValidReplacementAlbum(
    collection: Collection,
    user: User,
    wantedCollectionName: string,
) {
    return (
        collection.name === wantedCollectionName &&
        (collection.type == "album" ||
            collection.type == "folder" ||
            collection.type == "uncategorized") &&
        !isHiddenCollection(collection) &&
        !isQuickLinkCollection(collection) &&
        collection.owner.id == user.id
    );
}

export const getOrCreateAlbum = async (
    albumName: string,
    existingCollections: Collection[],
) => {
    const user: User = getData("user");
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
