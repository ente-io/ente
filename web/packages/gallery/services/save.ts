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
import { Zip, ZipPassThrough } from "fflate";
import type {
    AddSaveGroup,
    UpdateSaveGroup,
} from "../components/utils/save-groups";

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
                let writableOverride: WritableStreamHandle | undefined;
                if (electron && downloadDirPath) {
                    const zipExportName = await safeFileName(
                        downloadDirPath,
                        zipFileName(zipTitle),
                        electron.fs.exists,
                    );
                    const zipPath = joinPath(downloadDirPath, zipExportName);
                    writableOverride = await createNativeZipWritable(
                        electron,
                        zipPath,
                    );
                }

                // Try streaming ZIP first
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
                        if (!failedFiles.includes(file)) failedFiles.push(file);
                        updateSaveGroup((g) => ({
                            ...g,
                            failed: g.failed + 1,
                        }));
                    },
                });

                if (streamingResult === "success") {
                    if (!failedFiles.length) {
                        updateSaveGroup((g) => ({ ...g, retry: undefined }));
                    }
                    return;
                }

                if (streamingResult === "cancelled") {
                    canceller.abort();
                    return;
                }

                if (streamingResult !== "unavailable") {
                    // Streaming started but was cancelled or failed; avoid double-downloading
                    return;
                }

                // If streaming ZIP setup was unavailable (picker cancel/streamsaver missing),
                // fall back to individual downloads
                log.info(
                    "Streaming ZIP unavailable, falling back to individual",
                );
            }

            // Individual file downloads
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

/**
 * Replace invalid filesystem characters (\ / : * ? " < > |) with underscores.
 */
const sanitizeZipFileName = (name: string) =>
    name.replace(/[\\/:*?"<>|]/g, "_").trim() || "ente-download";

/** Sanitize title and strip any existing .zip extension. */
const baseZipName = (title: string) =>
    sanitizeZipFileName(title).replace(/\.zip$/i, "");

/** Generate ZIP filename, optionally with part number (e.g., "photos-part2.zip"). */
const zipFileName = (title: string, part?: number) => {
    const base = baseZipName(title);
    const nameWithPart = part ? `${base}-part${part}` : base;
    return `${nameWithPart}.zip`;
};

// ============================================================================
// Streaming ZIP support
// ============================================================================

/**
 * Type augmentation for File System Access API (Chrome/Edge 86+).
 * Falls back to StreamSaver.js on Firefox/Safari.
 */
declare global {
    interface Window {
        showSaveFilePicker?: (
            options?: SaveFilePickerOptions,
        ) => Promise<FileSystemFileHandle>;
    }
    interface SaveFilePickerOptions {
        suggestedName?: string;
        types?: { description?: string; accept: Record<string, string[]> }[];
    }
}

/**
 * Handle for managing a writable stream during ZIP creation.
 * Abstracts File System Access API vs StreamSaver.js differences.
 */
interface WritableStreamHandle {
    /** Writable stream accepting Uint8Array chunks. */
    stream: WritableStream<Uint8Array>;
    /** Finalize the file. Must be called on success. */
    close: () => Promise<void>;
    /** Abort and clean up. Call on error. */
    abort: () => void;
}

/**
 * Get a writable stream for ZIP file. Tries File System Access API first,
 * falls back to StreamSaver.js. Returns null if cancelled, undefined if unavailable.
 */
const getWritableStreamForZip = async (
    fileName: string,
): Promise<WritableStreamHandle | null | undefined> => {
    // Try File System Access API first (Chrome/Edge)
    if (window.showSaveFilePicker) {
        try {
            const fileHandle = await window.showSaveFilePicker({
                suggestedName: fileName,
                types: [
                    {
                        description: "ZIP Archive",
                        accept: { "application/zip": [".zip"] },
                    },
                ],
            });
            const writable = await fileHandle.createWritable();
            return {
                stream: writable,
                close: () => writable.close(),
                abort: () => void writable.abort(),
            };
        } catch (e) {
            // User cancelled the picker
            if (e instanceof DOMException && e.name === "AbortError") {
                return null;
            }
            log.warn(
                "File System Access API failed, falling back to StreamSaver",
                e,
            );
        }
    }

    // Fall back to StreamSaver.js (Firefox/Safari)
    try {
        // Dynamically import streamsaver to avoid SSR issues (it references document)
        const streamSaver = await import("streamsaver");
        const fileStream = streamSaver.createWriteStream(fileName);
        const writer = fileStream.getWriter();
        return {
            stream: new WritableStream<Uint8Array>({
                write: (chunk) => writer.write(chunk),
                close: () => writer.close(),
                abort: () => writer.abort(),
            }),
            close: async () => {
                await writer.close();
            },
            abort: () => {
                void writer.abort().catch(() => {
                    // Ignore errors during abort
                });
            },
        };
    } catch (e) {
        log.error("StreamSaver fallback also failed", e);
        return undefined;
    }
};

/** Options for {@link streamFilesToZip}. */
interface StreamingZipOptions {
    /** Files to add (processed in order, live photos expanded to image+video). */
    files: EnteFile[];
    /** Title for ZIP filename. */
    title: string;
    /** AbortSignal to cancel the operation. */
    signal: AbortSignal;
    /** Optional pre-configured writable (for desktop native writes). */
    writable?: WritableStreamHandle;
    /** Called when a file is successfully added. */
    onFileSuccess: (file: EnteFile, entryCount: number) => void;
    /** Called when a file fails (after retries exhausted). */
    onFileFailure: (file: EnteFile, error: unknown) => void;
}

/** Result: "success", "cancelled", "error", or "unavailable" (no streaming support). */
type StreamingZipResult = "success" | "cancelled" | "error" | "unavailable";

const STREAM_ZIP_MIN_CONCURRENCY = 2;
const STREAM_ZIP_MAX_CONCURRENCY = 12;
const STREAM_ZIP_MAX_RETRIES = 3;
const STREAM_ZIP_CONCURRENCY_REFRESH_MS = 600;
const STREAM_ZIP_BASE_WRITE_QUEUE_LIMIT = 16;
/** Base retry delay (multiplied by attempt number for backoff). */
const STREAM_ZIP_RETRY_DELAY_MS = 400;

/**
 * Determine optimal concurrency based on available memory.
 * Uses performance.memory (Chrome) or navigator.deviceMemory, defaults to 3.
 */
const getStreamZipConcurrency = () => {
    try {
        // Chrome provides heap info; keep headroom before allowing more parallel work.
        const memory = (
            performance as Performance & {
                memory?: { usedJSHeapSize: number; totalJSHeapSize: number };
            }
        ).memory;
        if (memory?.totalJSHeapSize && memory.usedJSHeapSize >= 0) {
            const free = memory.totalJSHeapSize - memory.usedJSHeapSize;
            if (free > 2000 * 1024 * 1024) return 12;
            if (free > 1400 * 1024 * 1024) return 10;
            if (free > 800 * 1024 * 1024) return 8;
            if (free > 400 * 1024 * 1024) return 4;
            if (free > 160 * 1024 * 1024) return 3;
            return 1; // very constrained, stream one at a time
        }

        // Fallback: navigator.deviceMemory returns approximate GBs available to JS.
        const deviceMemory = (
            navigator as Navigator & { deviceMemory?: number }
        ).deviceMemory;
        if (deviceMemory) {
            if (deviceMemory >= 20) return 12;
            if (deviceMemory >= 16) return 10;
            if (deviceMemory >= 12) return 8;
            if (deviceMemory >= 6) return 4;
            if (deviceMemory >= 4) return 3;
            return 2;
        }
    } catch {
        // Ignore and fall back to defaults below.
    }

    return 3;
};

/**
 * Determine write queue depth; allow more buffering on capable devices.
 */
const getStreamZipWriteQueueLimit = () => {
    try {
        const memory = (
            performance as Performance & {
                memory?: { usedJSHeapSize: number; totalJSHeapSize: number };
            }
        ).memory;
        if (memory?.totalJSHeapSize && memory.usedJSHeapSize >= 0) {
            const free = memory.totalJSHeapSize - memory.usedJSHeapSize;
            if (free > 1200 * 1024 * 1024) return 64;
            if (free > 800 * 1024 * 1024) return 48;
            if (free > 400 * 1024 * 1024) return 32;
        }

        const deviceMemory = (
            navigator as Navigator & { deviceMemory?: number }
        ).deviceMemory;
        if (deviceMemory) {
            if (deviceMemory >= 16) return 64;
            if (deviceMemory >= 12) return 48;
            if (deviceMemory >= 8) return 32;
        }
    } catch {
        // fall back
    }
    return STREAM_ZIP_BASE_WRITE_QUEUE_LIMIT;
};

/** Allow more entry streams on capable devices, coupled to prep concurrency. */
const getStreamZipEntryConcurrency = (prepConcurrency: number) => {
    const clamp = (value: number) =>
        Math.max(2, Math.min(value, STREAM_ZIP_MAX_CONCURRENCY));
    try {
        const memory = (
            performance as Performance & {
                memory?: { usedJSHeapSize: number; totalJSHeapSize: number };
            }
        ).memory;
        if (memory?.totalJSHeapSize && memory.usedJSHeapSize >= 0) {
            const free = memory.totalJSHeapSize - memory.usedJSHeapSize;
            if (free > 2400 * 1024 * 1024) return clamp(12);
            if (free > 1600 * 1024 * 1024) return clamp(10);
            if (free > 1000 * 1024 * 1024) return clamp(8);
            if (free > 600 * 1024 * 1024)
                return clamp(Math.max(prepConcurrency + 2, 6));
            if (free > 300 * 1024 * 1024)
                return clamp(Math.max(prepConcurrency + 1, 4));
        }

        const deviceMemory = (
            navigator as Navigator & { deviceMemory?: number }
        ).deviceMemory;
        if (deviceMemory) {
            if (deviceMemory >= 20) return clamp(12);
            if (deviceMemory >= 16) return clamp(10);
            if (deviceMemory >= 12) return clamp(8);
            if (deviceMemory >= 8)
                return clamp(Math.max(prepConcurrency + 2, 6));
            if (deviceMemory >= 6)
                return clamp(Math.max(prepConcurrency + 1, 4));
        }
    } catch {
        // fall back
    }
    return clamp(Math.max(prepConcurrency, 3));
};

/**
 * Create a writable stream for desktop app using native filesystem via Electron.
 * Uses TransformStream to bridge ZIP writes to native file streaming.
 */
const createNativeZipWritable = (
    electron: Electron,
    filePath: string,
): WritableStreamHandle => {
    const transform = new TransformStream<Uint8Array, Uint8Array>();
    const writer = transform.writable.getWriter();

    const writePromise = writeStream(electron, filePath, transform.readable);

    const close = async () => {
        await writer.close();
        await writePromise;
    };

    const abort = () => {
        void writer.abort().catch(() => undefined);
    };

    return {
        stream: new WritableStream<Uint8Array>({
            write: (chunk) => writer.write(chunk),
            close,
            abort,
        }),
        close,
        abort,
    };
};

/**
 * Stream files to a ZIP archive using fflate.
 *
 * Downloads files with limited concurrency, writes them to ZIP in order using
 * ZipPassThrough (no compression). Live photos expand to image+video entries.
 * Failed files are retried, then skipped. Reports progress via callbacks.
 */
const streamFilesToZip = async ({
    files,
    title,
    signal,
    writable,
    onFileSuccess,
    onFileFailure,
}: StreamingZipOptions): Promise<StreamingZipResult> => {
    const zipName = zipFileName(title);
    const handle = writable ?? (await getWritableStreamForZip(zipName));

    if (handle === null) return "cancelled";
    if (!handle) return "unavailable";

    const { stream } = handle;
    const writer = stream.getWriter();
    const writeQueueLimit = getStreamZipWriteQueueLimit();

    let zipError: Error | undefined;
    let allowWrites = true;
    let writerClosed = false;
    let writerClosing = false;
    let shuttingDown = false;
    let writeChain = Promise.resolve();
    let writeQueueDepth = 0;

    const closeWriter = async () => {
        if (writerClosed || writerClosing) return;
        shuttingDown = true;
        writerClosing = true;
        try {
            await writer.close();
            writerClosed = true;
        } catch (e) {
            log.warn("Failed to close ZIP writer", e);
        }
    };

    const abortWriter = () => {
        if (writerClosed) return;
        shuttingDown = true;
        writerClosing = true;
        try {
            void writer.abort();
            writerClosed = true;
        } catch (e) {
            log.warn("Failed to abort ZIP writer", e);
        }
    };

    const isClosingError = (err: unknown) => {
        if (!(err instanceof Error)) return false;
        const msg = err.message.toLowerCase();
        return msg.includes("closing") || msg.includes("closed");
    };

    const flushWrites = async () => {
        let lastChain: Promise<void> | undefined;
        do {
            lastChain = writeChain;
            await lastChain;
        } while (lastChain !== writeChain);
    };

    const waitForWriteWindow = async () => {
        while (writeQueueDepth >= writeQueueLimit) {
            if (zipError) throw zipError;
            try {
                await writeChain;
            } catch {
                // zipError will be picked up on next loop
            }
        }
    };

    /** Queue write, serialize through promise chain, capture errors in zipError. */
    const enqueueWrite = async (data: Uint8Array) => {
        if (!allowWrites || writerClosed || writerClosing) return;
        await waitForWriteWindow();
        writeQueueDepth++;
        writeChain = writeChain
            .then(() => writer.write(data))
            .catch((e: unknown) => {
                if (shuttingDown && isClosingError(e)) return;
                zipError = e instanceof Error ? e : new Error(String(e));
                throw zipError;
            })
            .finally(() => {
                writeQueueDepth = Math.max(0, writeQueueDepth - 1);
            });
        return writeChain;
    };

    const zip = new Zip((err, data) => {
        if (err) {
            zipError = err instanceof Error ? err : new Error(String(err));
            return;
        }
        void enqueueWrite(data);
    });

    interface PreparedEntry {
        name: string;
        getData: () => Promise<Uint8Array | ReadableStream<Uint8Array>>;
    }

    interface PreparedFile {
        file: EnteFile;
        entries: PreparedEntry[];
        entryCount: number;
    }

    /** Download and prepare file for ZIP (decodes live photos to image+video). */
    const prepareFile = async (
        file: EnteFile,
    ): Promise<PreparedFile | null> => {
        try {
            const fileName = fileFileName(file);

            if (file.metadata.fileType === FileType.livePhoto) {
                const blob = await downloadManager.fileBlob(file);
                if (signal.aborted) return null;

                const { imageFileName, imageData, videoFileName, videoData } =
                    await decodeLivePhoto(fileName, blob);

                const dataToStream = (
                    data: Blob | ArrayBuffer | Uint8Array,
                ) => {
                    if (data instanceof Blob) {
                        return new Response(data).body;
                    }
                    const view =
                        data instanceof Uint8Array
                            ? data
                            : new Uint8Array(data);
                    return new ReadableStream<Uint8Array>({
                        pull(controller) {
                            controller.enqueue(view);
                            controller.close();
                        },
                        cancel() {
                            return Promise.resolve();
                        },
                    });
                };

                const entries: PreparedEntry[] = [
                    {
                        name: imageFileName,
                        getData: () => Promise.resolve(dataToStream(imageData)),
                    },
                    {
                        name: videoFileName,
                        getData: () => Promise.resolve(dataToStream(videoData)),
                    },
                ];

                return { file, entries, entryCount: 1 };
            }

            const getStream = async () => {
                const stream = await downloadManager.fileStream(file);
                if (!stream) throw new Error("Failed to get file stream");
                return stream;
            };

            return {
                file,
                entries: [{ name: fileName, getData: getStream }],
                entryCount: 1,
            };
        } catch (e) {
            onFileFailure(file, e);
            return null;
        }
    };

    const preparedPromises: Promise<PreparedFile | null>[] = [];
    const clampConcurrency = (value: number) =>
        Math.max(
            STREAM_ZIP_MIN_CONCURRENCY,
            Math.min(value, STREAM_ZIP_MAX_CONCURRENCY),
        );
    const clampEntryConcurrency = (value: number) =>
        Math.max(2, Math.min(value, STREAM_ZIP_MAX_CONCURRENCY));

    let targetConcurrency = clampConcurrency(getStreamZipConcurrency());
    let entryConcurrency = clampEntryConcurrency(
        getStreamZipEntryConcurrency(targetConcurrency),
    );
    let lastConcurrencyCheck = 0;
    let concurrencyCheckTimer: ReturnType<typeof setInterval> | undefined;

    const stopConcurrencyRefresh = () => {
        if (concurrencyCheckTimer) {
            clearInterval(concurrencyCheckTimer);
            concurrencyCheckTimer = undefined;
        }
    };

    const refreshConcurrency = (force = false) => {
        const now = Date.now();
        if (
            !force &&
            now - lastConcurrencyCheck < STREAM_ZIP_CONCURRENCY_REFRESH_MS
        )
            return targetConcurrency;
        lastConcurrencyCheck = now;
        const next = clampConcurrency(getStreamZipConcurrency());
        if (next !== targetConcurrency) {
            targetConcurrency = next;
            scheduleNext();
        }
        entryConcurrency = clampEntryConcurrency(
            getStreamZipEntryConcurrency(targetConcurrency),
        );
        return targetConcurrency;
    };

    const startConcurrencyRefresh = () => {
        if (typeof setInterval !== "function") return;
        concurrencyCheckTimer = setInterval(
            () => refreshConcurrency(true),
            STREAM_ZIP_CONCURRENCY_REFRESH_MS,
        );
    };

    let nextToSchedule = 0;
    let active = 0;

    /** Schedule next file prep if under concurrency limit. */
    const scheduleNext = () => {
        const allowed = refreshConcurrency();
        while (nextToSchedule < files.length && active < allowed) {
            const index = nextToSchedule++;
            const file = files[index]!;
            const promise = prepareFile(file).finally(() => {
                active--;
                scheduleNext();
            });
            preparedPromises[index] = promise;
            active++;
        }
    };

    startConcurrencyRefresh();
    scheduleNext();

    let lastCompletedIndex = -1;

    /** Add entry to ZIP with retries. Streams chunks to avoid buffering full files. */
    const addEntryToZipWithRetry = async (
        file: EnteFile,
        entry: PreparedEntry,
    ) => {
        let attempt = 0;
        while (attempt < STREAM_ZIP_MAX_RETRIES) {
            attempt++;
            try {
                const resolvedData = await entry.getData();
                const passThrough = new ZipPassThrough(entry.name);
                zip.add(passThrough);
                if (resolvedData instanceof ReadableStream) {
                    const reader = resolvedData.getReader();
                    let shouldCancel = true;
                    try {
                        while (true) {
                            const { done, value } = await reader.read();
                            if (done) break;
                            if (signal.aborted) {
                                void reader.cancel().catch(() => undefined);
                                throw new DOMException("Aborted", "AbortError");
                            }
                            await waitForWriteWindow();
                            passThrough.push(value);
                            if (zipError) throw zipError;
                        }
                        shouldCancel = false;
                    } finally {
                        if (shouldCancel) {
                            void reader.cancel().catch(() => undefined);
                        }
                    }
                } else {
                    await waitForWriteWindow();
                    passThrough.push(resolvedData);
                }

                await waitForWriteWindow();
                passThrough.push(new Uint8Array(0), true);

                await writeChain;
                if (zipError) throw zipError;
                return;
            } catch (e) {
                if (signal.aborted || attempt === STREAM_ZIP_MAX_RETRIES) {
                    throw e;
                }
                log.warn(
                    `Retrying stream for file ${file.id} (attempt ${attempt})`,
                    e,
                );
                await wait(STREAM_ZIP_RETRY_DELAY_MS * attempt);
            }
        }
    };

    const inFlightEntries = new Set<Promise<void>>();
    let entryFailure: unknown | null = null;

    const waitForEntrySlot = async () => {
        while (inFlightEntries.size >= entryConcurrency) {
            await Promise.race(inFlightEntries);
        }
    };

    const startEntry = (file: EnteFile, entry: PreparedEntry) => {
        let p: Promise<void>;
        p = addEntryToZipWithRetry(file, entry)
            .catch((e) => {
                entryFailure = entryFailure ?? e;
                throw e;
            })
            .finally(() => {
                inFlightEntries.delete(p);
            });
        inFlightEntries.add(p);
        return p;
    };

    const fileCompletions: Promise<void>[] = [];

    try {
        // Consume prepared files in order; preparation happens with limited concurrency
        for (let i = 0; i < files.length; i++) {
            if (signal.aborted) {
                abortWriter();
                stopConcurrencyRefresh();
                return "cancelled";
            }

            const preparedPromise = preparedPromises[i];
            if (!preparedPromise) {
                continue;
            }
            const prepared = await preparedPromise;
            const file = files[i]!;
            if (prepared && !signal.aborted) {
                const entryPromises: Promise<void>[] = [];
                for (const entry of prepared.entries) {
                    await waitForEntrySlot();
                    entryPromises.push(startEntry(file, entry));
                }
                fileCompletions.push(
                    Promise.all(entryPromises)
                        .then(() => onFileSuccess(file, prepared.entryCount))
                        .catch((e) => {
                            log.error(
                                `Failed to add file ${file.id} to ZIP`,
                                e,
                            );
                            onFileFailure(file, e);
                        }),
                );
            }

            if (zipError) {
                throw zipError;
            }
        }

        // Drain remaining in-flight entry writes and file completions
        if (inFlightEntries.size) {
            await Promise.allSettled([...inFlightEntries]);
        }
        if (fileCompletions.length) {
            await Promise.allSettled(fileCompletions);
        }
        lastCompletedIndex = files.length - 1;
        if (entryFailure) {
            throw entryFailure;
        }

        // Finalize the ZIP
        zip.end();

        // Wait for all pending writes to flush and close the writer
        await flushWrites();
        if (zipError) throw zipError;

        allowWrites = false;

        await closeWriter();
        stopConcurrencyRefresh();

        return "success";
    } catch (e) {
        if (!signal.aborted) {
            // Mark any remaining files as failed so counts stay consistent
            for (let i = lastCompletedIndex + 1; i < files.length; i++) {
                const file = files[i]!;
                onFileFailure(file, e);
            }
        }

        log.error("Streaming ZIP creation failed", e);
        abortWriter();
        stopConcurrencyRefresh();
        return signal.aborted ? "cancelled" : "error";
    }
};
