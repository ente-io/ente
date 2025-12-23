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
import { safeFileName } from "ente-new/photos/utils/native-fs";
import { wait } from "ente-utils/promise";
import type {
    AddSaveGroup,
    UpdateSaveGroup,
} from "../components/utils/save-groups";
import type { WritableStreamHandle } from "./zip";
import {
    createNativeZipWritable,
    getWritableStreamForZip,
    streamFilesToZip,
    zipFileName,
} from "./zip";

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
    }

    // For web streaming ZIP, get the writable handle first (shows file picker)
    // so we only show the notification after user confirms the location.
    let preObtainedWritable: WritableStreamHandle | undefined;
    if (!electron && files.length > 1) {
        const zipName = zipFileName(title);
        const handle = await getWritableStreamForZip(zipName);
        if (handle === null) {
            // User cancelled the file picker
            return;
        }
        if (handle === undefined) {
            // Streaming unavailable, will fall back to individual downloads
            log.info(
                "Streaming ZIP unavailable, will use individual downloads",
            );
        } else {
            preObtainedWritable = handle;
        }
    }

    const canceller = new AbortController();
    const failedFiles: EnteFile[] = [];
    let isDownloading = false;
    let updateSaveGroup: UpdateSaveGroup = () => undefined;
    let retryAttempt = 0;

    const saveSingleFile = async (file: EnteFile) => {
        if (electron && downloadDirPath) {
            await saveFileDesktop(electron, file, downloadDirPath);
        } else {
            await saveAsFile(file);
        }
        updateSaveGroup((g) => ({ ...g, success: g.success + 1 }));
    };

    const downloadFiles = async (
        filesToDownload: EnteFile[],
        resetFailedCount = false,
    ) => {
        if (!filesToDownload.length || isDownloading) return;

        isDownloading = true;
        if (resetFailedCount) {
            updateSaveGroup((g) => ({ ...g, failed: 0 }));
            retryAttempt += 1;
        }
        failedFiles.length = 0;

        try {
            const zipTitle =
                retryAttempt > 0 ? `${title}-retry-${retryAttempt}` : title;

            if (filesToDownload.length > 1) {
                let writableOverride: WritableStreamHandle | undefined =
                    preObtainedWritable;

                if (electron && downloadDirPath) {
                    const zipExportName = await safeFileName(
                        downloadDirPath,
                        zipFileName(zipTitle),
                        electron.fs.exists,
                    );
                    const zipPath = joinPath(downloadDirPath, zipExportName);
                    writableOverride = createNativeZipWritable(
                        electron,
                        zipPath,
                    );
                }

                // For retries on web, we need to get a new writable handle
                if (!electron && retryAttempt > 0) {
                    const retryZipName = zipFileName(zipTitle);
                    const handle = await getWritableStreamForZip(retryZipName);
                    if (handle === null) {
                        // User cancelled retry file picker
                        canceller.abort();
                        return;
                    }
                    if (handle) {
                        writableOverride = handle;
                    }
                }

                if (writableOverride) {
                    const streamingResult = await streamFilesToZip({
                        files: filesToDownload,
                        title: zipTitle,
                        signal: canceller.signal,
                        writable: writableOverride,
                        onFileSuccess: (_file, entryCount) => {
                            updateSaveGroup((g) => ({
                                ...g,
                                success: g.success + entryCount,
                            }));
                        },
                        onFileFailure: (file) => {
                            if (!failedFiles.includes(file))
                                failedFiles.push(file);
                            updateSaveGroup((g) => ({
                                ...g,
                                failed: g.failed + 1,
                            }));
                        },
                    });

                    if (streamingResult === "success") {
                        if (!failedFiles.length) {
                            updateSaveGroup((g) => ({
                                ...g,
                                retry: undefined,
                            }));
                        }
                        return;
                    }

                    if (streamingResult === "cancelled") {
                        canceller.abort();
                        return;
                    }

                    if (streamingResult !== "unavailable") {
                        // Streaming started but failed; avoid double-downloading
                        return;
                    }
                }

                // Fall back to individual downloads if streaming unavailable
                log.info(
                    "Streaming ZIP unavailable, falling back to individual",
                );
            }

            // Individual file downloads (used for single-file or when ZIP is unavailable)
            for (const file of filesToDownload) {
                if (canceller.signal.aborted) break;
                try {
                    await saveSingleFile(file);
                } catch (e) {
                    log.error("File download failed", e);
                    failedFiles.push(file);
                    updateSaveGroup((g) => ({ ...g, failed: g.failed + 1 }));
                }
            }

            if (!failedFiles.length) {
                updateSaveGroup((g) => ({ ...g, retry: undefined }));
            }
        } finally {
            isDownloading = false;
        }
    };

    const retry = () => {
        if (!failedFiles.length || isDownloading || canceller.signal.aborted)
            return;
        void downloadFiles([...failedFiles], true);
    };

    // Only add save group notification after user has confirmed the download location
    updateSaveGroup = onAddSaveGroup({
        title,
        collectionSummaryID,
        isHiddenCollectionSummary,
        downloadDirPath,
        total,
        canceller,
        retry,
    });

    await downloadFiles(files);
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
const saveBlobPartAsFile = async (
    blobPart: BlobPart,
    fileName: string,
    mimeType?: string,
) =>
    createTypedObjectURL(blobPart, fileName, mimeType).then((url) =>
        saveAsFileAndRevokeObjectURL(url, fileName),
    );

const createTypedObjectURL = async (
    blobPart: BlobPart,
    fileName: string,
    mimeType?: string,
) => {
    const blob = blobPart instanceof Blob ? blobPart : new Blob([blobPart]);
    if (!mimeType) {
        try {
            ({ mimeType } = await detectFileTypeInfo(
                new File([blob], fileName),
            ));
        } catch (e) {
            log.error("Failed to detect mime type", e);
        }
    }
    return URL.createObjectURL(new Blob([blob], { type: mimeType }));
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

// Streaming ZIP logic moved to zip.ts
