import { isDesktop } from "ente-base/app";
import { decryptBlob } from "ente-base/crypto";
import type { EncryptedBlob } from "ente-base/crypto/types";
import { isDevBuild } from "ente-base/env";
import type { PublicAlbumsCredentials } from "ente-base/http";
import log from "ente-base/log";
import type { EnteFile } from "ente-media/file";
import { FileType } from "ente-media/file-type";
import { settingsSnapshot } from "ente-new/photos/services/settings";
import { gunzip } from "ente-new/photos/utils/gzip";
import { ensurePrecondition } from "ente-utils/ensure";
import { z } from "zod";
import { downloadManager } from "./download";
import { generateVideoPreviewVariantWeb } from "./ffmpeg";
import { fetchFileData, fetchFilePreviewData } from "./file-data";
import type { UploadItem } from "./upload";

interface VideoProcessingQueueItem {
    /**
     * The {@link EnteFile} (guaranteed to be of {@link FileType.video}) whose
     * video data needs processing.
     */
    file: EnteFile;
    /**
     * The contents of the {@link file} as the newly uploaded {@link UploadItem}.
     */
    uploadItem: UploadItem;
}

/**
 * Internal in-memory state shared by the functions in this module.
 *
 * This entire object will be reset on logout.
 */
class VideoState {
    /**
     * Queue of videos waiting to be processed.
     */
    videoProcessingQueue: VideoProcessingQueueItem[] = [];
    /**
     * Active queue processor, if any.
     */
    queueProcessor: Promise<void> | undefined;
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
});

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

/**
 * Create a streamable HLS playlist for a video uploaded from this client.
 *
 * This function is called by the uploader when it uploads a new file from this
 * client, allowing us to create its streamable variant without needing to
 * redownload the video.
 *
 * Note that this is an optimization. Even if we don't process the video at this
 * time (e.g. if the video processor can't keep up with the uploads), we will
 * eventually process it later as part of a backfill.
 *
 * @param file The {@link EnteFile} that got uploaded (video or otherwise).
 *
 * @param uploadItem The item that was uploaded. This can be used to get at the
 * contents of the file that got uploaded.
 */
export const processVideoNewUpload = (
    file: EnteFile,
    uploadItem: UploadItem,
) => {
    // TODO(HLS):
    if (!isVideoProcessingEnabled()) return;
    if (file.metadata.fileType !== FileType.video) return;
    if (!isDesktop) {
        // Processing very large videos with the current ffmpeg Wasm
        // implementation can cause the app to crash, esp. on mobile devices
        // (e.g. https://github.com/ffmpegwasm/ffmpeg.wasm/issues/851).
        //
        // So the video processing only happpens in the desktop app (which uses
        // the much more efficient native ffmpeg integration).
        if (process.env.NEXT_PUBLIC_ENTE_WIP_VIDEO_STREAMING && isDevBuild) {
            // TODO(HLS): Temporary dev convenience
        } else {
            return;
        }
    }

    if (_state.videoProcessingQueue.length > 1) {
        // Drop new requests if the queue can't keep up to avoid the app running
        // out of memory by keeping hold of too many (potentially huge) video
        // blobs. These items will later get processed as part of a backfill.
        log.info("Will process new video upload later (backlog too big)");
        return;
    }

    // Enqueue the item.
    _state.videoProcessingQueue.push({ file, uploadItem });

    // Tickle the processor if it isn't already running.
    _state.queueProcessor ??= processQueue();
};

export const isVideoProcessingEnabled = () =>
    process.env.NEXT_PUBLIC_ENTE_WIP_VIDEO_STREAMING &&
    settingsSnapshot().isInternalUser;

const processQueue = async () => {
    while (_state.videoProcessingQueue.length) {
        try {
            await processQueueItem(_state.videoProcessingQueue.shift()!);
        } catch (e) {
            log.error("Video processing failed", e);
            // Ignore this unprocessable item. Currently this function only runs
            // post upload, so this item will later get processed as part of the
            // backfill.
            //
            // TODO(HLS): When processing the backfill itself, we'll need a way
            // to mark this item as failed.
        }
    }
    _state.queueProcessor = undefined;
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
    uploadItem,
}: VideoProcessingQueueItem) => {
    log.debug(() => ["gen-hls", { file, uploadItem }]);

    const fileBlob = await fetchOriginalVideoBlob(file, uploadItem);
    const previewFileData = await generateVideoPreviewVariantWeb(fileBlob);

    console.log(previewFileData);

    await Promise.resolve(0);
};

/**
 * Return a blob containing the contents of the given video file.
 *
 * The blob is either constructed using the given {@link uploadItem} if present,
 * otherwise it is downloaded from remote.
 *
 * @param file An {@link EnteFile} of type {@link FileType.video}.
 *
 * @param uploadItem If we're called during the upload process, then this will
 * be set to the {@link UploadItem} that was uploaded. This way, we can directly
 * use the on-disk file instead of needing to download the original from remote.
 */
const fetchOriginalVideoBlob = async (
    file: EnteFile,
    uploadItem: UploadItem | undefined,
): Promise<Blob> =>
    uploadItem
        ? fetchOriginalVideoUploadItemBlob(file, uploadItem)
        : await downloadManager.fileBlob(file);

const fetchOriginalVideoUploadItemBlob = (
    _: EnteFile,
    uploadItem: UploadItem,
) => {
    // TODO(HLS): Commented below is the implementation that the eventual
    // desktop only conversion would need to handle - the conversion logic would
    // need to move to the desktop side to allow it to handle large videos.
    //
    // Meanwhile during development, we assume we're on the happy web-only cases
    // (dragging and dropping a file). All this code is behind a development
    // feature flag, so it is not going to impact end users.

    if (typeof uploadItem == "string" || Array.isArray(uploadItem)) {
        throw new Error("Not implemented");
        // const { response, lastModifiedMs } = await readStream(
        //     ensureElectron(),
        //     uploadItem,
        // );
        // const path = typeof uploadItem == "string" ? uploadItem : uploadItem[1];
        // // This function will not be called for videos, and for images
        // // it is reasonable to read the entire stream into memory here.
        // return new File([await response.arrayBuffer()], basename(path), {
        //     lastModified: lastModifiedMs,
        // });
    } else {
        if (uploadItem instanceof File) {
            return uploadItem;
        } else {
            return uploadItem.file;
        }
    }
};
