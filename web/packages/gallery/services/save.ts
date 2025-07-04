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

/**
 * An object that keeps track of progress of the download of a set of files.
 *
 * This "download" is distinct from the downloads the app does from remote. What
 * we're doing here is perhaps more accurately but too verbosely described as "a
 * user initiated download of files to the user's device", aka "saving them". In
 * contrast, the app does the "download the file from remote" internal action,
 * e.g. for showing to the user or performing some indexing etc.
 */
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
            await saveFileDesktop(electron, file, downloadPath);
            progressBarUpdater?.increaseSuccess();
        } catch (e) {
            log.error("download fail for file", e);
            progressBarUpdater?.increaseFailed();
        }
    }
}

/**
 * Save a file to the given {@link directoryPath} using native filesystem APIs.
 *
 * This is a sibling of {@link saveAsFile} for use when we are running in the
 * context of our desktop app. Unlike the browser, the desktop app can use
 * native file system APIs to efficiently write the files on disk without
 * needing to prompt the user for each write.
 *
 * @param electron An {@link Electron} instance, a witness to the fact that
 * we're running in the desktop app.
 *
 * @param file The {@link EnteFile} whose contents we want to save to the user's
 * file system.
 *
 * @param directoryPath The file system directory in which to save the file.
 */
const saveFileDesktop = async (
    electron: Electron,
    file: EnteFile,
    directoryPath: string,
) => {
    const fs = electron.fs;

    const createSafeName = (fileName: string) =>
        safeFileName(directoryPath, fileName, fs.exists);

    const writeStreamToFile = (
        fileName: string,
        stream: ReadableStream<Uint8Array> | null,
    ) => writeStream(electron, joinPath(directoryPath, fileName), stream);

    const stream = await downloadManager.fileStream(file);
    const fileName = fileFileName(file);

    if (file.metadata.fileType == FileType.livePhoto) {
        const { imageFileName, imageData, videoFileName, videoData } =
            await decodeLivePhoto(fileName, await new Response(stream).blob());
        const imageExportName = await createSafeName(imageFileName);
        await writeStreamToFile(imageExportName, new Response(imageData).body);
        try {
            await writeStreamToFile(
                await createSafeName(videoFileName),
                new Response(videoData).body,
            );
        } catch (e) {
            await fs.rm(joinPath(directoryPath, imageExportName));
            throw e;
        }
    } else {
        await writeStreamToFile(await createSafeName(fileName), stream);
    }
};

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
