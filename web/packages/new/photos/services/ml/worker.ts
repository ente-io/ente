import { clientPackageName } from "@/base/app";
import { isHTTP4xxError } from "@/base/http";
import { getKVN } from "@/base/kv";
import { ensureAuthToken } from "@/base/local-user";
import log from "@/base/log";
import type { EnteFile } from "@/new/photos/types/file";
import { fileLogID } from "@/new/photos/utils/file";
import { ensure } from "@/utils/ensure";
import { wait } from "@/utils/promise";
import { DOMParser } from "@xmldom/xmldom";
import { expose } from "comlink";
import { z } from "zod";
import downloadManager from "../download";
import { cmpNewLib2, extractRawExif } from "../exif";
import { getAllLocalFiles, getLocalTrashedFiles } from "../files";
import type { UploadItem } from "../upload/types";
import {
    imageBitmapAndData,
    indexableBlobs,
    type ImageBitmapAndData,
} from "./blob";
import { clipIndexingVersion, indexCLIP, type CLIPIndex } from "./clip";
import { saveFaceCrops } from "./crop";
import {
    indexableFileIDs,
    markIndexingFailed,
    saveIndexes,
    updateAssumingLocalFiles,
} from "./db";
import {
    fetchDerivedData,
    putDerivedData,
    type RemoteDerivedData,
} from "./embedding";
import { faceIndexingVersion, indexFaces, type FaceIndex } from "./face";
import type { MLWorkerDelegate, MLWorkerElectron } from "./worker-types";

const idleDurationStart = 5; /* 5 seconds */
const idleDurationMax = 16 * 60; /* 16 minutes */

interface IndexableItem {
    /** The {@link EnteFile} to index (potentially). */
    enteFile: EnteFile;
    /** If the file was uploaded from the current client, then its contents. */
    uploadItem: UploadItem | undefined;
    /** The existing derived data on remote corresponding to this file. */
    remoteDerivedData: RemoteDerivedData | undefined;
}

/**
 * The port used to communicate with the Node.js ML worker process
 *
 * See: [Note: ML IPC]
 * */
let _port: MessagePort | undefined;

globalThis.onmessage = (event: MessageEvent) => {
    if (event.data == "createMLWorker/port") {
        _port = event.ports[0];
        _port?.start();
    }
};

const IPCResponse = z.object({
    id: z.number(),
    data: z.any(),
});

/**
 * Our hand-rolled IPC handler and router - the web worker end.
 *
 * Sibling of the handleMessage function (in `ml-worker.ts`) in the desktop app.
 */
const electronMLWorker = async (type: string, data: string) => {
    const port = ensure(_port);
    // Generate a unique nonce to identify this RPC interaction.
    const id = Math.random();
    return new Promise((resolve) => {
        const handleMessage = (event: MessageEvent) => {
            const response = IPCResponse.parse(event.data);
            if (response.id != id) return;
            port.removeEventListener("message", handleMessage);
            resolve(response.data);
        };
        port.addEventListener("message", handleMessage);
        port.postMessage({ type, id, data });
    });
};

/**
 * Run operations related to machine learning (e.g. indexing) in a Web Worker.
 *
 * This is a normal class that is however exposed (via comlink) as a proxy
 * running inside a Web Worker. This way, we do not bother the main thread with
 * tasks that might degrade interactivity.
 *
 * Conceptually, the MLWorker state machine is as follows:
 *
 *     ext. event      state           then state
 *    ------------- --------------- --------------
 *     sync         -> "backfillq"  -> "idle"
 *     upload       -> "liveq"      -> "idle"
 *     idleTimeout  -> "backfillq"  -> "idle"
 *
 * where:
 *
 * -   "liveq": indexing items that are being uploaded,
 * -   "backfillq": fetching remote embeddings of unindexed items, and then
 *     indexing them if needed,
 * -   "idle": in between state transitions.
 */
export class MLWorker {
    private electron: MLWorkerElectron | undefined;
    private delegate: MLWorkerDelegate | undefined;
    private state: "idle" | "indexing" = "idle";
    private liveQ: IndexableItem[] = [];
    private idleTimeout: ReturnType<typeof setTimeout> | undefined;
    private idleDuration = idleDurationStart; /* unit: seconds */

    /**
     * Initialize a new {@link MLWorker}.
     *
     * This is conceptually the constructor, however it is easier to have this
     * as a separate function to avoid complicating the comlink types further.
     *
     * @param electron The {@link MLWorkerElectron} that allows the worker to
     * use the functionality provided by our Node.js layer when running in the
     * context of our desktop app.
     *
     * @param delegate The {@link MLWorkerDelegate} the worker can use to inform
     * the main thread of interesting events.
     */
    async init(electron: MLWorkerElectron, delegate?: MLWorkerDelegate) {
        this.electron = electron;
        this.delegate = delegate;
        // Initialize the downloadManager running in the web worker with the
        // user's token. It'll be used to download files to index if needed.
        await downloadManager.init(await ensureAuthToken());

        // Normally, DOMParser is available to web code, so our Exif library
        // (ExifReader) has an optional dependency on the the non-browser
        // alternative DOMParser provided by @xmldom/xmldom.
        //
        // But window.DOMParser is not available to web workers.
        //
        // So we need to get ExifReader to use the @xmldom/xmldom version.
        // ExifReader references it using the following code:
        //
        //     __non_webpack_require__('@xmldom/xmldom')
        //
        // So we need to explicitly reference it to ensure that it does not get
        // tree shaken by webpack. But ensuring it is part of the bundle does
        // not seem to work (for reasons I don't yet understand), so we also
        // need to monkey patch it (This also ensures that it is not tree
        // shaken).
        globalThis.DOMParser = DOMParser;

        void (async () => {
            console.log("yyy calling foo with 3");
            const res = await electronMLWorker("foo", "3");
            console.log("yyy calling foo with 3 result", res);
        })();
    }

    /**
     * Start backfilling if needed.
     *
     * This function enqueues a backfill attempt and returns immediately without
     * waiting for it complete. During a backfill, it will first attempt to
     * fetch embeddings for files which don't have that data locally. If we
     * fetch and find what we need, we save it locally. Otherwise we index them.
     */
    sync() {
        this.wakeUp();
    }

    /** Invoked in response to external events. */
    private wakeUp() {
        if (this.state == "idle") {
            // Currently paused. Get back to work.
            if (this.idleTimeout) clearTimeout(this.idleTimeout);
            this.idleTimeout = undefined;
            void this.tick();
        } else {
            // In the middle of a task. Do nothing, `this.tick` will
            // automatically be invoked when the current task finishes.
        }
    }

    /**
     * Called when a file is uploaded from the current client.
     *
     * This is a great opportunity to index since we already have the in-memory
     * representation of the file's contents with us and won't need to download
     * the file from remote.
     */
    onUpload(enteFile: EnteFile, uploadItem: UploadItem) {
        // Add the recently uploaded file to the live indexing queue.
        //
        // Limit the queue to some maximum so that we don't keep growing
        // indefinitely (and cause memory pressure) if the speed of uploads is
        // exceeding the speed of indexing.
        //
        // In general, we can be sloppy with the items in the live queue (as
        // long as we're not systematically ignoring it). This is because the
        // live queue is just an optimization: if a file doesn't get indexed via
        // the live queue, it'll later get indexed anyway when we backfill.
        if (this.liveQ.length < 200) {
            // The file is just being uploaded, and so will not have any
            // pre-existing derived data on remote.
            const remoteDerivedData = undefined;
            this.liveQ.push({ enteFile, uploadItem, remoteDerivedData });
            this.wakeUp();
        } else {
            log.debug(() => "Ignoring upload item since liveQ is full");
        }
    }

    /**
     * Return true if we're currently indexing.
     */
    isIndexing() {
        return this.state == "indexing";
    }

    private async tick() {
        log.debug(() => [
            "ml/tick",
            {
                state: this.state,
                liveQ: this.liveQ,
                idleDuration: this.idleDuration,
            },
        ]);

        const scheduleTick = () => void setTimeout(() => this.tick(), 0);

        const liveQ = this.liveQ;
        this.liveQ = [];
        this.state = "indexing";

        // Use the liveQ if present, otherwise get the next batch to backfill.
        const items = liveQ.length > 0 ? liveQ : await this.backfillQ();

        const allSuccess = await indexNextBatch(
            items,
            ensure(this.electron),
            this.delegate,
        );
        if (allSuccess) {
            // Everything is running smoothly. Reset the idle duration.
            this.idleDuration = idleDurationStart;
            // And tick again.
            scheduleTick();
            return;
        }

        // We come here in three scenarios - either there is nothing left to do,
        // or we cannot currently do it (e.g. user is offline), or we
        // encountered failures during indexing.
        //
        // Failures are not really expected, so something unexpected might be
        // going on, or remote might be having issues.
        //
        // So in all cases, we pause for exponentially longer durations of time
        // (limited to some maximum).

        this.state = "idle";
        this.idleDuration = Math.min(this.idleDuration * 2, idleDurationMax);
        this.idleTimeout = setTimeout(scheduleTick, this.idleDuration * 1000);
    }

    /** Return the next batch of items to backfill (if any). */
    async backfillQ() {
        const userID = ensure(await getKVN("userID"));
        // Find files that our local DB thinks need syncing.
        const filesByID = await syncWithLocalFilesAndGetFilesToIndex(
            userID,
            200,
        );
        if (!filesByID.size) return [];
        // Fetch their existing derived data (if any).
        const derivedDataByID = await fetchDerivedData(filesByID);
        // Return files after annotating them with their existing derived data.
        return Array.from(filesByID, ([id, file]) => ({
            enteFile: file,
            uploadItem: undefined,
            remoteDerivedData: derivedDataByID.get(id),
        }));
    }
}

expose(MLWorker);

/**
 * Find out files which need to be indexed. Then index the next batch of them.
 *
 * Returns `false` to indicate that either an error occurred, or there are no
 * more files to process, or that we cannot currently process files.
 *
 * Which means that when it returns true, all is well and there are more
 * things pending to process, so we should chug along at full speed.
 */
const indexNextBatch = async (
    items: IndexableItem[],
    electron: MLWorkerElectron,
    delegate: MLWorkerDelegate | undefined,
) => {
    // Don't try to index if we wouldn't be able to upload them anyway. The
    // liveQ has already been drained, but that's fine, it'll be rare that we
    // were able to upload just a bit ago but don't have network now.
    if (!self.navigator.onLine) {
        log.info("Skipping ML indexing since we are not online");
        return false;
    }

    // Nothing to do.
    if (items.length == 0) return false;

    // Index, keeping track if any of the items failed.
    let allSuccess = true;
    for (const item of items) {
        try {
            await index(item, electron);
            delegate?.workerDidProcessFile();
            // Possibly unnecessary, but let us drain the microtask queue.
            await wait(0);
        } catch (e) {
            log.warn(`Skipping unindexable file ${item.enteFile.id}`, e);
            allSuccess = false;
        }
    }

    // Return true if nothing failed.
    return allSuccess;
};

/**
 * Sync face DB with the local (and potentially indexable) files that we know
 * about. Then return the next {@link count} files that still need to be
 * indexed.
 *
 * For specifics of what a "sync" entails, see {@link updateAssumingLocalFiles}.
 *
 * @param userID Sync only files owned by a {@link userID} with the face DB.
 *
 * @param count Limit the resulting list of indexable files to {@link count}.
 */
const syncWithLocalFilesAndGetFilesToIndex = async (
    userID: number,
    count: number,
): Promise<Map<number, EnteFile>> => {
    const isIndexable = (f: EnteFile) => f.ownerID == userID;

    const localFiles = await getAllLocalFiles();
    const localFilesByID = new Map(
        localFiles.filter(isIndexable).map((f) => [f.id, f]),
    );

    const localTrashFileIDs = (await getLocalTrashedFiles()).map((f) => f.id);

    await updateAssumingLocalFiles(
        Array.from(localFilesByID.keys()),
        localTrashFileIDs,
    );

    const fileIDsToIndex = await indexableFileIDs(count);
    return new Map(
        fileIDsToIndex.map((id) => [id, ensure(localFilesByID.get(id))]),
    );
};

/**
 * Index file, save the persist the results locally, and put them on remote.
 *
 * [Note: ML indexing does more ML]
 *
 * Nominally, and primarily, indexing a file involves computing its various ML
 * embeddings: faces and CLIP. However, since this is a occasion where we have
 * the original file in memory, it is a great time to also compute other derived
 * data related to the file (instead of re-downloading it again).
 *
 * So this function also does things that are not related to ML and/or indexing:
 *
 * -   Extracting Exif.
 * -   Saving face crops.
 *
 * ---
 *
 * [Note: Transient and permanent indexing failures]
 *
 * We mark indexing for a file as having failed only if there is a good chance
 * that the indexing failed because of some inherent issue with that particular
 * file, and not if there were generic failures (like when trying to save the
 * indexes to remote).
 *
 * When we mark it as failed, then a flag is persisted corresponding to this
 * file in the ML DB so that it won't get reindexed in future runs. This are
 * thus considered as permanent failures.
 *
 * > We might retry these in future versions if we identify reasons for indexing
 * > to fail (it ideally shouldn't) and rectify them.
 *
 * On the other hand, saving the face index to remote might fail for transient
 * issues (network issues, or remote having hiccups). We don't mark a file as
 * failed permanently in such cases, so that it gets retried at some point.
 * These are considered as transient failures.
 *
 * However, it is vary hard to pre-emptively enumerate all possible failure
 * modes, and there is a the possibility of some non-transient failure getting
 * classified as a transient failure and causing the client to try and index the
 * same file again and again, when in fact there is a issue specific to that
 * file which is preventing the index from being saved. What exactly? We don't
 * know, but the possibility exists.
 *
 * To reduce the chances of this happening, we treat HTTP 4xx responses as
 * permanent failures too - there are no known cases where a client retrying a
 * 4xx response would work, and there are expected (but rare) cases where a
 * client might get a non-retriable 4xx (e.g. if the file has over ~700 faces,
 * then remote will return a 413 Request Entity Too Large).
 */
const index = async (
    { enteFile, uploadItem, remoteDerivedData }: IndexableItem,
    electron: MLWorkerElectron,
) => {
    const f = fileLogID(enteFile);
    const fileID = enteFile.id;

    // Massage the existing data (if any) that we got from remote to the form
    // that the rest of this function operates on.
    //
    // Discard any existing data that is made by an older indexing pipelines.
    // See: [Note: Embedding versions]

    const existingRemoteFaceIndex = remoteDerivedData?.parsed?.face;
    const existingRemoteCLIPIndex = remoteDerivedData?.parsed?.clip;

    // exif is expected to be a JSON object in the shape of RawExifTags, but
    // this function don't care what's inside it and can just treat it as an
    // opaque blob.
    const existingExif = remoteDerivedData?.raw.exif;
    const hasExistingExif = existingExif !== undefined && existingExif !== null;

    let existingFaceIndex: FaceIndex | undefined;
    if (
        existingRemoteFaceIndex &&
        existingRemoteFaceIndex.version >= faceIndexingVersion
    ) {
        const { width, height, faces } = existingRemoteFaceIndex;
        existingFaceIndex = { width, height, faces };
    }

    let existingCLIPIndex: CLIPIndex | undefined;
    if (
        existingRemoteCLIPIndex &&
        existingRemoteCLIPIndex.version >= clipIndexingVersion
    ) {
        const { embedding } = existingRemoteCLIPIndex;
        existingCLIPIndex = { embedding };
    }

    // See if we already have all the derived data fields that we need. If so,
    // just update our local db and return.

    if (existingFaceIndex && existingCLIPIndex && hasExistingExif) {
        try {
            await saveIndexes(
                { fileID, ...existingFaceIndex },
                { fileID, ...existingCLIPIndex },
            );
        } catch (e) {
            log.error(`Failed to save indexes for ${f}`, e);
            throw e;
        }
        return;
    }

    // There is at least one derived data type that still needs to be indexed.

    // Videos will not have an original blob whilst having a renderable blob.
    const { originalImageBlob, renderableBlob } = await indexableBlobs(
        enteFile,
        uploadItem,
        electron,
    );

    let image: ImageBitmapAndData;
    try {
        image = await imageBitmapAndData(renderableBlob);
    } catch (e) {
        // If we cannot get the raw image data for the file, then retrying again
        // won't help (if in the future we enhance the underlying code for
        // `indexableBlobs` to handle this failing type we can trigger a
        // reindexing attempt for failed files).
        //
        // See: [Note: Transient and permanent indexing failures]
        log.error(`Failed to get image data for indexing ${f}`, e);
        await markIndexingFailed(enteFile.id);
        throw e;
    }

    try {
        let faceIndex: FaceIndex;
        let clipIndex: CLIPIndex;
        let exif: unknown;

        const startTime = Date.now();

        try {
            [faceIndex, clipIndex, exif] = await Promise.all([
                existingFaceIndex ?? indexFaces(enteFile, image, electron),
                existingCLIPIndex ?? indexCLIP(image, electron),
                existingExif ??
                    (originalImageBlob
                        ? extractRawExif(originalImageBlob)
                        : undefined),
            ]);
        } catch (e) {
            // See: [Note: Transient and permanent indexing failures]
            log.error(`Failed to index ${f}`, e);
            await markIndexingFailed(enteFile.id);
            throw e;
        }

        if (originalImageBlob && exif)
            await cmpNewLib2(enteFile, originalImageBlob, exif);

        log.debug(() => {
            const ms = Date.now() - startTime;
            const msg = [];
            if (!existingFaceIndex) msg.push(`${faceIndex.faces.length} faces`);
            if (!existingCLIPIndex) msg.push("clip");
            if (!hasExistingExif && originalImageBlob) msg.push("exif");
            return `Indexed ${msg.join(" and ")} in ${f} (${ms} ms)`;
        });

        const remoteFaceIndex = existingRemoteFaceIndex ?? {
            version: faceIndexingVersion,
            client: clientPackageName,
            ...faceIndex,
        };

        const remoteCLIPIndex = existingRemoteCLIPIndex ?? {
            version: clipIndexingVersion,
            client: clientPackageName,
            ...clipIndex,
        };

        // Perform an "upsert" by using the existing raw data we got from the
        // remote as the base, and inserting or overwriting any newly indexed
        // parts. See: [Note: Preserve unknown derived data fields].

        const existingRawDerivedData = remoteDerivedData?.raw ?? {};
        const rawDerivedData = {
            ...existingRawDerivedData,
            face: remoteFaceIndex,
            clip: remoteCLIPIndex,
            exif,
        };

        log.debug(() => ["Uploading derived data", rawDerivedData]);

        try {
            await putDerivedData(enteFile, rawDerivedData);
        } catch (e) {
            // See: [Note: Transient and permanent indexing failures]
            log.error(`Failed to put derived data for ${f}`, e);
            if (isHTTP4xxError(e)) await markIndexingFailed(enteFile.id);
            throw e;
        }

        try {
            await saveIndexes(
                { fileID, ...faceIndex },
                { fileID, ...clipIndex },
            );
        } catch (e) {
            // Not sure if DB failures should be considered permanent or
            // transient. There isn't a known case where writing to the local
            // indexedDB would fail.
            log.error(`Failed to save indexes for ${f}`, e);
            throw e;
        }

        // This step, saving face crops, is conceptually not part of the
        // indexing pipeline; we just do it here since we have already have the
        // ImageBitmap at hand. Ignore errors that happen during this since it
        // does not impact the generated face index.
        if (!existingFaceIndex) {
            try {
                await saveFaceCrops(image.bitmap, faceIndex);
            } catch (e) {
                log.error(`Failed to save face crops for ${f}`, e);
            }
        }
    } finally {
        image.bitmap.close();
    }
};
