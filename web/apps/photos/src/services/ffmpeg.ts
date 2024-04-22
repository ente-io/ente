import { ElectronFile } from "@/next/types/file";
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
 * Generate a thumbnail of the given video using FFmpeg.
 *
 * This function is called during upload, when we need to generate thumbnails
 * for the new files that the user is adding.
 *
 * @param blob The input video blob.
 * @returns JPEG data of the generated thumbnail.
 */
export const generateVideoThumbnail = async (blob: Blob) => {
    const thumbnailAtTime = (seekTime: number) =>
        ffmpegExec(
            [
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
            ],
            blob,
            "thumb.jpeg",
        );

    try {
        // Try generating thumbnail at seekTime 1 second.
        return await thumbnailAtTime(1);
    } catch (e) {
        // If that fails, try again at the beginning. If even this throws, let
        // it fail.
        return await thumbnailAtTime(0);
    }
};

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
        `metadata.txt`,
    );
    return parseFFmpegExtractedMetadata(
        new Uint8Array(await metadata.arrayBuffer()),
    );
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
        "output.mp4",
        30 * 1000,
    );
}

/**
 * Run the given FFmpeg command.
 *
 * If we're running in the context of our desktop app, use the FFmpeg binary we
 * bundle with our desktop app to run the command. Otherwise fallback to using
 * the wasm FFmpeg we link to from our web app in a web worker.
 *
 * As a rough ballpark, the native FFmpeg integration in the desktop app is
 * 10-20x faster than the wasm one currently. See: [Note: FFmpeg in Electron].
 */
const ffmpegExec = async (
    command: string[],
    blob: Blob,
    outputFileName: string,
    timeoutMs: number = 0,
): Promise<Uint8Array> => {
    const electron = globalThis.electron;
    if (electron)
        return electron.ffmpegExec(command, blob, outputFileName, timeoutMs);
    else
        return workerFactory
            .lazy()
            .then((worker) =>
                worker.exec(command, blob, outputFileName, timeoutMs),
            );
};

const ffmpegExec2 = async (
    command: string[],
    inputFile: File | ElectronFile,
    outputFileName: string,
    timeoutMS: number = 0,
): Promise<File | ElectronFile> => {
    const electron = globalThis.electron;
    if (electron || false) {
        // return electron.ffmpegExec(
        //     command,
        //     /* TODO(MR): ElectronFile changes */
        //     inputFile as unknown as string,
        //     outputFileName,
        //     timeoutMS,
        // );
    } else {
        return workerFactory
            .lazy()
            .then((worker) =>
                worker.execute(
                    command,
                    /* TODO(MR): ElectronFile changes */ inputFile as File,
                    outputFileName,
                    timeoutMS,
                ),
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
