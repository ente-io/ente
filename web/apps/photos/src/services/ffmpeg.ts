import log from "@/next/log";
import { validateAndGetCreationUnixTimeInMicroSeconds } from "@ente/shared/time";
import {
    FFMPEG_PLACEHOLDER,
    INPUT_PATH_PLACEHOLDER,
    OUTPUT_PATH_PLACEHOLDER,
} from "constants/ffmpeg";
import { NULL_LOCATION } from "constants/upload";
import { ElectronFile, ParsedExtractedMetadata } from "types/upload";
import ComlinkFFmpegWorker from "utils/comlink/ComlinkFFmpegWorker";

/** Called during upload */
export async function generateVideoThumbnail(
    file: File | ElectronFile,
): Promise<File | ElectronFile> {
    try {
        let seekTime = 1;
        while (seekTime >= 0) {
            try {
                return await ffmpegExec(
                    [
                        FFMPEG_PLACEHOLDER,
                        "-i",
                        INPUT_PATH_PLACEHOLDER,
                        "-ss",
                        `00:00:0${seekTime}`,
                        "-vframes",
                        "1",
                        "-vf",
                        "scale=-1:720",
                        OUTPUT_PATH_PLACEHOLDER,
                    ],
                    file,
                    "thumb.jpeg",
                );
            } catch (e) {
                if (seekTime === 0) {
                    throw e;
                }
            }
            seekTime--;
        }
    } catch (e) {
        log.error("ffmpeg generateVideoThumbnail failed", e);
        throw e;
    }
}

/** Called during upload */
export async function extractVideoMetadata(file: File | ElectronFile) {
    try {
        // https://stackoverflow.com/questions/9464617/retrieving-and-saving-media-metadata-using-ffmpeg
        // -c [short for codex] copy[(stream_specifier)[ffmpeg.org/ffmpeg.html#Stream-specifiers]] => copies all the stream without re-encoding
        // -map_metadata [http://ffmpeg.org/ffmpeg.html#Advanced-options search for map_metadata] => copies all stream metadata to the out
        // -f ffmetadata [https://ffmpeg.org/ffmpeg-formats.html#Metadata-1] => dump metadata from media files into a simple UTF-8-encoded INI-like text file
        const metadata = await ffmpegExec(
            [
                FFMPEG_PLACEHOLDER,
                "-i",
                INPUT_PATH_PLACEHOLDER,
                "-c",
                "copy",
                "-map_metadata",
                "0",
                "-f",
                "ffmetadata",
                OUTPUT_PATH_PLACEHOLDER,
            ],
            file,
            `metadata.txt`,
        );
        return parseFFmpegExtractedMetadata(
            new Uint8Array(await metadata.arrayBuffer()),
        );
    } catch (e) {
        log.error("ffmpeg extractVideoMetadata failed", e);
        throw e;
    }
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
    try {
        return await ffmpegExec(
            [
                FFMPEG_PLACEHOLDER,
                "-i",
                INPUT_PATH_PLACEHOLDER,
                "-preset",
                "ultrafast",
                OUTPUT_PATH_PLACEHOLDER,
            ],
            file,
            "output.mp4",
            true,
        );
    } catch (e) {
        log.error("ffmpeg convertToMP4 failed", e);
        throw e;
    }
}

/**
 * Run the given FFMPEG command.
 *
 * If we're running in the context of our desktop app, use the FFMPEG binary we
 * bundle with our desktop app to run the command. Otherwise fallback to the
 * WASM ffmpeg we link to from our web app.
 *
 * As a rough ballpark, the native FFMPEG integration in the desktop app is
 * 10-20x faster than the WASM one currently. See: [Note: FFMPEG in Electron].
 */
const ffmpegExec = async (
    cmd: string[],
    inputFile: File | ElectronFile,
    outputFilename: string,
    dontTimeout?: boolean,
): Promise<File | ElectronFile> => {
    const electron = globalThis.electron;
    if (electron) {
        return electron.runFFmpegCmd(
            cmd,
            inputFile,
            outputFilename,
            dontTimeout,
        );
    } else {
        return ComlinkFFmpegWorker.getInstance().then((worker) =>
            worker.run(cmd, inputFile, outputFilename, dontTimeout),
        );
    }
};
