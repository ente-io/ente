import { ensureElectron } from "@/base/electron";
import log from "@/base/log";
import type { Electron } from "@/base/types/ipc";
import {
    toDataOrPathOrZipEntry,
    type DesktopUploadItem,
    type UploadItem,
} from "@/gallery/services/upload";
import {
    readConvertToMP4Done,
    readConvertToMP4Stream,
    writeConvertToMP4Stream,
} from "@/gallery/utils/native-stream";
import { parseMetadataDate, type ParsedMetadata } from "@/media/file-metadata";
import {
    ffmpegPathPlaceholder,
    inputPathPlaceholder,
    outputPathPlaceholder,
} from "./constants";
import { ffmpegExecWeb } from "./web";

/**
 * Generate a thumbnail for the given video using a Wasm FFmpeg running in a web
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
    } catch {
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
 * Otherwise it uses a Wasm build of FFmpeg running in a web worker.
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
): Promise<ParsedMetadata> => {
    const command = extractVideoMetadataCommand;
    return parseFFmpegExtractedMetadata(
        uploadItem instanceof File
            ? await ffmpegExecWeb(command, uploadItem, "txt")
            : await ensureElectron().ffmpegExec(
                  command,
                  toDataOrPathOrZipEntry(uploadItem),
                  "txt",
              ),
    );
};

/**
 * The FFmpeg command to use to extract metadata from videos.
 *
 * Options:
 *
 * - `-c [short for codex] copy`
 * - copy is the [stream_specifier](ffmpeg.org/ffmpeg.html#Stream-specifiers)
 * - copies all the stream without re-encoding
 *
 * - `-map_metadata`
 * - http://ffmpeg.org/ffmpeg.html#Advanced-options (search for map_metadata)
 * - copies all stream metadata to the output
 *
 * - `-f ffmetadata`
 * - https://ffmpeg.org/ffmpeg-formats.html#Metadata-2
 * - dump metadata from media files into a simple INI-like utf-8 text file
 */
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

/**
 * Convert the output produced by running the FFmpeg
 * {@link extractVideoMetadataCommand} into a {@link ParsedMetadata}.
 *
 * @param ffmpegOutput The bytes containing the output of the FFmpeg command.
 */
const parseFFmpegExtractedMetadata = (ffmpegOutput: Uint8Array) => {
    // The output is a utf8 INI-like text file with key=value pairs interspersed
    // with comments and newlines.
    //
    // https://ffmpeg.org/ffmpeg-formats.html#Metadata-2

    const lines = new TextDecoder().decode(ffmpegOutput).split("\n");
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

/**
 * Parse a location string found in the FFmpeg metadata attributes.
 *
 * This is meant to parse either the "com.apple.quicktime.location.ISO6709"
 * (preferable) or the "location" key (fallback).
 */
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

/**
 * Parse a date/time string found in the FFmpeg metadata attributes.
 *
 * This is meant to parse either the "com.apple.quicktime.creationdate"
 * (preferable) or the "creation_time" key (fallback).
 *
 * Both of these are expected to be ISO 8601 date/time strings, but we prefer
 * "com.apple.quicktime.creationdate" since it includes the time zone offset.
 */
const parseFFMetadataDate = (s: string | undefined) => {
    if (!s) return undefined;

    const d = parseMetadataDate(s);
    if (!d) {
        log.warn(`Ignoring unparseable video metadata date string "${s}"`);
        return undefined;
    }

    // While not strictly required, we retain the same behaviour as the image
    // Exif parser of ignoring dates whose epoch is 0.
    if (!d.timestamp) {
        log.warn(`Ignoring zero video metadata date string "${s}"`);
        return undefined;
    }

    return d;
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
    await readConvertToMP4Done(electron, token);
    return mp4Blob;
};

/**
 * Generate a preview variant of for the given video using a Wasm FFmpeg running
 * in a web worker.
 *
 * See: [Note: Preview variant of videos].
 *
 * @param blob The input video blob.
 *
 * @returns The data of the generated preview variant.
 */
export const generateVideoPreviewVariantWeb = async (blob: Blob) =>
    ffmpegExecWeb(generateVideoPreviewMetadataCommand, blob, "mp4");

/**
 * The FFmpeg command to use to create a preview variant of videos.
 *
 * Current parameters
 *
 * - 720p width
 * - 2000kbps bitrate
 * - 30fps frame rate
 *
 * See: [Note: Preview variant of videos]
 *
 * Options:
 *
 * - `-vf` creates a filter graph for the video stream
 *
 * - `-vf scale=720:-1` scales the video to 720p width, keeping aspect ratio.
 *
 * - `-r` sets the frame rate.
 *
 * - `-c:v libx264` sets the codec for the video stream to H264.
 *
 * - `-b:v 2000k` sets the bitrate for the video stream.
 *
 * - `-c:a aac -b:a 128k` converts the audio stream to 128k bit AAC.
 */
const generateVideoPreviewMetadataCommand = [
    ffmpegPathPlaceholder,
    "-i",
    inputPathPlaceholder,
    "-vf",
    "scale=720:-1",
    "-r",
    "30",
    "-c:v",
    "libx264",
    "-b:v",
    "2000k",
    "-c:a",
    "aac",
    "-b:a",
    "128k",
    outputPathPlaceholder,
];
