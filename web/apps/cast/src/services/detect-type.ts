import { KnownFileTypeInfos } from "@/media/file-type";
import { nameAndExtension } from "@/next/file";
import { fileTypeFromBlob } from "file-type";

/**
 * Try to deduce the MIME type for the given {@link file}. Return the MIME type
 * string if successful _and_ if it is an image or a video, otherwise return
 * `undefined`.
 *
 * It first peeks into the file's initial contents to detect the MIME type. If
 * that doesn't give any results, it tries to deduce it from the file's name.
 */
export const detectMediaMIMEType = async (file: File): Promise<string> => {
    const mime = (await fileTypeFromBlob(file))?.mime;
    if (mime) {
        if (mime.startsWith("image/") || mime.startsWith("video/")) return mime;
        else throw new Error(`Detected MIME type ${mime} is not a media file`);
    }

    let [, ext] = nameAndExtension(file.name);
    if (!ext) return undefined;
    ext = ext.toLowerCase();
    return KnownFileTypeInfos.find((f) => f.exactType == ext)?.mimeType;
};
