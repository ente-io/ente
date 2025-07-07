import { assertionFailed } from "ente-base/assert";
import { joinPath } from "ente-base/file-name";
import log from "ente-base/log";
import { type Electron } from "ente-base/types/ipc";
import { saveAsFileAndRevokeObjectURL } from "ente-base/utils/web";
import { downloadManager } from "ente-gallery/services/download";
import { detectFileTypeInfo } from "ente-gallery/utils/detect-type";
import { writeStream } from "ente-gallery/utils/native-stream";
import type { EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { decodeLivePhoto } from "ente-media/live-photo";
import {
    safeDirectoryName,
    safeFileName,
} from "ente-new/photos/utils/native-fs";
import { wait } from "ente-utils/promise";
import type { AddSaveGroup } from "../components/utils/save-groups";

/**
 * Save the given {@link files} to the user's device.
 *
 * If we're running in the context of the web app, the files will be saved to
 * the user's download folder. If we're running in the context of our desktop
 * app, the user will be prompted to select a directory on their file system and
 * the files will be saved therein.
 *
 * @param files The files to save.
 *
 * @param title A title to show in the UI notification that indicates the
 * progress of the save.
 *
 * @param onAddSaveGroup A function that can be used to create a save group
 * associated with the save. The newly added save group will correspond to a
 * notification shown in the UI, and the progress and status of the save can be
 * communicated by updating the save group's state using the updater function
 * obtained when adding the save group.
 */
export const downloadAndSaveFiles = (
    files: EnteFile[],
    title: string,
    onAddSaveGroup: AddSaveGroup,
) => downloadAndSave(files, title, onAddSaveGroup);

/**
 * Save all the files of a collection to the user's device.
 *
 * This is a variant of {@link downloadAndSaveFiles}, except instead of taking a
 * list of files to save, this variant is tailored for saving saves all the
 * files that belong to a collection. Otherwise, it broadly behaves similarly;
 * see that method's documentation for more details.
 *
 * When running in the context of the desktop app, instead of saving the files
 * in the directory selected by the user, files are saved in a directory with
 * the same name as the collection.
 *
 * @param isHiddenCollectionSummary `true` if the collection is associated with
 * a "hidden" collection or pseudo-collection in the app. Only relevant when
 * running in the context of the photos app, can be `undefined` otherwise.
 */
export const downloadAndSaveCollectionFiles = async (
    collectionSummaryName: string,
    collectionSummaryID: number,
    files: EnteFile[],
    isHiddenCollectionSummary: boolean | undefined,
    onAddSaveGroup: AddSaveGroup,
) =>
    downloadAndSave(
        files,
        collectionSummaryName,
        onAddSaveGroup,
        collectionSummaryName,
        collectionSummaryID,
        isHiddenCollectionSummary,
    );

/**
 * The lower level primitive that the public API of this module delegates to.
 */
const downloadAndSave = async (
    files: EnteFile[],
    title: string,
    onAddSaveGroup: AddSaveGroup,
    collectionSummaryName?: string,
    collectionSummaryID?: number,
    isHiddenCollectionSummary?: boolean,
) => {
    const electron = globalThis.electron;

    const total = files.length;
    if (!files.length) {
        // Nothing to download.
        assertionFailed();
        return;
    }

    let downloadDirPath: string | undefined;
    if (electron) {
        downloadDirPath = await electron.selectDirectory();
        if (!downloadDirPath) {
            // The user cancelled on the directory selection dialog.
            return;
        }
        if (collectionSummaryName) {
            downloadDirPath = await mkdirCollectionDownloadFolder(
                electron,
                downloadDirPath,
                collectionSummaryName,
            );
        }
    }

    const canceller = new AbortController();

    const updateSaveGroup = onAddSaveGroup({
        title,
        collectionSummaryID,
        isHiddenCollectionSummary,
        downloadDirPath,
        total,
        canceller,
    });

    for (const file of files) {
        if (canceller.signal.aborted) break;
        try {
            if (electron && downloadDirPath) {
                await saveFileDesktop(electron, file, downloadDirPath);
            } else {
                await saveAsFile(file);
            }
            updateSaveGroup((g) => ({ ...g, success: g.success + 1 }));
        } catch (e) {
            log.error("File download failed", e);
            updateSaveGroup((g) => ({ ...g, failed: g.failed + 1 }));
        }
    }
};

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

/**
 * Create a new directory on the user's file system with the same name as the
 * provided {@link collectionName} under the provided {@link downloadDirPath},
 * and return the full path to the created directory.
 *
 * This function can be used only when running in the context of our desktop
 * app, and so such requires an {@link Electron} instance as the witness.
 */
const mkdirCollectionDownloadFolder = async (
    { fs }: Electron,
    downloadDirPath: string,
    collectionName: string,
) => {
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
};

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

    const createExportName = (fileName: string) =>
        safeFileName(directoryPath, fileName, fs.exists);

    const writeStreamToFile = (
        exportName: string,
        stream: ReadableStream<Uint8Array> | null,
    ) => writeStream(electron, joinPath(directoryPath, exportName), stream);

    const stream = await downloadManager.fileStream(file);
    const fileName = fileFileName(file);

    if (file.metadata.fileType == FileType.livePhoto) {
        const { imageFileName, imageData, videoFileName, videoData } =
            await decodeLivePhoto(fileName, await new Response(stream).blob());
        const imageExportName = await createExportName(imageFileName);
        await writeStreamToFile(imageExportName, new Response(imageData).body);
        try {
            await writeStreamToFile(
                await createExportName(videoFileName),
                new Response(videoData).body,
            );
        } catch (e) {
            await fs.rm(joinPath(directoryPath, imageExportName));
            throw e;
        }
    } else {
        await writeStreamToFile(await createExportName(fileName), stream);
    }
};
