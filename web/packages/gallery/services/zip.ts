import log from "ente-base/log";
import { type Electron } from "ente-base/types/ipc";
import { downloadManager } from "ente-gallery/services/download";
import { writeStream } from "ente-gallery/utils/native-stream";
import type { EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { decodeLivePhoto } from "ente-media/live-photo";
import { wait } from "ente-utils/promise";
import { Zip, ZipPassThrough } from "fflate";

/**
 * Replace invalid filesystem characters (\ / : * ? " < > |) with underscores.
 */
export const sanitizeZipFileName = (name: string) =>
    name.replace(/[\\/:*?"<>|]/g, "_").trim() || "ente-download";

/** Sanitize title and strip any existing .zip extension. */
export const baseZipName = (title: string) =>
    sanitizeZipFileName(title).replace(/\.zip$/i, "");

/** Generate ZIP filename, optionally with part number (e.g., "photos-part2.zip"). */
export const zipFileName = (title: string, part?: number) => {
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
export interface WritableStreamHandle {
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
export const getWritableStreamForZip = async (
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
        // StreamSaver uses CommonJS (module.exports = obj), so the actual object
        // may be in the default export depending on bundler interop. We need to
        // set mitm on the actual object, not on the module namespace, because
        // internal StreamSaver code references its own internal streamSaver.mitm.
        type StreamSaverModule = typeof import("streamsaver");
        const streamSaverModule: StreamSaverModule & { default?: StreamSaverModule } =
            await import("streamsaver");
        const streamSaver = streamSaverModule.default ?? streamSaverModule;

        // Configure StreamSaver to use our self-hosted mitm.html instead of the
        // external jimmywarting.github.io endpoint. This avoids cross-origin issues
        // and ensures the service worker is served from the same origin.
        streamSaver.mitm = "/streamsaver/mitm.html";

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
export interface StreamingZipOptions {
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
export type StreamingZipResult =
    | "success"
    | "cancelled"
    | "error"
    | "unavailable";

const STREAM_ZIP_MIN_CONCURRENCY = 2;
const STREAM_ZIP_MAX_CONCURRENCY = 24;
const STREAM_ZIP_MAX_RETRIES = 3;
const STREAM_ZIP_CONCURRENCY_REFRESH_MS = 600;
const STREAM_ZIP_BASE_WRITE_QUEUE_LIMIT = 24;
/** Base retry delay (multiplied by attempt number for backoff). */
const STREAM_ZIP_RETRY_DELAY_MS = 400;

/**
 * Determine optimal concurrency based on available memory.
 * Uses performance.memory (Chrome) or navigator.deviceMemory, defaults to 4.
 *
 * Note: navigator.deviceMemory is capped at 8 GB max by browsers for privacy.
 */
const getStreamZipConcurrency = () => {
    let method = "default";
    let detectedValue: number | string = "none";
    let concurrency = 4;

    try {
        // Chrome provides heap info; use jsHeapSizeLimit for actual available memory.
        const memory = (
            performance as Performance & {
                memory?: { usedJSHeapSize: number; jsHeapSizeLimit: number };
            }
        ).memory;
        if (memory?.jsHeapSizeLimit && memory.usedJSHeapSize >= 0) {
            const free = memory.jsHeapSizeLimit - memory.usedJSHeapSize;
            const freeMB = Math.round(free / (1024 * 1024));
            method = "performance.memory";
            detectedValue = `${freeMB} MB free`;
            if (free > 4000 * 1024 * 1024)
                concurrency = 24; // >4 GB free
            else if (free > 3000 * 1024 * 1024)
                concurrency = 20; // >3 GB free
            else if (free > 2000 * 1024 * 1024)
                concurrency = 16; // >2 GB free
            else if (free > 1200 * 1024 * 1024)
                concurrency = 12; // >1.2 GB free
            else if (free > 800 * 1024 * 1024)
                concurrency = 10; // >800 MB free
            else if (free > 400 * 1024 * 1024)
                concurrency = 6; // >400 MB free
            else if (free > 200 * 1024 * 1024)
                concurrency = 4; // >200 MB free
            else concurrency = 2; // constrained
            log.info(
                `ZIP concurrency: ${concurrency} (${method}: ${detectedValue})`,
            );
            return concurrency;
        }

        // Fallback: navigator.deviceMemory returns approximate GBs (capped at 8 max).
        const deviceMemory = (
            navigator as Navigator & { deviceMemory?: number }
        ).deviceMemory;
        if (deviceMemory) {
            method = "deviceMemory";
            detectedValue = `${deviceMemory} GB`;
            // deviceMemory is capped at 8 GB by browsers for privacy
            if (deviceMemory >= 8)
                concurrency = 20; // 8 GB (max reported)
            else if (deviceMemory >= 4)
                concurrency = 12; // 4 GB
            else if (deviceMemory >= 2)
                concurrency = 8; // 2 GB
            else if (deviceMemory >= 1)
                concurrency = 4; // 1 GB
            else concurrency = 2; // <1 GB
            log.info(
                `ZIP concurrency: ${concurrency} (${method}: ${detectedValue})`,
            );
            return concurrency;
        }
    } catch (e) {
        log.warn("Failed to detect memory for ZIP concurrency", e);
    }

    log.info(`ZIP concurrency: ${concurrency} (${method})`);
    return concurrency;
};

/**
 * Determine write queue depth; allow more buffering on capable devices.
 *
 * Detection priority:
 * 1. performance.memory - Chrome/Edge/Electron (real-time heap info)
 * 2. navigator.deviceMemory - Chrome/Edge fallback (capped at 8 GB by browsers)
 * 3. navigator.hardwareConcurrency - Firefox/Safari fallback (CPU cores)
 * 4. Default - STREAM_ZIP_BASE_WRITE_QUEUE_LIMIT (24)
 */
const getStreamZipWriteQueueLimit = () => {
    let method = "default";
    let detectedValue: number | string = "none";
    let limit = STREAM_ZIP_BASE_WRITE_QUEUE_LIMIT;

    try {
        // Priority 1: Chrome/Edge/Electron - use jsHeapSizeLimit for actual available memory
        const memory = (
            performance as Performance & {
                memory?: { usedJSHeapSize: number; jsHeapSizeLimit: number };
            }
        ).memory;
        if (memory?.jsHeapSizeLimit && memory.usedJSHeapSize >= 0) {
            const free = memory.jsHeapSizeLimit - memory.usedJSHeapSize;
            const freeMB = Math.round(free / (1024 * 1024));
            method = "performance.memory";
            detectedValue = `${freeMB} MB free`;
            if (free > 4000 * 1024 * 1024) {
                limit = 192; // >4 GB free
            } else if (free > 3000 * 1024 * 1024) {
                limit = 160; // >3 GB free
            } else if (free > 2000 * 1024 * 1024) {
                limit = 128; // >2 GB free
            } else if (free > 1200 * 1024 * 1024) {
                limit = 96; // >1.2 GB free
            } else if (free > 800 * 1024 * 1024) {
                limit = 64; // >800 MB free
            } else if (free > 400 * 1024 * 1024) {
                limit = 48; // >400 MB free
            } else if (free > 200 * 1024 * 1024) {
                limit = 32; // >200 MB free
            }
            log.info(`ZIP write queue: ${limit} (${method}: ${detectedValue})`);
            return limit;
        }

        // Priority 2: Chrome/Edge fallback - deviceMemory is capped at 8 GB max
        const deviceMemory = (
            navigator as Navigator & { deviceMemory?: number }
        ).deviceMemory;
        if (deviceMemory) {
            method = "deviceMemory";
            detectedValue = `${deviceMemory} GB`;
            // deviceMemory is capped at 8 GB by browsers for privacy
            if (deviceMemory >= 8) {
                limit = 160; // 8 GB (max reported)
            } else if (deviceMemory >= 4) {
                limit = 96; // 4 GB
            } else if (deviceMemory >= 2) {
                limit = 64; // 2 GB
            } else if (deviceMemory >= 1) {
                limit = 48; // 1 GB
            } else {
                limit = 32; // <1 GB
            }
            log.info(`ZIP write queue: ${limit} (${method}: ${detectedValue})`);
            return limit;
        }

        // Priority 3: Firefox/Safari fallback - use CPU cores as capability proxy
        const cores = navigator.hardwareConcurrency;
        if (cores) {
            method = "hardwareConcurrency";
            detectedValue = `${cores} cores`;
            if (cores >= 24) {
                limit = 160; // >=24 cores (high-end workstation)
            } else if (cores >= 16) {
                limit = 128; // >=16 cores
            } else if (cores >= 12) {
                limit = 96; // >=12 cores
            } else if (cores >= 8) {
                limit = 64; // >=8 cores
            } else if (cores >= 4) {
                limit = 48; // >=4 cores
            } else {
                limit = 32; // <4 cores
            }
            log.info(`ZIP write queue: ${limit} (${method}: ${detectedValue})`);
            return limit;
        }
    } catch (e) {
        log.warn("Failed to detect memory/CPU for ZIP queue limit", e);
    }

    // Priority 4: Default for constrained/unknown environments
    log.info(`ZIP write queue: ${limit} (${method})`);
    return limit;
};

/**
 * Create a writable stream for desktop app using native filesystem via Electron.
 * Uses TransformStream to bridge ZIP writes to native file streaming.
 */
export const createNativeZipWritable = (
    electron: Electron,
    filePath: string,
): WritableStreamHandle => {
    const transform = new TransformStream<Uint8Array, Uint8Array>();
    const writer = transform.writable.getWriter();

    // Track if native write stream has failed so we can fail fast on subsequent writes
    let streamError: Error | undefined;
    let aborted = false;

    const writePromise = writeStream(electron, filePath, transform.readable);

    // Monitor writePromise for failures - if native stream fails, capture error immediately
    // so we stop accumulating data in memory
    writePromise.catch((e: unknown) => {
        streamError = e instanceof Error ? e : new Error(String(e));
        // Abort the writer to stop any pending writes from queuing more data
        if (!aborted) {
            aborted = true;
            void writer.abort(streamError).catch(() => undefined);
        }
    });

    const close = async () => {
        // Check for stream error before closing
        if (streamError) throw streamError;
        await writer.close();
        await writePromise;
    };

    const abort = () => {
        if (aborted) return;
        aborted = true;
        void writer.abort().catch(() => undefined);
    };

    return {
        stream: new WritableStream<Uint8Array>({
            write: async (chunk) => {
                // Fail fast if native stream has already failed
                if (streamError) throw streamError;
                if (aborted) throw new Error("Stream aborted");
                return writer.write(chunk);
            },
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
export const streamFilesToZip = async ({
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
                ): ReadableStream<Uint8Array> => {
                    if (data instanceof Blob) {
                        const body = new Response(data).body;
                        if (!body) {
                            throw new Error("Failed to create blob stream");
                        }
                        return body;
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

    let targetConcurrency = clampConcurrency(getStreamZipConcurrency());
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

    // Track ZIP entry state for salvage logic on error.
    // If all started entries are complete, we can finalize the ZIP cleanly.
    let entriesAddedToZip = 0;
    let entriesCompletedInZip = 0;

    /**
     * Add entry to ZIP. Retries only the data fetch, NOT the ZIP write.
     *
     * IMPORTANT: Once zip.add() is called, we cannot retry without corrupting
     * the ZIP (each retry would add a duplicate incomplete entry). So retries
     * only happen for getData(), and any failure after zip.add() is final.
     */
    const addEntryToZip = async (_file: EnteFile, entry: PreparedEntry) => {
        // Phase 1: Get data with retries (safe to retry - ZIP not modified yet)
        let resolvedData: Uint8Array | ReadableStream<Uint8Array> | undefined;
        let lastError: unknown;

        for (let attempt = 1; attempt <= STREAM_ZIP_MAX_RETRIES; attempt++) {
            try {
                resolvedData = await entry.getData();
                break;
            } catch (e) {
                lastError = e;
                if (signal.aborted) throw e;
                if (attempt < STREAM_ZIP_MAX_RETRIES) {
                    log.warn(
                        `Retrying getData for ${entry.name} (attempt ${attempt})`,
                        e,
                    );
                    await wait(STREAM_ZIP_RETRY_DELAY_MS * attempt);
                }
            }
        }

        if (resolvedData === undefined) {
            throw lastError ?? new Error("Failed to get entry data");
        }

        // Phase 2: Write to ZIP (NO retries - would corrupt ZIP with duplicates)
        const passThrough = new ZipPassThrough(entry.name);
        zip.add(passThrough);
        entriesAddedToZip++;

        // Stream or write the data
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

        // Finalize this entry
        await waitForWriteWindow();
        passThrough.push(new Uint8Array(0), true);

        await writeChain;
        if (zipError) throw zipError;
        entriesCompletedInZip++;
    };

    const inFlightEntries = new Set<Promise<void>>();
    let entryFailure: unknown = null;

    const waitForEntrySlot = async () => {
        while (inFlightEntries.size >= targetConcurrency) {
            await Promise.race(inFlightEntries);
        }
    };

    const startEntry = (file: EnteFile, entry: PreparedEntry) => {
        const p: Promise<void> = addEntryToZip(file, entry)
            .catch((e: unknown) => {
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
            if (prepared) {
                const entryPromises: Promise<void>[] = [];
                for (const entry of prepared.entries) {
                    await waitForEntrySlot();
                    entryPromises.push(startEntry(file, entry));
                }
                fileCompletions.push(
                    Promise.all(entryPromises)
                        .then(() => onFileSuccess(file, prepared.entryCount))
                        .catch((e: unknown) => {
                            log.error(
                                `Failed to add file ${file.id} to ZIP`,
                                e,
                            );
                            onFileFailure(file, e);
                        }),
                );
            }

            // Track that this file's preparation is complete (success or failure)
            // so the catch block won't double-count it
            lastCompletedIndex = i;

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
            throw entryFailure instanceof Error
                ? entryFailure
                : new Error(JSON.stringify(entryFailure));
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
        // Wait for any in-flight entries to settle before checking salvage condition.
        // This ensures entriesAddedToZip and entriesCompletedInZip are accurate.
        if (inFlightEntries.size) {
            await Promise.allSettled([...inFlightEntries]);
        }

        if (!signal.aborted) {
            // Mark any remaining files as failed so counts stay consistent
            for (let i = lastCompletedIndex + 1; i < files.length; i++) {
                const file = files[i]!;
                onFileFailure(file, e);
            }
        }

        log.error("Streaming ZIP creation failed", e);
        stopConcurrencyRefresh();

        // Try to salvage the ZIP if all started entries are complete.
        // This produces a valid partial ZIP with successfully downloaded files.
        if (
            !signal.aborted &&
            entriesAddedToZip > 0 &&
            entriesAddedToZip === entriesCompletedInZip
        ) {
            log.info(
                `Attempting to salvage ZIP with ${entriesCompletedInZip} complete entries`,
            );
            try {
                zip.end();
                await flushWrites();
                allowWrites = false;
                await closeWriter();
                log.info("ZIP salvaged successfully");
                return "error";
            } catch (salvageError) {
                log.warn("Failed to salvage ZIP", salvageError);
                abortWriter();
            }
        } else {
            if (entriesAddedToZip !== entriesCompletedInZip) {
                log.info(
                    `Cannot salvage ZIP: ${entriesAddedToZip - entriesCompletedInZip} entries incomplete`,
                );
            }
            abortWriter();
        }

        return signal.aborted ? "cancelled" : "error";
    }
};
