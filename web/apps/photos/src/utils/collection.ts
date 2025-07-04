import { ensureElectron } from "ente-base/electron";
import { joinPath } from "ente-base/file-name";
import log from "ente-base/log";
import { uniqueFilesByID } from "ente-gallery/utils/file";
import type { EnteFile } from "ente-media/file";
import {
    defaultHiddenCollectionUserFacingName,
    findDefaultHiddenCollectionIDs,
} from "ente-new/photos/services/collection";
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import {
    savedCollectionFiles,
    savedCollections,
} from "ente-new/photos/services/photos-fdb";
import { safeDirectoryName } from "ente-new/photos/utils/native-fs";
import type {
    SetFilesDownloadProgressAttributes,
    SetFilesDownloadProgressAttributesCreator,
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
