import { FILE_TYPE, type FileTypeInfo } from "@/media/file-type";
import {
    generateImageThumbnailUsingCanvas,
    generateVideoThumbnailUsingCanvas,
} from "@/media/image";
import log from "@/next/log";
import { type Electron } from "@/next/types/ipc";
import * as ffmpeg from "services/ffmpeg";
import { heicToJPEG } from "services/heic-convert";
import { toDataOrPathOrZipEntry, type DesktopUploadItem } from "./types";

/** Maximum width or height of the generated thumbnail */
const maxThumbnailDimension = 720;
/** Maximum size (in bytes) of the generated thumbnail */
const maxThumbnailSize = 100 * 1024; // 100 KB

/**
 * Generate a JPEG thumbnail for the given image or video blob.
 *
 * The thumbnail has a smaller file size so that is quick to load. But more
 * importantly, it uses a universal file format (JPEG in our case) so that the
 * thumbnail itself can be opened in all clients, even those like the web client
 * itself that might not yet have support for more exotic formats.
 *
 * @param blob The image or video blob whose thumbnail we want to generate.
 *
 * @param fileTypeInfo The type information for the file this blob came from.
 *
 * @return The JPEG data of the generated thumbnail.
 */
export const generateThumbnailWeb = async (
    blob: Blob,
    fileTypeInfo: FileTypeInfo,
): Promise<Uint8Array> =>
    fileTypeInfo.fileType === FILE_TYPE.IMAGE
        ? await generateImageThumbnailWeb(blob, fileTypeInfo)
        : await generateVideoThumbnailWeb(blob);

const generateImageThumbnailWeb = async (
    blob: Blob,
    { extension }: FileTypeInfo,
) => {
    if (extension == "heic" || extension == "heif") {
        log.debug(() => `Pre-converting HEIC to JPEG for thumbnail generation`);
        blob = await heicToJPEG(blob);
    }

    return generateImageThumbnailUsingCanvas(blob);
};

const generateVideoThumbnailWeb = async (blob: Blob) => {
    try {
        return await ffmpeg.generateVideoThumbnailWeb(blob);
    } catch (e) {
        log.error(
            `Failed to generate video thumbnail using the wasm FFmpeg web worker, will fallback to canvas`,
            e,
        );
        return generateVideoThumbnailUsingCanvas(blob);
    }
};

/**
 * Generate a JPEG thumbnail for the given file or path using native tools.
 *
 * This function only works when we're running in the context of our desktop
 * app, and this dependency is enforced by the need to pass the {@link electron}
 * object which we use to perform IPC with the Node.js side of our desktop app.
 *
 * @param dataOrPath Contents of an image or video file, or the path to the
 * image or video file on the user's local file system, whose thumbnail we want
 * to generate.
 *
 * @param fileTypeInfo The type information for {@link dataOrPath}.
 *
 * @return The JPEG data of the generated thumbnail.
 *
 * See also {@link generateThumbnailWeb}.
 */
export const generateThumbnailNative = async (
    electron: Electron,
    desktopUploadItem: DesktopUploadItem,
    fileTypeInfo: FileTypeInfo,
): Promise<Uint8Array> =>
    fileTypeInfo.fileType === FILE_TYPE.IMAGE
        ? await electron.generateImageThumbnail(
              toDataOrPathOrZipEntry(desktopUploadItem),
              maxThumbnailDimension,
              maxThumbnailSize,
          )
        : ffmpeg.generateVideoThumbnailNative(electron, desktopUploadItem);

/**
 * A fallback, black, thumbnail for use in cases where thumbnail generation
 * fails.
 */
export const fallbackThumbnail = () =>
    Uint8Array.from(atob(blackThumbnailB64), (c) => c.charCodeAt(0));

const blackThumbnailB64 =
    "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEB" +
    "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQ" +
    "EBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARC" +
    "ACWASwDAREAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUF" +
    "BAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk" +
    "6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztL" +
    "W2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAA" +
    "AAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVY" +
    "nLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImK" +
    "kpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oAD" +
    "AMBAAIRAxEAPwD/AD/6ACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKA" +
    "CgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACg" +
    "AoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKAC" +
    "gAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAo" +
    "AKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACg" +
    "AoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACg" +
    "AoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKA" +
    "CgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKA" +
    "CgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoA" +
    "KACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACg" +
    "AoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAo" +
    "AKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKA" +
    "CgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAK" +
    "ACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoA" +
    "KACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAo" +
    "AKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAo" +
    "AKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgD/9k=";
