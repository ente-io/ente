import { isDesktop } from "ente-base/app";
import { assertionFailed } from "ente-base/assert";
import { decryptBlob } from "ente-base/crypto";
import type { EncryptedBlob } from "ente-base/crypto/types";
import { ensureElectron } from "ente-base/electron";
import { isHTTP4xxError, type PublicAlbumsCredentials } from "ente-base/http";
import log from "ente-base/log";
import { fileLogID, type EnteFile } from "ente-media/file";
import { FileType } from "ente-media/file-type";
import {
    getAllLocalFiles,
    uniqueFilesByID,
} from "ente-new/photos/services/files";
import { settingsSnapshot } from "ente-new/photos/services/settings";
import { gunzip, gzip } from "ente-new/photos/utils/gzip";
import { randomSample } from "ente-utils/array";
import { ensurePrecondition } from "ente-utils/ensure";
import { wait } from "ente-utils/promise";
import { z } from "zod";
import {
    initiateGenerateHLS,
    readVideoStream,
    videoStreamDone,
} from "../utils/native-stream";
import { downloadManager, isNetworkDownloadError } from "./download";
import {
    fetchFileData,
    fetchFilePreviewData,
    getFilePreviewDataUploadURL,
    putVideoData,
    syncUpdatedFileDataFileIDs,
} from "./file-data";
import {
    fileSystemUploadItemIfUnchanged,
    type FileSystemUploadItem,
    type ProcessableUploadItem,
    type TimestampedFileSystemUploadItem,
} from "./upload";

interface VideoProcessingQueueItem {
    /**
     * The {@link EnteFile} (guaranteed to be of {@link FileType.video}) whose
     * video data needs processing.
     */
    file: EnteFile;
    /**
     * The {@link TimestampedFileSystemUploadItem} when available for the newly
     * uploaded {@link file}.
     *
     * It will be present when this queue item was enqueued during a upload from
     * the current client. If present, this serves as an optimization allowing
     * us to directly read the file off the user's file system.
     */
    timestampedUploadItem?: TimestampedFileSystemUploadItem;
}

const idleWaitInitial = 10 * 1000; /* 10 sec */
const idleWaitMax = idleWaitInitial * 2 ** 6; /* 640 sec */

/**
 * Internal in-memory state shared by the functions in this module.
 *
 * This entire object will be reset on logout.
 */
class VideoState {
    /**
     * Queue of recently uploaded items waiting to be processed.
     */
    liveQueue: VideoProcessingQueueItem[] = [];
    /**
     * Active queue processor, if any.
     */
    queueProcessor: Promise<void> | undefined;
    /**
     * A promise that the main processing loop waits for in addition to the idle
     * timeout. Can be resolved using {@link resolveTick}.
     */
    tick: Promise<void> | undefined;
    /**
     * A function that can be called to resolve {@link tick}.
     *
     * See: [Note: Exiting idle wait of processing loop].
     */
    resolveTick: (() => void) | undefined;
    /**
     * The time to sleep if nothing is pending.
     *
     * Goes from {@link idleWaitInitial} to {@link idleWaitMax} in doublings.
     * Reset back to {@link idleWaitInitial} in case of any activity.
     */
    idleWait = idleWaitInitial;
    /**
     * `true` if we have synced at least once with remote.
     *
     * We use this to gate the processing of the backfill queue to avoid
     * unnecessarily picking up files that have already been indexed elsewhere
     * (we'll still check before processing them, but still that's unnecessary
     * work this flag can save us).
     */
    haveSyncedOnce = false;
}

/**
 * State shared by the functions in this module. See {@link VideoState}.
 */
let _state = new VideoState();

/**
 * Reset any internal state maintained by the module.
 *
 * This is primarily meant as a way for stateful apps (e.g. photos) to clear any
 * user specific state on logout.
 */
export const resetVideoState = () => {
    // Note: We rely on [Note: Full reload on logout] to abort any in-flight
    // requests.
    _state = new VideoState();
};

export interface HLSPlaylistData {
    /** A data URL to a HLS playlist that streams the video. */
    playlistURL: string;
    /** The width of the video (px). */
    width: number;
    /** The height of the video (px). */
    height: number;
}

/**
 * Return a HLS playlist that can be used to stream playback of then given video
 * {@link file}.
 *
 * @param file An {@link EnteFile} of type video.
 *
 * @param publicAlbumsCredentials Credentials to use for fetching the HLS
 * playlist when we are running in the context of the public albums app. If
 * these are not specified, then the credentials of the logged in user are used.
 *
 * @returns The HLS playlist as a string (along with the dimensions of the video
 * it will play), or `undefined` if there is no video preview associated with
 * the given file.
 *
 * See: [Note: Video playlist and preview]
 *
 * ---
 *
 * [Note: Caching HLS playlist data]
 *
 * The playlist data can be cached in an asymmetric manner.
 *
 * - If a file has a corresponding HLS playlist, then currently there is no
 *   scenario (apart from file deletion, where the playlist also gets deleted)
 *   where the playlist is deleted after being created. There is a limit to the
 *   validity of the presigned chunk URLs within the playlist we create (which
 *   we do handle, see `createHLSPlaylistItemDataValidity`), but the original
 *   playlist itself does not change. Updates are technically possible, but
 *   apart from a misbehaving client, are not expected (and should be no-ops in
 *   the rare cases they happen, since effectively same playlist should get
 *   regenerated again). All in all, this means that a positive result ("this
 *   file has a playlist") can be cached indefinitely.
 *
 * - If a file does not have a HLS playlist, and it is eligible for being
 *   streamed (e.g. it is not too small where the streaming overhead is not
 *   required), then a client (this one, or a different one) can process it at
 *   any arbitrary time. So the negative result ("this file does not have a
 *   playlist") cannot be cached.
 *
 * So while we can easily cache the first case ("this file has a playlist"), we
 * need to deal with the second case ("this file does not have a playlist") a
 * bit more intricately:
 *
 * - If running in the context of a logged in user (e.g. photos app), we can use
 *   the "/files/data/status-diff" API to be notified of any modifications to
 *   the second case for the user's own files. This status-diff happens during
 *   the regular "sync", and we can use that as a cue to selectively prune cache
 *   entries for the second case (but can otherwise indefinitely cache it).
 *
 * - If the file is a shared file, the status-diff will not return it. And if
 *   we're not running in the context of a logged in user (e.g. the public
 *   albums app), then there is no status-diff to do. For these two scenarios,
 *   we thus mark the cached values as "transient" and always recheck for a
 *   playlist when opening the slide.
 */
export const hlsPlaylistDataForFile = async (
    file: EnteFile,
    publicAlbumsCredentials?: PublicAlbumsCredentials,
): Promise<HLSPlaylistData | undefined> => {
    ensurePrecondition(file.metadata.fileType == FileType.video);

    const playlistFileData = await fetchFileData(
        "vid_preview",
        file.id,
        publicAlbumsCredentials,
    );
    if (!playlistFileData) return undefined;

    const {
        type,
        playlist: playlistTemplate,
        width,
        height,
    } = await decryptPlaylistJSON(
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        playlistFileData,
        file,
    );

    // A playlist format the current client does not understand.
    if (type != "hls_video") return undefined;

    const videoURL = await fetchFilePreviewData(
        "vid_preview",
        file.id,
        publicAlbumsCredentials,
    );
    if (!videoURL) return undefined;

    // [Note: HLS playlist format]
    //
    // The decrypted playlist is a regular HLS playlist for an encrypted media
    // stream, except that it uses a placeholder "output.ts" which needs to be
    // replaced with the URL of the actual encrypted video data. A single URL
    // pointing to the entire encrypted video data suffices; the individual
    // chunks are fetched by HTTP range requests.
    //
    // Here is an example of what the contents of the `playlist` variable might
    // look like at this point:
    //
    //     #EXTM3U
    //     #EXT-X-VERSION:4
    //     #EXT-X-TARGETDURATION:8
    //     #EXT-X-MEDIA-SEQUENCE:0
    //     #EXT-X-KEY:METHOD=AES-128,URI="data:text/plain;base64,XjvG7qeRrsOpPUbJPh2Ikg==",IV=0x00000000000000000000000000000000
    //     #EXTINF:8.333333,
    //     #EXT-X-BYTERANGE:3046928@0
    //     output.ts
    //     #EXTINF:8.333333,
    //     #EXT-X-BYTERANGE:3012704@3046928
    //     output.ts
    //     #EXTINF:2.200000,
    //     #EXT-X-BYTERANGE:834736@6059632
    //     output.ts
    //     #EXT-X-ENDLIST
    //
    // The HLS playlist format is specified in RFC 8216:
    // https://datatracker.ietf.org/doc/html/rfc8216
    //
    // Some notes pertinent to us:
    //
    // - A URI line identifies a media segment.
    //
    // - The EXTINF tag specifies the duration of the media segment (applies
    //   only to the next URI line that follows it in the playlist).
    //
    // - The EXT-X-BYTERANGE tag indicates that a media segment is a sub-range
    //   of the resource identified by its URI (applies only to the next URI
    //   line that follows it in the playlist). The value should be of the
    //   format `<n>[@<o>]` where n is an integer indicating the length of the
    //   sub-range in bytes, and if present, o is the integer indicating the
    //   start of the sub-range as a byte offset from the beginning of the
    //   resource. If o is not present, the sub-range begins at the next byte
    //   following the sub-range of the previous media segment.
    //
    // - Media segments may be encrypted, and the EXT-X-KEY tag specifies how to
    //   decrypt them. It applies to all subsequent media segment (until another
    //   EXT-X-KEY). Value is an `<attribute-list>`, consisting of the METHOD
    //   (AES-128 for us), URI and IV attributes. The URI attribute value is a
    //   quoted string containing a URI that specifies how to obtain the key.

    const playlist = playlistTemplate.replaceAll(
        "\noutput.ts",
        `\n${videoURL}`,
    );

    // From the RFC
    //
    // > Each playlist file must be identifiable either by the path component of
    // > its URI (ending with either ".m3u8" or ".m3u") or by its HTTP
    // > Content-Type ("application/vnd.apple.mpegurl" or "audio/mpegurl").
    // > Clients should refuse to parse playlists that are not so identified.
    //
    // As of now (2025), there isn't a way to set the filename for a URL created
    // via createObjectURL, so instead we create a "data:" URL where the MIME
    // type can be specified.
    //
    // The generated data URL be of the form:
    //
    //     data:application/vnd.apple.mpegurl;base64,<base64-string>

    const playlistURL = await blobToDataURL(
        new Blob([playlist], { type: "application/vnd.apple.mpegurl" }),
    );

    return { playlistURL, width, height };
};

const PlaylistJSON = z.object({
    /**
     * The type of the playlist.
     *
     * The only value we currently understand on this client is "hls_video", but
     * for future extensibility this might be other values too.
     */
    type: z.string(),
    /**
     * The HLS playlist, as a string.
     */
    playlist: z.string(),
    /**
     * The width of the video (px).
     */
    width: z.number(),
    /**
     * The height of the video (px).
     */
    height: z.number(),
    /**
     * The size (in bytes) of the corresponding file containing the video
     * segments that the playlist refers to.
     */
    size: z.number(),
});

type PlaylistJSON = z.infer<typeof PlaylistJSON>;

const decryptPlaylistJSON = async (
    encryptedPlaylist: EncryptedBlob,
    file: EnteFile,
) => {
    const decryptedBytes = await decryptBlob(encryptedPlaylist, file.key);
    const jsonString = await gunzip(decryptedBytes);
    return PlaylistJSON.parse(JSON.parse(jsonString));
};

/**
 * Convert a blob to a `data:` URL.
 */
const blobToDataURL = (blob: Blob) =>
    new Promise<string>((resolve) => {
        const reader = new FileReader();
        // We need to cast to a string here. This should be safe since MDN says:
        //
        // > the result attribute contains the data as a data: URL representing
        // > the file's data as a base64 encoded string.
        // >
        // > https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsDataURL
        reader.onload = () => resolve(reader.result as string);
        reader.readAsDataURL(blob);
    });

// TODO(HLS): Store this in DB.
let _videoPreviewProcessedFileIDs: number[] = [];
let _videoPreviewFailedFileIDs: number[] = [];
let _videoPreviewSyncLastUpdatedAt: number | undefined;

/**
 * Return the (persistent) {@link Set} containing the ids of the files which
 * have already been processed for generating their streaming variant.
 *
 * {@link savedProcessedVideoFileIDs} and its sibling
 * {@link savedFailedVideoFileIDs} are mutually exclusive - that is, a file ID
 * will be present in only one of them at max. We maintain that invariant in the
 * higher level `mark*` functions when updating either of these persisted sets.
 *
 * The data is retrieved from persistent storage (KV DB), where it is stored as
 * an array.
 */
const savedProcessedVideoFileIDs = async () => {
    // TODO(HLS): make async
    await wait(0);
    return new Set(_videoPreviewProcessedFileIDs);
};

/**
 * Return the (persistent) {@link Set} containing the ids of the files for which
 * an attempt to generate a streaming variant failed locally.
 *
 * @see also {@link savedProcessedVideoFileIDs}.
 */
const savedFailedVideoFileIDs = async () => {
    // TODO(HLS): make async
    await wait(0);
    return new Set(_videoPreviewFailedFileIDs);
};

/**
 * Update the persisted set of IDs of files which have already been processed
 * and have a video preview generated (either on this client, or elsewhere).
 *
 * @see also {@link savedProcessedVideoFileIDs}.
 */
const saveProcessedVideoFileIDs = async (videoFileIDs: Set<number>) => {
    // TODO(HLS): make async
    await wait(0);
    _videoPreviewProcessedFileIDs = Array.from(videoFileIDs);
};

/**
 * Update the persisted set of IDs of files for which attempt to generate a
 * video preview failed on this client.
 *
 * @see also {@link savedProcessedVideoFileIDs}.
 */
const saveFailedVideoFileIDs = async (videoFileIDs: Set<number>) => {
    // TODO(HLS): make async
    await wait(0);
    _videoPreviewFailedFileIDs = Array.from(videoFileIDs);
};

/**
 * Mark the provided file ID as having been processed to generate a video
 * preview.
 *
 * The mark is persisted locally in IndexedDB (KV DB), so will persist across
 * app restarts (but not across logouts).
 *
 * @see also {@link savedProcessedVideoFileIDs}.
 */
const markProcessedVideoFileID = async (fileID: number) => {
    const savedIDs = await savedProcessedVideoFileIDs();
    const failedIDs = await savedFailedVideoFileIDs();
    savedIDs.add(fileID);
    if (failedIDs.delete(fileID)) await saveFailedVideoFileIDs(failedIDs);
    await saveProcessedVideoFileIDs(savedIDs);
};

/**
 * Mark multiple file IDs as processed. Plural variant of
 * {@link markProcessedVideoFileID}.
 */
const markProcessedVideoFileIDs = async (fileIDs: Set<number>) => {
    const savedIDs = await savedProcessedVideoFileIDs();
    const failedIDs = await savedFailedVideoFileIDs();
    await Promise.all([
        saveProcessedVideoFileIDs(savedIDs.union(fileIDs)),
        saveFailedVideoFileIDs(failedIDs.difference(fileIDs)),
    ]);
};

/**
 * Mark the provided file ID as having failed in a non-transient manner when we
 * tried processing it to generate a video preview on this client.
 *
 * Similar to [Note: Transient and permanent indexing failures], we attempt to
 * separate failures into two categories - transients, which leave no mark no
 * the DB so that the file eventually gets retried; and permanent, where we keep
 * a persistent record of failure so that this client does not go into a loop
 * reattempting preview generation for the specific unprocessable (to the best
 * of the current client's ability) item.
 *
 * The mark is local only, and will be reset on logout, or if another client
 * with a different able is able to process it.
 */
const markFailedVideoFileID = async (fileID: number) => {
    const failedIDs = await savedFailedVideoFileIDs();
    failedIDs.add(fileID);
    await saveFailedVideoFileIDs(failedIDs);
};

/**
 * Return the persisted time when we last synced processed file IDs with remote.
 *
 * The returned value is an epoch millisecond value suitable to be passed to
 * {@link syncUpdatedFileDataFileIDs}.
 */
const savedSyncLastUpdatedAt = async () => {
    // TODO(HLS): make async
    await wait(0);
    return _videoPreviewSyncLastUpdatedAt;
};

/**
 * Update the persisted timestamp used for syncing processed file IDs with
 * remote.
 *
 * Use {@link savedSyncLastUpdatedAt} to get the persisted value back.
 */
const saveSyncLastUpdatedAt = async (lastUpdatedAt: number) => {
    // TODO(HLS): make async
    await wait(0);
    _videoPreviewSyncLastUpdatedAt = lastUpdatedAt;
};

/**
 * Fetch IDs of files from remote that have been processed by other clients
 * since the last time we checked.
 */
const syncProcessedFileIDs = async () =>
    syncUpdatedFileDataFileIDs(
        "vid_preview",
        (await savedSyncLastUpdatedAt()) ?? 0,
        async ({ fileIDs, lastUpdatedAt }) => {
            await Promise.all([
                markProcessedVideoFileIDs(fileIDs),
                saveSyncLastUpdatedAt(lastUpdatedAt),
            ]);
        },
    );

/**
 * If video processing is enabled, trigger a sync with remote and any subsequent
 * backfill queue processing for pending videos.
 *
 * This function is expected to be called during a regular sync that the app
 * makes with remote (See: [Note: Remote sync]). It is a no-op if video
 * processing is not enabled or eligible on this device. Otherwise it syncs the
 * list of already processed file IDs with remote.
 *
 * At this point it also triggers a backfill (if needed), but doesn't wait for
 * it to complete (which might take a time for big libraries).
 *
 * Calling it when a backfill has already been triggered by a previous sync is
 * also a no-op. However, a backfill does not start until at least one sync of
 * file IDs has been completed with remote, to avoid picking up work on file IDs
 * that have already been processed elsewhere.
 */
export const videoProcessingSyncIfNeeded = async () => {
    if (!isDesktop) return;
    if (!isVideoProcessingEnabled()) return;

    await syncProcessedFileIDs();
    _state.haveSyncedOnce = true;

    tickNow(); /* if not already ticking */
};

/**
 * Create a streamable HLS playlist for a video uploaded from this client.
 *
 * This function is called by the uploader when it uploads a new file from this
 * client, allowing us to create its streamable variant without needing to
 * redownload the video.
 *
 * It only does the processing if we're running in the context of the desktop
 * app as the video processing is resource intensive. In particular, processing
 * large videos with the Wasm ffmpeg implementation can cause the app to crash,
 * on mobile devices (see https://github.com/ffmpegwasm/ffmpeg.wasm/issues/851).
 * In contrast, the desktop app can us the efficient native FFmpeg integration.
 *
 * Note that this function is an optimization. Even if we don't process the
 * video at this time (e.g. if the video processor can't keep up with the
 * uploads), we will eventually process it later as part of a backfill.
 *
 * @param file The {@link EnteFile} that got uploaded (video or otherwise).
 *
 * @param processableUploadItem The item that was uploaded. This can be used to
 * read the contents of the file that got uploaded directly from disk instead of
 * needing to download it again.
 */
export const processVideoNewUpload = (
    file: EnteFile,
    processableUploadItem: ProcessableUploadItem,
) => {
    if (!isDesktop) return;
    if (!isVideoProcessingEnabled()) return;
    if (file.metadata.fileType !== FileType.video) return;
    if (processableUploadItem instanceof File) {
        // While the types don't guarantee it, we really shouldn't be getting
        // here. The only time a processableUploadItem can be File when we're
        // running in the desktop app is when an edited image copy is being
        // saved. But we've already checked above that the file which was
        // uploaded was a video.
        assertionFailed();
        return;
    }

    // Enqueue the item.
    _state.liveQueue.push({
        file,
        timestampedUploadItem: processableUploadItem,
    });

    // Interrupt any idle timeouts if any, go go.
    tickNow();
};

/**
 * If {@link processQueue} is not already running, start it.
 *
 * If there is an existing {@link resolveTick} so that if perchance
 * {@link processQueue} was waiting on an idle timeout, it wakes up now.
 *
 * Also create a new {@link tick} and {@link resolveTick} pair for use by
 * subsequent calls to {@link tickNow}
 */
const tickNow = () => {
    // See: [Note: Exiting idle wait of processing loop] for what this function
    // is trying to do.

    // Resolve the existing tick (if any).
    if (_state.resolveTick) _state.resolveTick();

    // Create a new resolvable pair.
    _state.tick = new Promise((r) => (_state.resolveTick = r));

    // Start the processor if it isn't already running.
    _state.queueProcessor ??= processQueue();
};

export const isVideoProcessingEnabled = () =>
    // TODO(HLS):
    process.env.NEXT_PUBLIC_ENTE_WIP_VIDEO_STREAMING &&
    settingsSnapshot().isInternalUser;

/**
 * The video processing loop goes through videos one by one, preferring items in
 * the liveQueue, otherwise working for a backlog item. If there are no items to
 * process, it goes on an idle timeout. The {@link resolveTick} state property
 * can be used to tickle it out of sleep.
 *
 * [Note: Exiting idle wait of processing loop]
 *
 * The following toy example illustrates the overall mechanism:
 *
 *     let resolveTick
 *     let tick = new Promise((r) => (resolveTick = r));
 *
 *     const tickNow = () => {
 *         resolveTick();
 *         tick = new Promise((r) => (resolveTick = r));
 *     }
 *
 *     const f = async () => {
 *         for (let i of [1, 2, 3, 4, 5]) {
 *             const wait = new Promise((r) => setTimeout(r, i * 1e3));
 *             await Promise.race([wait, tick]);
 *         }
 *     }
 *
 *     f()
 *
 *     setTimeout(tickNow, 2500);
 *     setTimeout(tickNow, 5000);
 *     setTimeout(tickNow, 5500);
 *
 * The `Promise.race([wait, tick])` means that the loop will proceed to the next
 * item either if the timeout expires, or if tick resolves. Thus the same
 * function can handle both the internally determined processing of backfill
 * batches, and the externally triggered processing of live uploads.
 */
const processQueue = async () => {
    if (!(isDesktop && isVideoProcessingEnabled())) {
        assertionFailed(); /* we shouldn't have come here */
        return;
    }

    let bq: typeof _state.liveQueue | undefined;
    while (isVideoProcessingEnabled()) {
        let item = _state.liveQueue.shift();
        if (!item) {
            if (!bq && _state.haveSyncedOnce) {
                /* initialize */
                bq = await backfillQueue();
            }
            if (bq) {
                switch (bq.length) {
                    case 0:
                        /* no more items to backfill */
                        break;
                    case 1 /* last item. take it, and refill queue */:
                        item = bq.pop();
                        bq = await backfillQueue();
                        break;
                    default:
                        /* more than one item. take it */
                        item = bq.pop();
                        break;
                }
            } else {
                log.info("Not backfilling since we haven't synced yet");
            }
        }
        if (item) {
            try {
                await processQueueItem(item);
                await markProcessedVideoFileID(item.file.id);
            } catch (e) {
                // This will get retried again at some point later.
                log.error(`Failed to process video ${fileLogID(item.file)}`, e);
            }
            // Reset the idle wait on any activity.
            _state.idleWait = idleWaitInitial;
        } else {
            // There are no more items in either the live queue or backlog.
            // Go to sleep (for increasingly longer durations, capped at a
            // maximum).
            const idleWait = _state.idleWait;
            _state.idleWait = Math.min(idleWait * 2, idleWaitMax);

            // `tick` allows the sleep to be interrupted when there is
            // potential activity.
            if (!_state.tick) assertionFailed();
            const tick = _state.tick!;

            log.debug(() => ["gen-hls", { idleWait }]);
            await Promise.race([tick, wait(idleWait)]);
        }
    }

    _state.queueProcessor = undefined;
};

/**
 * Return the next batch of videos that need to be processed.
 *
 * If there is nothing pending, return an empty array.
 */
const backfillQueue = async (): Promise<VideoProcessingQueueItem[]> => {
    const allCollectionFiles = await getAllLocalFiles();
    const doneIDs = (await savedProcessedVideoFileIDs()).union(
        await savedFailedVideoFileIDs(),
    );
    const videoFiles = uniqueFilesByID(
        allCollectionFiles.filter((f) => f.metadata.fileType == FileType.video),
    );
    const pendingVideoFiles = videoFiles.filter((f) => !doneIDs.has(f.id));
    const batch = randomSample(pendingVideoFiles, 50);
    return batch.map((file) => ({ file }));
};

/**
 * Generate and upload a streamable variant of the given {@link EnteFile}.
 *
 * [Note: Preview variant of videos]
 *
 * A preview variant of a video is created by transcoding it into a smaller,
 * streamable, and (more) widely supported format.
 *
 * 1. The video is transcoded into a format that is both smaller but is also
 *    using a much more widely supported codec so that it can be played back
 *    readily across browsers and OSes independent of the codec used by the
 *    source video.
 *
 * 2. We use a format that can be streamed back by the client instead of needing
 *    to download it all at once, and also generate an HLS playlist that refers
 *    to the offsets in the generated video file.
 *
 * 3. Both the generated video and the HLS playlist are then uploaded, E2EE.
 */
const processQueueItem = async ({
    file,
    timestampedUploadItem,
}: VideoProcessingQueueItem) => {
    const electron = ensureElectron();

    log.debug(() => ["gen-hls", { file, timestampedUploadItem }]);

    const playlistFileData = await fetchFileData("vid_preview", file.id);
    if (playlistFileData) {
        // Since video processing for even an individual item can take
        // substantial time, it is possible that an item might've gotten
        // processed on a different client in the interval between us enqueuing
        // it and us getting here.
        //
        // Bail out early to avoid unnecessary duplicate work.
        log.info(`Generate HLS for ${fileLogID(file)} | already-processed`);
        return;
    }

    const uploadItem = timestampedUploadItem
        ? await fileSystemUploadItemIfUnchanged(
              timestampedUploadItem,
              electron.fs.statMtime,
          )
        : undefined;

    let sourceVideo: FileSystemUploadItem | ReadableStream | undefined =
        uploadItem;
    if (!sourceVideo) {
        try {
            sourceVideo = (await downloadManager.fileStream(file))!;
        } catch (e) {
            if (!isNetworkDownloadError(e))
                await markFailedVideoFileID(file.id);
            throw e;
        }
    }

    // [Note: Upload HLS video segment from node side]
    //
    // The generated video can be huge (multi-GB), too large to read it into
    // memory as an arrayBuffer.
    //
    // One option was to chain the video stream response (from the node side)
    // directly into a fetch request to `objectUploadURL`, however that requires
    // HTTP/2 (our servers support it, but self hosters' might not). Also that
    // approach won't work with retries on transient failures unless we
    // duplicate the stream beforehand, which invalidates the point of
    // streaming.
    //
    // So instead we provide the presigned upload URL to the node side so that
    // it can directly upload the generated video segments.
    const { objectID, url: objectUploadURL } =
        await getFilePreviewDataUploadURL(file);

    log.info(`Generate HLS for ${fileLogID(file)} | start`);

    // TODO(HLS): Inside this needs to be more granular in case of errors.
    const res = await initiateGenerateHLS(
        electron,
        sourceVideo,
        objectUploadURL,
    );

    if (!res) {
        log.info(`Generate HLS for ${fileLogID(file)} | not-required`);
        return;
    }

    const { playlistToken, dimensions, videoSize } = res;
    try {
        const playlist = await readVideoStream(electron, playlistToken).then(
            (res) => res.text(),
        );

        const playlistData = await encodePlaylistJSON({
            type: "hls_video",
            playlist,
            ...dimensions,
            size: videoSize,
        });

        try {
            await putVideoData(file, playlistData, objectID, videoSize);
        } catch (e) {
            if (isHTTP4xxError(e)) await markFailedVideoFileID(file.id);
            throw e;
        }

        log.info(`Generate HLS for ${fileLogID(file)} | done`);
    } finally {
        await videoStreamDone(electron, playlistToken);
    }
};

/**
 * A semi-sibling of {@link decryptPlaylistJSON}, which does the gzip but leaves
 * the encryption up to the next layer.
 *
 * It is a trivial function, the main utility it provides is that it forces us
 * to conform to the {@link PlaylistJSON} type.
 */
const encodePlaylistJSON = (playlistJSON: PlaylistJSON) =>
    gzip(JSON.stringify(playlistJSON));
