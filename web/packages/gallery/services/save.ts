import { ensureElectron } from "ente-base/electron";
import { joinPath } from "ente-base/file-name";
import log from "ente-base/log";
import { type Electron } from "ente-base/types/ipc";
import { saveAsFileAndRevokeObjectURL } from "ente-base/utils/web";
import { downloadManager } from "ente-gallery/services/download";
import { detectFileTypeInfo } from "ente-gallery/utils/detect-type";
import { uniqueFilesByID } from "ente-gallery/utils/file";
import { writeStream } from "ente-gallery/utils/native-stream";
import type { EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { decodeLivePhoto } from "ente-media/live-photo";
import {
    defaultHiddenCollectionUserFacingName,
    findDefaultHiddenCollectionIDs,
} from "ente-new/photos/services/collection";
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import {
    savedCollectionFiles,
    savedCollections,
} from "ente-new/photos/services/photos-fdb";
import {
    safeDirectoryName,
    safeFileName,
} from "ente-new/photos/utils/native-fs";
import { wait } from "ente-utils/promise";

export interface FilesDownloadProgressAttributes {
    id: number;
    success: number;
    failed: number;
    total: number;
    folderName: string;
    collectionID: number;
    isHidden: boolean;
    downloadDirPath: string;
    canceller: AbortController;
}

export type SetFilesDownloadProgressAttributes = (
    value:
        | Partial<FilesDownloadProgressAttributes>
        | ((
              prev: FilesDownloadProgressAttributes,
          ) => FilesDownloadProgressAttributes),
) => void;

export type SetFilesDownloadProgressAttributesCreator = (
    folderName: string,
    collectionID?: number,
    isHidden?: boolean,
) => SetFilesDownloadProgressAttributes;

export async function downloadFilesWithProgress(
    files: EnteFile[],
    downloadDirPath: string,
    setFilesDownloadProgressAttributes: SetFilesDownloadProgressAttributes,
) {
    if (!files.length) {
        return;
    }
    const canceller = new AbortController();
    const increaseSuccess = () => {
        if (canceller.signal.aborted) return;
        setFilesDownloadProgressAttributes((prev) => ({
            ...prev,
            success: prev.success + 1,
        }));
    };
    const increaseFailed = () => {
        if (canceller.signal.aborted) return;
        setFilesDownloadProgressAttributes((prev) => ({
            ...prev,
            failed: prev.failed + 1,
        }));
    };
    const isCancelled = () => canceller.signal.aborted;

    setFilesDownloadProgressAttributes({
        downloadDirPath,
        success: 0,
        failed: 0,
        total: files.length,
        canceller,
    });

    const electron = globalThis.electron;
    if (electron) {
        await downloadFilesDesktop(
            electron,
            files,
            { increaseSuccess, increaseFailed, isCancelled },
            downloadDirPath,
        );
    } else {
        await downloadFiles(files, {
            increaseSuccess,
            increaseFailed,
            isCancelled,
        });
    }
}

export async function downloadSelectedFiles(
    files: EnteFile[],
    setFilesDownloadProgressAttributes: SetFilesDownloadProgressAttributes,
) {
    if (!files.length) {
        return;
    }
    let downloadDirPath: string;
    const electron = globalThis.electron;
    if (electron) {
        downloadDirPath = await electron.selectDirectory();
        if (!downloadDirPath) {
            return;
        }
    }
    await downloadFilesWithProgress(
        files,
        downloadDirPath,
        setFilesDownloadProgressAttributes,
    );
}

export async function downloadSingleFile(
    file: EnteFile,
    setFilesDownloadProgressAttributes: SetFilesDownloadProgressAttributes,
) {
    let downloadDirPath: string;
    const electron = globalThis.electron;
    if (electron) {
        downloadDirPath = await electron.selectDirectory();
        if (!downloadDirPath) {
            return;
        }
    }
    await downloadFilesWithProgress(
        [file],
        downloadDirPath,
        setFilesDownloadProgressAttributes,
    );
}

export async function downloadFiles(
    files: EnteFile[],
    progressBarUpdater: {
        increaseSuccess: () => void;
        increaseFailed: () => void;
        isCancelled: () => boolean;
    },
) {
    for (const file of files) {
        try {
            if (progressBarUpdater?.isCancelled()) {
                return;
            }
            await saveAsFile(file);
            progressBarUpdater?.increaseSuccess();
        } catch (e) {
            log.error("download fail for file", e);
            progressBarUpdater?.increaseFailed();
        }
    }
}

/**
 * Save the given {@link EnteFile} as a file in the user's download folder.
 */
const saveAsFile = async (file: EnteFile) => {
    const fileBlob = await downloadManager.fileBlob(file);
    const fileName = fileFileName(file);
    if (file.metadata.fileType == FileType.livePhoto) {
        const { imageFileName, imageData, videoFileName, videoData } =
            await decodeLivePhoto(fileName, fileBlob);

        await saveBlobPartAsFile(imageData, imageFileName);

        // Downloading multiple works everywhere except, you guessed it,
        // Safari. Make up for their incompetence by adding a setTimeout.
        await wait(300) /* arbitrary constant, 300ms */;
        await saveBlobPartAsFile(videoData, videoFileName);
    } else {
        await saveBlobPartAsFile(fileBlob, fileName);
    }
};

/**
 * Save the given {@link blob} as a file in the user's download folder.
 */
const saveBlobPartAsFile = async (blobPart: BlobPart, fileName: string) =>
    createTypedObjectURL(blobPart, fileName).then((url) =>
        saveAsFileAndRevokeObjectURL(url, fileName),
    );

const createTypedObjectURL = async (blobPart: BlobPart, fileName: string) => {
    const blob = blobPart instanceof Blob ? blobPart : new Blob([blobPart]);
    const { mimeType } = await detectFileTypeInfo(new File([blob], fileName));
    return URL.createObjectURL(new Blob([blob], { type: mimeType }));
};

async function downloadFilesDesktop(
    electron: Electron,
    files: EnteFile[],
    progressBarUpdater: {
        increaseSuccess: () => void;
        increaseFailed: () => void;
        isCancelled: () => boolean;
    },
    downloadPath: string,
) {
    for (const file of files) {
        try {
            if (progressBarUpdater?.isCancelled()) {
                return;
            }
            await downloadFileDesktop(electron, file, downloadPath);
            progressBarUpdater?.increaseSuccess();
        } catch (e) {
            log.error("download fail for file", e);
            progressBarUpdater?.increaseFailed();
        }
    }
}

async function downloadFileDesktop(
    electron: Electron,
    file: EnteFile,
    downloadDir: string,
) {
    const fs = electron.fs;

    const stream = await downloadManager.fileStream(file);
    const fileName = fileFileName(file);

    if (file.metadata.fileType == FileType.livePhoto) {
        const fileBlob = await new Response(stream).blob();
        const { imageFileName, imageData, videoFileName, videoData } =
            await decodeLivePhoto(fileName, fileBlob);
        const imageExportName = await safeFileName(
            downloadDir,
            imageFileName,
            fs.exists,
        );
        const imageStream = new Response(imageData).body;
        await writeStream(
            electron,
            joinPath(downloadDir, imageExportName),
            imageStream,
        );
        try {
            const videoExportName = await safeFileName(
                downloadDir,
                videoFileName,
                fs.exists,
            );
            const videoStream = new Response(videoData).body;
            await writeStream(
                electron,
                joinPath(downloadDir, videoExportName),
                videoStream,
            );
        } catch (e) {
            await fs.rm(joinPath(downloadDir, imageExportName));
            throw e;
        }
    } else {
        const fileExportName = await safeFileName(
            downloadDir,
            fileName,
            fs.exists,
        );
        await writeStream(
            electron,
            joinPath(downloadDir, fileExportName),
            stream,
        );
    }
}

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
