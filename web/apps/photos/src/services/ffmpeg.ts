import { ElectronFile } from "@/next/types/file";
import type { Electron } from "@/next/types/ipc";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { validateAndGetCreationUnixTimeInMicroSeconds } from "@ente/shared/time";
import { Remote } from "comlink";
import {
    ffmpegPathPlaceholder,
    inputPathPlaceholder,
    outputPathPlaceholder,
} from "constants/ffmpeg";
import { NULL_LOCATION } from "constants/upload";
import { ParsedExtractedMetadata } from "types/upload";
import { type DedicatedFFmpegWorker } from "worker/ffmpeg.worker";

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
    generateVideoThumbnail((seekTime: number) =>
        ffmpegExecWeb(genThumbnailCommand(seekTime), blob, "jpeg", 0),
    );

const generateVideoThumbnail = async (
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
 * user's local filesystem. See: [Note: The fileOrPath parameter to upload].
 *
 * @returns JPEG data of the generated thumbnail.
 *
 * See also {@link generateVideoThumbnailNative}.
 */
export const generateVideoThumbnailNative = async (
    electron: Electron,
    dataOrPath: Uint8Array | string,
) =>
    generateVideoThumbnail((seekTime: number) =>
        electron.ffmpegExec(
            genThumbnailCommand(seekTime),
            dataOrPath,
            "jpeg",
            0,
        ),
    );

const genThumbnailCommand = (seekTime: number) => [
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

/** Called during upload */
export async function extractVideoMetadata(file: File | ElectronFile) {
    // https://stackoverflow.com/questions/9464617/retrieving-and-saving-media-metadata-using-ffmpeg
    // -c [short for codex] copy[(stream_specifier)[ffmpeg.org/ffmpeg.html#Stream-specifiers]] => copies all the stream without re-encoding
    // -map_metadata [http://ffmpeg.org/ffmpeg.html#Advanced-options search for map_metadata] => copies all stream metadata to the out
    // -f ffmetadata [https://ffmpeg.org/ffmpeg-formats.html#Metadata-1] => dump metadata from media files into a simple UTF-8-encoded INI-like text file
    const metadata = await ffmpegExec2(
        [
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
        ],
        file,
        "txt",
    );
    return parseFFmpegExtractedMetadata(metadata);
}

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
    let location = NULL_LOCATION;
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

/** Called when viewing a file */
export async function convertToMP4(file: File) {
    return await ffmpegExec2(
        [
            ffmpegPathPlaceholder,
            "-i",
            inputPathPlaceholder,
            "-preset",
            "ultrafast",
            outputPathPlaceholder,
        ],
        file,
        "mp4",
        30 * 1000,
    );
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
    timeoutMs: number,
) => {
    const worker = await workerFactory.lazy();
    return await worker.exec(command, blob, outputFileExtension, timeoutMs);
};

/**
 * Run the given FFmpeg command using a native FFmpeg binary bundled with our
 * desktop app.
 *
 * See also: {@link ffmpegExecWeb}.
 */
/*
TODO(MR): Remove me
const ffmpegExecNative = async (
    electron: Electron,
    command: string[],
    blob: Blob,
    timeoutMs: number = 0,
) => {
    const electron = globalThis.electron;
    if (electron) {
        const data = new Uint8Array(await blob.arrayBuffer());
        return await electron.ffmpegExec(command, data, timeoutMs);
    } else {
        const worker = await workerFactory.lazy();
        return await worker.exec(command, blob, timeoutMs);
    }
};
*/

const ffmpegExec2 = async (
    command: string[],
    inputFile: File | ElectronFile,
    outputFileExtension: string,
    timeoutMS: number = 0,
) => {
    const electron = globalThis.electron;
    if (electron || false) {
        throw new Error("WIP");
        // return electron.ffmpegExec(
        //     command,
        //     /* TODO(MR): ElectronFile changes */
        //     inputFile as unknown as string,
        //     outputFileName,
        //     timeoutMS,
        // );
    } else {
        /* TODO(MR): ElectronFile changes */
        return ffmpegExecWeb(
            command,
            inputFile as File,
            outputFileExtension,
            timeoutMS,
        );
    }
};

/** Lazily create a singleton instance of our worker */
class WorkerFactory {
    private instance: Promise<Remote<DedicatedFFmpegWorker>>;

    async lazy() {
        if (!this.instance) this.instance = createComlinkWorker().remote;
        return this.instance;
    }
}

const workerFactory = new WorkerFactory();

const createComlinkWorker = () =>
    new ComlinkWorker<typeof DedicatedFFmpegWorker>(
        "ffmpeg-worker",
        new Worker(new URL("worker/ffmpeg.worker.ts", import.meta.url)),
    );
