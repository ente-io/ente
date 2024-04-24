import { KnownFileTypeInfos } from "@/media/file-type";
import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import FileType from "file-type";

/**
 * Try to deduce the MIME type for the given {@link file}. Return the MIME type
 * string if successful _and_ if it is an image or a video, otherwise return
 * `undefined`.
 *
 * It first peeks into the file's initial contents to detect the MIME type. If
 * that doesn't give any results, it tries to deduce it from the file's name.
 */
export const tryDetectMediaMIMEType = async (file: File): Promise<string> => {
    const chunkSizeForTypeDetection = 4100;

    let mime: string | undefined;
    try {
        const fileChunk = file.slice(0, chunkSizeForTypeDetection);
        const chunkData = new Uint8Array(await fileChunk.arrayBuffer());
        const result = await FileType.fromBuffer(chunkData);
        mime = result?.mime;
    } catch (e) {
        log.error(
            `Failed to deduce MIME type from file contents for ${file}, will try with the file name instead`,
            e,
        );
    }

    if (mime) {
        if (mime.startsWith("image/") || mime.startsWith("video/")) return mime;
        else throw new Error(`Detected MIME type ${mime} is not a media file`);
    }

    let [, ext] = nameAndExtension(file.name);
    if (!ext) return undefined;
    ext = ext.toLowerCase();
    return KnownFileTypeInfos.find((f) => f.exactType == ext)?.mimeType;
};
