import {
    NULL_LOCATION,
    toDataOrPathOrZipEntry,
    type DesktopUploadItem,
    type UploadItem,
} from "@/new/photos/services/upload/types";
import type { ParsedExtractedMetadata } from "@/new/photos/types/metadata";
import {
    readConvertToMP4Done,
    readConvertToMP4Stream,
    writeConvertToMP4Stream,
} from "@/new/photos/utils/native-stream";
import type { Electron } from "@/next/types/ipc";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { validateAndGetCreationUnixTimeInMicroSeconds } from "@ente/shared/time";
import type { Remote } from "comlink";
import {
    ffmpegPathPlaceholder,
    inputPathPlaceholder,
    outputPathPlaceholder,
} from "constants/ffmpeg";
import type { DedicatedFFmpegWorker } from "worker/ffmpeg.worker";

/**
 * Generate a thumbnail for the given video using a wasm FFmpeg running in a web
 * worker.
 *
 * This function is called during upload, when we need to generate thumbnails
 * for the new files that the user is adding.
 *
 * @param blob The input video blob.
 *
 * @returns JPEG data of the generated thumbnail.
 *
 * See also {@link generateVideoThumbnailNative}.
 */
export const generateVideoThumbnailWeb = async (blob: Blob) =>
    _generateVideoThumbnail((seekTime: number) =>
        ffmpegExecWeb(makeGenThumbnailCommand(seekTime), blob, "jpeg"),
    );

const _generateVideoThumbnail = async (
    thumbnailAtTime: (seekTime: number) => Promise<Uint8Array>,
) => {
    try {
        // Try generating thumbnail at seekTime 1 second.
        return await thumbnailAtTime(1);
    } catch (e) {
        // If that fails, try again at the beginning. If even this throws, let
        // it fail.
        return await thumbnailAtTime(0);
    }
};

/**
 * Generate a thumbnail for the given video using a native FFmpeg binary bundled
 * with our desktop app.
 *
 * This function is called during upload, when we need to generate thumbnails
 * for the new files that the user is adding.
 *
 * @param dataOrPath The input video's data or the path to the video on the
 * user's local file system. See: [Note: Reading a UploadItem].
 *
 * @returns JPEG data of the generated thumbnail.
 *
 * See also {@link generateVideoThumbnailNative}.
 */
export const generateVideoThumbnailNative = async (
    electron: Electron,
    desktopUploadItem: DesktopUploadItem,
) =>
    _generateVideoThumbnail((seekTime: number) =>
        electron.ffmpegExec(
            makeGenThumbnailCommand(seekTime),
            toDataOrPathOrZipEntry(desktopUploadItem),
            "jpeg",
        ),
    );

const makeGenThumbnailCommand = (seekTime: number) => [
    ffmpegPathPlaceholder,
    "-i",
    inputPathPlaceholder,
    "-ss",
    `00:00:0${seekTime}`,
    "-vframes",
    "1",
    "-vf",
    "scale=-1:720",
    outputPathPlaceholder,
];

/**
 * Extract metadata from the given video
 *
 * When we're running in the context of our desktop app _and_ we're passed a
 * file path , this uses the native FFmpeg bundled with our desktop app.
 * Otherwise it uses a wasm FFmpeg running in a web worker.
 *
 * This function is called during upload, when we need to extract the metadata
 * of videos that the user is uploading.
 *
 * @param uploadItem A {@link File}, or the absolute path to a file on the
 * user's local file sytem. A path can only be provided when we're running in
 * the context of our desktop app.
 */
export const extractVideoMetadata = async (
    uploadItem: UploadItem,
): Promise<ParsedExtractedMetadata> => {
    const command = extractVideoMetadataCommand;
    const outputData =
        uploadItem instanceof File
            ? await ffmpegExecWeb(command, uploadItem, "txt")
            : await electron.ffmpegExec(
                  command,
                  toDataOrPathOrZipEntry(uploadItem),
                  "txt",
              );

    return parseFFmpegExtractedMetadata(outputData);
};

// Options:
//
// - `-c [short for codex] copy`
// - copy is the [stream_specifier](ffmpeg.org/ffmpeg.html#Stream-specifiers)
// - copies all the stream without re-encoding
//
// - `-map_metadata`
// - http://ffmpeg.org/ffmpeg.html#Advanced-options (search for map_metadata)
// - copies all stream metadata to the output
//
// - `-f ffmetadata`
// - https://ffmpeg.org/ffmpeg-formats.html#Metadata-1
// - dump metadata from media files into a simple INI-like utf-8 text file
//
const extractVideoMetadataCommand = [
    ffmpegPathPlaceholder,
    "-i",
    inputPathPlaceholder,
    "-c",
    "copy",
    "-map_metadata",
    "0",
    "-f",
    "ffmetadata",
    outputPathPlaceholder,
];

enum MetadataTags {
    CREATION_TIME = "creation_time",
    APPLE_CONTENT_IDENTIFIER = "com.apple.quicktime.content.identifier",
    APPLE_LIVE_PHOTO_IDENTIFIER = "com.apple.quicktime.live-photo.auto",
    APPLE_CREATION_DATE = "com.apple.quicktime.creationdate",
    APPLE_LOCATION_ISO = "com.apple.quicktime.location.ISO6709",
    LOCATION = "location",
}

function parseFFmpegExtractedMetadata(encodedMetadata: Uint8Array) {
    const metadataString = new TextDecoder().decode(encodedMetadata);
    const metadataPropertyArray = metadataString.split("\n");
    const metadataKeyValueArray = metadataPropertyArray.map((property) =>
        property.split("="),
    );
    const validKeyValuePairs = metadataKeyValueArray.filter(
        (keyValueArray) => keyValueArray.length === 2,
    ) as Array<[string, string]>;

    const metadataMap = Object.fromEntries(validKeyValuePairs);

    const location = parseAppleISOLocation(
        metadataMap[MetadataTags.APPLE_LOCATION_ISO] ??
            metadataMap[MetadataTags.LOCATION],
    );

    const creationTime = parseCreationTime(
        metadataMap[MetadataTags.APPLE_CREATION_DATE] ??
            metadataMap[MetadataTags.CREATION_TIME],
    );
    const parsedMetadata: ParsedExtractedMetadata = {
        creationTime,
        location: {
            latitude: location.latitude,
            longitude: location.longitude,
        },
        width: null,
        height: null,
    };
    return parsedMetadata;
}

function parseAppleISOLocation(isoLocation: string) {
    let location = { ...NULL_LOCATION };
    if (isoLocation) {
        const [latitude, longitude] = isoLocation
            .match(/(\+|-)\d+\.*\d+/g)
            .map((x) => parseFloat(x));

        location = { latitude, longitude };
    }
    return location;
}

function parseCreationTime(creationTime: string) {
    let dateTime = null;
    if (creationTime) {
        dateTime = validateAndGetCreationUnixTimeInMicroSeconds(
            new Date(creationTime),
        );
    }
    return dateTime;
}

/**
 * Run the given FFmpeg command using a wasm FFmpeg running in a web worker.
 *
 * As a rough ballpark, currently the native FFmpeg integration in the desktop
 * app is 10-20x faster than the wasm one. See: [Note: FFmpeg in Electron].
 */
const ffmpegExecWeb = async (
    command: string[],
    blob: Blob,
    outputFileExtension: string,
) => {
    const worker = await workerFactory.lazy();
    return await worker.exec(command, blob, outputFileExtension);
};

/**
 * Convert a video from a format that is not supported in the browser to MP4.
 *
 * This function is called when the user views a video or a live photo, and we
 * want to play it back. The idea is to convert it to MP4 which has much more
 * universal support in browsers.
 *
 * @param blob The video blob.
 *
 * @returns The mp4 video blob.
 */
export const convertToMP4 = async (blob: Blob): Promise<Blob | Uint8Array> => {
    const electron = globalThis.electron;
    if (electron) {
        return convertToMP4Native(electron, blob);
    } else {
        const command = [
            ffmpegPathPlaceholder,
            "-i",
            inputPathPlaceholder,
            "-preset",
            "ultrafast",
            outputPathPlaceholder,
        ];
        return ffmpegExecWeb(command, blob, "mp4");
    }
};

const convertToMP4Native = async (electron: Electron, blob: Blob) => {
    const token = await writeConvertToMP4Stream(electron, blob);
    const mp4Blob = await readConvertToMP4Stream(electron, token);
    readConvertToMP4Done(electron, token);
    return mp4Blob;
};

/** Lazily create a singleton instance of our worker */
class WorkerFactory {
    private instance: Promise<Remote<DedicatedFFmpegWorker>>;

    private createComlinkWorker = () =>
        new ComlinkWorker<typeof DedicatedFFmpegWorker>(
            "ffmpeg-worker",
            new Worker(new URL("worker/ffmpeg.worker.ts", import.meta.url)),
        );

    async lazy() {
        if (!this.instance) this.instance = this.createComlinkWorker().remote;
        return this.instance;
    }
}

const workerFactory = new WorkerFactory();
