import { assertionFailed } from "ente-base/assert";
import { joinPath, nameAndExtension } from "ente-base/file-name";
import log from "ente-base/log";
import { type Electron } from "ente-base/types/ipc";
import { saveAsFileAndRevokeObjectURL } from "ente-base/utils/web";
import { downloadManager } from "ente-gallery/services/download";
import { writeStream } from "ente-gallery/utils/native-stream";
import type { EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { decodeLivePhoto } from "ente-media/live-photo";
import {
    safeDirectoryName,
    safeFileName,
} from "ente-new/photos/utils/native-fs";
import JSZip from "jszip";
import type {
    AddSaveGroup,
    UpdateSaveGroup,
} from "../components/utils/save-groups";

/**
 * Download limits optimized for different devices and browsers.
 */
interface DownloadLimits {
    /** Number of concurrent file downloads. */
    concurrency: number;
    /** Maximum size of a ZIP batch in bytes. */
    maxZipSize: number;
}

let cachedLimits: DownloadLimits | undefined;

/**
 * Get download limits for the current device.
 *
 * - Mobile devices: 4 concurrent, 100MB max
 * - Desktop: 8 concurrent, 250MB max
 */
const getDownloadLimits = (): DownloadLimits => {
    if (cachedLimits) return cachedLimits;

    const ua = navigator.userAgent.toLowerCase();
    const isMobile =
        ua.includes("iphone") ||
        ua.includes("ipad") ||
        ua.includes("ipod") ||
        ua.includes("android") ||
        ua.includes("mobile") ||
        ua.includes("tablet") ||
        (ua.includes("macintosh") && navigator.maxTouchPoints > 1);

    cachedLimits = isMobile
        ? { concurrency: 4, maxZipSize: 100 * 1024 * 1024 } // 100MB
        : { concurrency: 8, maxZipSize: 250 * 1024 * 1024 }; // 250MB

    return cachedLimits;
};

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
    const failedFiles: EnteFile[] = [];
    let isDownloading = false;
    let updateSaveGroup: UpdateSaveGroup = () => undefined;
    // Track the next ZIP batch index across retries so part numbers continue
    // sequentially (e.g., if initial download creates Parts 1-5 and fails,
    // retry creates Part 6+ instead of starting over at Part 1).
    let nextZipBatchIndex = 1;

    const downloadFilesDesktop = async (
        filesToDownload: EnteFile[],
        resetFailedCount = false,
    ) => {
        if (!filesToDownload.length || isDownloading) return;
        if (!electron || !downloadDirPath) return;

        isDownloading = true;
        if (resetFailedCount) {
            updateSaveGroup((g) => ({ ...g, failed: 0 }));
        }
        failedFiles.length = 0;

        try {
            for (const file of filesToDownload) {
                if (canceller.signal.aborted) break;
                try {
                    await saveFileDesktop(electron, file, downloadDirPath);
                    updateSaveGroup((g) => ({ ...g, success: g.success + 1 }));
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

    const downloadFilesWeb = async (
        filesToDownload: EnteFile[],
        resetFailedCount = false,
    ) => {
        if (!filesToDownload.length || isDownloading) return;

        // Reset counts first if this is a retry, before any other logic
        if (resetFailedCount) {
            updateSaveGroup((g) => ({
                ...g,
                failed: 0,
                failureReason: undefined,
            }));
            failedFiles.length = 0;
        }

        // If already offline, mark all files as failed so retry is available
        if (!navigator.onLine) {
            log.info("Download skipped - network is offline");
            for (const file of filesToDownload) {
                failedFiles.push(file);
            }
            updateSaveGroup((g) => ({
                ...g,
                failed: filesToDownload.length,
                failureReason: "network_offline",
            }));
            return;
        }

        isDownloading = true;
        // Only clear on first download, not retry (already cleared above)
        if (!resetFailedCount) {
            failedFiles.length = 0;
        }

        try {
            // Single non-live-photo file: download directly without zipping
            const singleFile = filesToDownload[0];
            if (
                filesToDownload.length === 1 &&
                singleFile &&
                singleFile.metadata.fileType !== FileType.livePhoto
            ) {
                try {
                    const fileBlob = await downloadManager.fileBlob(singleFile);
                    const fileName = fileFileName(singleFile);
                    const url = URL.createObjectURL(fileBlob);
                    saveAsFileAndRevokeObjectURL(url, fileName);
                    updateSaveGroup((g) => ({ ...g, success: g.success + 1 }));
                } catch (e) {
                    log.error("File download failed", e);
                    failedFiles.push(singleFile);
                    updateSaveGroup((g) => ({ ...g, failed: g.failed + 1 }));
                }
            } else {
                // Multiple files or live photo: use ZIP
                nextZipBatchIndex = await saveAsZip(
                    filesToDownload,
                    title,
                    () =>
                        updateSaveGroup((g) => ({
                            ...g,
                            success: g.success + 1,
                        })),
                    (file) => {
                        failedFiles.push(file);
                        updateSaveGroup((g) => ({
                            ...g,
                            failed: g.failed + 1,
                        }));
                    },
                    canceller,
                    updateSaveGroup,
                    nextZipBatchIndex,
                );
            }

            if (!failedFiles.length) {
                updateSaveGroup((g) => ({ ...g, retry: undefined }));
            }
        } finally {
            isDownloading = false;
        }
    };

    const downloadFiles = electron ? downloadFilesDesktop : downloadFilesWeb;

    const retry = () => {
        if (!failedFiles.length || isDownloading || canceller.signal.aborted)
            return;
        void downloadFiles([...failedFiles], true);
    };

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
 * A helper class to accumulate files into ZIP batches and download them when
 * the batch size limit is reached.
 */
class ZipBatcher {
    private zip = new JSZip();
    private currentBatchSize = 0;
    private currentFileCount = 0;
    private batchIndex: number;
    private usedNames = new Set<string>();
    private baseName: string;
    private maxZipSize: number;
    private onStateChange?: (
        isDownloading: boolean,
        partNumber: number,
    ) => void;

    constructor(
        baseName: string,
        maxZipSize: number,
        startingBatchIndex = 1,
        onStateChange?: (isDownloading: boolean, partNumber: number) => void,
    ) {
        this.baseName = baseName;
        this.maxZipSize = maxZipSize;
        this.batchIndex = startingBatchIndex;
        this.onStateChange = onStateChange;
    }

    /**
     * Get the next batch index that would be used for the next ZIP file.
     * This is useful for tracking progress across retries.
     */
    getNextBatchIndex(): number {
        return this.batchIndex;
    }

    /**
     * Get the current batch index being processed.
     */
    getCurrentBatchIndex(): number {
        return this.batchIndex;
    }

    /**
     * Add file data to the current ZIP batch. If adding this file would exceed
     * the batch size limit, the current batch is downloaded first.
     */
    async addFile(data: Uint8Array | Blob, fileName: string): Promise<void> {
        const size = data instanceof Blob ? data.size : data.byteLength;

        // If adding this file would exceed the limit and we have files in the
        // batch, download the current batch first.
        if (
            this.currentBatchSize > 0 &&
            this.currentBatchSize + size > this.maxZipSize
        ) {
            await this.downloadCurrentBatch();
            // Notify that we're now preparing a new part
            this.onStateChange?.(false, this.batchIndex);
        }

        // Ensure unique file names within the ZIP
        const uniqueName = this.getUniqueName(fileName);
        this.usedNames.add(uniqueName);
        this.zip.file(uniqueName, data);
        this.currentBatchSize += size;
        this.currentFileCount++;
    }

    /**
     * Download any remaining files in the current batch.
     */
    async flush(): Promise<void> {
        if (this.currentBatchSize > 0) {
            await this.downloadCurrentBatch();
        }
    }

    private async downloadCurrentBatch(): Promise<void> {
        this.onStateChange?.(true, this.batchIndex);
        try {
            const zipBlob = await this.zip.generateAsync({ type: "blob" });
            const fileLabel =
                this.currentFileCount === 1
                    ? "1 file"
                    : `${this.currentFileCount} files`;
            const zipName = `${this.baseName} Part ${this.batchIndex} - ${fileLabel}.zip`;

            const url = URL.createObjectURL(zipBlob);
            saveAsFileAndRevokeObjectURL(url, zipName);
        } finally {
            this.onStateChange?.(false, this.batchIndex);
        }

        // Reset for next batch
        this.zip = new JSZip();
        this.currentBatchSize = 0;
        this.currentFileCount = 0;
        this.usedNames.clear();
        this.batchIndex++;
    }

    /**
     * Generate a unique file name within the ZIP by appending a suffix if the
     * name already exists.
     */
    private getUniqueName(fileName: string): string {
        if (!this.usedNames.has(fileName)) {
            return fileName;
        }

        const [name, ext] = nameAndExtension(fileName);
        let counter = 1;
        let uniqueName: string;
        do {
            uniqueName = ext
                ? `${name}(${counter}).${ext}`
                : `${name}(${counter})`;
            counter++;
        } while (this.usedNames.has(uniqueName));

        return uniqueName;
    }
}

/** Result of downloading and processing a single file for ZIP inclusion. */
type DownloadedFileData =
    | { type: "regular"; fileName: string; data: Uint8Array }
    | {
          type: "livePhoto";
          imageFileName: string;
          imageData: Uint8Array;
          videoFileName: string;
          videoData: Uint8Array;
      };

/**
 * Download and process a single file, returning the data ready for ZIP.
 */
const downloadFileForZip = async (
    file: EnteFile,
): Promise<DownloadedFileData> => {
    const fileBlob = await downloadManager.fileBlob(file);
    const fileName = fileFileName(file);

    if (file.metadata.fileType == FileType.livePhoto) {
        const { imageFileName, imageData, videoFileName, videoData } =
            await decodeLivePhoto(fileName, fileBlob);
        return {
            type: "livePhoto",
            imageFileName,
            imageData,
            videoFileName,
            videoData,
        };
    } else {
        const data = new Uint8Array(await fileBlob.arrayBuffer());
        return { type: "regular", fileName, data };
    }
};

/**
 * Save multiple files as ZIP archives to the user's download folder.
 *
 * Files are batched into ZIPs of up to 100MB each. If the total exceeds 100MB,
 * multiple ZIP files will be downloaded. Downloads are performed concurrently
 * (up to {@link CONCURRENT_DOWNLOADS} at a time) for better performance.
 *
 * @param files The files to download and add to the ZIP.
 * @param baseName The base name for the ZIP file(s).
 * @param onSuccess Callback invoked after each file is successfully added.
 * @param onError Callback invoked when a file fails to download.
 * @param canceller An AbortController to check for cancellation.
 * @param startingBatchIndex The batch index to start from (for retries).
 * @returns The next batch index to use for subsequent ZIPs (useful for retries).
 */
const saveAsZip = async (
    files: EnteFile[],
    baseName: string,
    onSuccess: () => void,
    onError: (file: EnteFile, error: unknown) => void,
    canceller: AbortController,
    updateSaveGroup: UpdateSaveGroup,
    startingBatchIndex = 1,
): Promise<number> => {
    const { concurrency, maxZipSize } = getDownloadLimits();
    const batcher = new ZipBatcher(
        baseName,
        maxZipSize,
        startingBatchIndex,
        (isDownloading, partNumber) =>
            updateSaveGroup((g) => ({
                ...g,
                isDownloadingZip: isDownloading,
                currentPart: partNumber,
            })),
    );

    // Set initial part number
    updateSaveGroup((g) => ({ ...g, currentPart: startingBatchIndex }));

    // Queue of files to process
    let fileIndex = 0;

    // Track if we've gone offline to stop processing immediately.
    // Using an object so the value can be mutated by event handlers and
    // checked synchronously by the async workers.
    const networkState = { isOffline: !navigator.onLine };
    const handleOffline = () => {
        networkState.isOffline = true;
    };
    const handleOnline = () => {
        networkState.isOffline = false;
    };
    window.addEventListener("offline", handleOffline);
    window.addEventListener("online", handleOnline);

    // Mutex for serializing ZIP additions (download is concurrent, but adding
    // to the ZIP must be serialized to avoid race conditions with batching)
    let zipMutex: Promise<void> = Promise.resolve();
    const withZipLock = async <T>(fn: () => Promise<T>): Promise<T> => {
        const prev = zipMutex;
        let resolve: () => void;
        zipMutex = new Promise((r) => (resolve = r));
        await prev;
        try {
            return await fn();
        } finally {
            resolve!();
        }
    };

    // Process a single file: download, then add to ZIP
    const processFile = async (): Promise<boolean> => {
        // Stop immediately if offline or cancelled
        if (networkState.isOffline || canceller.signal.aborted) {
            return false;
        }

        // Get next file to process
        const currentIndex = fileIndex++;
        if (currentIndex >= files.length) {
            return false;
        }

        const file = files[currentIndex]!;
        try {
            // Check again before starting download (value can change via event handler)
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
            if (networkState.isOffline) {
                // Put this file back for retry
                onError(file, new Error("Network offline"));
                return false;
            }

            // Download happens concurrently
            const downloadedData = await downloadFileForZip(file);

            // Adding to ZIP is serialized via mutex
            await withZipLock(async () => {
                if (downloadedData.type === "livePhoto") {
                    await batcher.addFile(
                        downloadedData.imageData,
                        downloadedData.imageFileName,
                    );
                    await batcher.addFile(
                        downloadedData.videoData,
                        downloadedData.videoFileName,
                    );
                } else {
                    await batcher.addFile(
                        downloadedData.data,
                        downloadedData.fileName,
                    );
                }
            });
            onSuccess();
        } catch (e) {
            // Individual file failed - mark it for retry but continue with others
            // Only log non-network errors to avoid log spam when offline
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
            if (!networkState.isOffline) {
                log.error(`Failed to download file ${file.id}, skipping`, e);
            }
            onError(file, e);

            // Only stop all processing if we went offline (not for individual failures)
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
            if (networkState.isOffline) {
                updateSaveGroup((g) => ({
                    ...g,
                    failureReason: "network_offline",
                }));
                return false;
            }
            // Mark as file error for individual failures
            updateSaveGroup((g) => ({
                ...g,
                failureReason: g.failureReason ?? "file_error",
            }));
            // Continue processing remaining files even if this one failed
        }

        return true;
    };

    // Worker that continuously processes files until done
    const worker = async (): Promise<void> => {
        while (await processFile()) {
            // Continue processing
        }
    };

    try {
        // Start concurrent workers
        const workers = Array.from(
            { length: Math.min(concurrency, files.length) },
            () => worker(),
        );
        await Promise.all(workers);

        // If we went offline, mark remaining files as failed
        if (networkState.isOffline) {
            updateSaveGroup((g) => ({
                ...g,
                failureReason: "network_offline",
            }));
            while (fileIndex < files.length) {
                const file = files[fileIndex++];
                if (file) {
                    onError(file, new Error("Network offline"));
                }
            }
        }

        // Flush whatever we have (even partial) unless cancelled
        if (!canceller.signal.aborted) {
            await batcher.flush();
        }

        return batcher.getNextBatchIndex();
    } finally {
        // Clean up event listeners
        window.removeEventListener("offline", handleOffline);
        window.removeEventListener("online", handleOnline);
    }
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
