import log from "ente-base/log";
import {
    parseMetadataDate,
    type ParsedMetadata,
} from "ente-media/file-metadata";
import {
    ffmpegPathPlaceholder,
    inputPathPlaceholder,
    outputPathPlaceholder,
} from "./constants";
import { determineVideoDurationWeb, ffmpegExecWeb } from "./web";

/**
 * Generate a thumbnail for the given video using the web FFmpeg worker.
 */
export const generateVideoThumbnailWeb = async (blob: Blob) =>
    _generateVideoThumbnail((seekTime: number) =>
        ffmpegExecWeb(makeGenThumbnailCommand(seekTime), blob, "jpeg"),
    );

const _generateVideoThumbnail = async (
    thumbnailAtTime: (seekTime: number) => Promise<Uint8Array>,
) => {
    try {
        return await thumbnailAtTime(1);
    } catch {
        return await thumbnailAtTime(0);
    }
};

const makeGenThumbnailCommand = (seekTime: number) => ({
    default: _makeGenThumbnailCommand(seekTime, false),
    hdr: _makeGenThumbnailCommand(seekTime, true),
});

const _makeGenThumbnailCommand = (seekTime: number, forHDR: boolean) => [
    ffmpegPathPlaceholder,
    "-i",
    inputPathPlaceholder,
    "-ss",
    `00:00:0${seekTime}`,
    "-vframes",
    "1",
    "-vf",
    [
        "scale=-2:720",
        forHDR
            ? [
                  "zscale=transfer=linear",
                  "tonemap=tonemap=hable:desat=0",
                  "zscale=primaries=709:transfer=709:matrix=709",
              ]
            : [],
    ]
        .flat()
        .join(","),
    outputPathPlaceholder,
];

/**
 * Extract ffmetadata from an uploaded video using the web FFmpeg worker.
 */
export const extractVideoMetadata = async (
    uploadItem: File,
): Promise<ParsedMetadata> =>
    parseFFmpegExtractedMetadata(
        await ffmpegExecWeb(extractVideoMetadataCommand, uploadItem, "txt"),
    );

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

const parseFFmpegExtractedMetadata = (ffmpegOutput: Uint8Array) => {
    const lines = new TextDecoder().decode(ffmpegOutput).split(/\r?\n/);
    const isPair = (xs: string[]): xs is [string, string] => xs.length == 2;
    const kvPairs = lines.map((property) => property.split("=")).filter(isPair);

    const kv = new Map(kvPairs);
    const result: ParsedMetadata = {};

    const creationDate =
        parseFFMetadataDate(kv.get("com.apple.quicktime.creationdate")) ??
        parseFFMetadataDate(kv.get("creation_time"));
    if (creationDate) result.creationDate = creationDate;

    const location =
        parseFFMetadataLocation(
            kv.get("com.apple.quicktime.location.ISO6709"),
        ) ?? parseFFMetadataLocation(kv.get("location"));
    if (location) result.location = location;

    return result;
};

const parseFFMetadataLocation = (s: string | undefined) => {
    if (!s) return undefined;

    const m = s.match(/(\+|-)\d+\.*\d+/g);
    if (!m) {
        log.warn(`Ignoring unparseable location string "${s}"`);
        return undefined;
    }

    const [latitude, longitude] = m.map(parseFloat);
    if (!latitude || !longitude) {
        log.warn(`Ignoring unparseable video metadata location string "${s}"`);
        return undefined;
    }

    return { latitude, longitude };
};

const parseFFMetadataDate = (s: string | undefined) => {
    if (!s) return undefined;

    const d = parseMetadataDate(s);
    if (!d) {
        log.warn(`Ignoring unparseable video metadata date string "${s}"`);
        return undefined;
    }

    if (!d.timestamp) {
        log.warn(`Ignoring zero video metadata date string "${s}"`);
        return undefined;
    }

    return d;
};

export const determineVideoDuration = async (
    uploadItem: File,
): Promise<number> => determineVideoDurationWeb(uploadItem);

export const convertToMP4 = async (blob: Blob): Promise<Blob | Uint8Array> => {
    const command = [
        ffmpegPathPlaceholder,
        "-i",
        inputPathPlaceholder,
        "-preset",
        "ultrafast",
        outputPathPlaceholder,
    ];
    return ffmpegExecWeb(command, blob, "mp4");
};
