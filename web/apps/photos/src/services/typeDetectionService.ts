import {
    FILE_TYPE,
    KnownFileTypeInfos,
    KnownNonMediaFileExtensions,
    type FileTypeInfo,
} from "@/media/file-type";
import { lowercaseExtension } from "@/next/file";
import { ElectronFile } from "@/next/types/file";
import { CustomError } from "@ente/shared/error";
import FileType, { type FileTypeResult } from "file-type";
import { getUint8ArrayView } from "./readerService";

/**
 * Read the file's initial contents or use the file's name to detect its type.
 *
 * This function first reads an initial chunk of the file and tries to detect
 * the file's {@link FileTypeInfo} from it. If that doesn't work, it then falls
 * back to using the file's name to detect it.
 *
 * If neither of these two approaches work, it throws an exception.
 *
 * If we were able to detect the file type, but it is explicitly not a media
 * (image or video) format that we support, this function throws an error with
 * the message `CustomError.UNSUPPORTED_FILE_FORMAT`.
 *
 * @param fileOrPath A {@link File} object, or the path to the file on the
 * user's local filesystem. It is only valid to provide a path if we're running
 * in the context of our desktop app.
 *
 * @returns The detected {@link FileTypeInfo}.
 */
export const detectFileTypeInfo = async (
    fileOrPath: File | ElectronFile,
): Promise<FileTypeInfo> => {
    try {
        let fileType: FILE_TYPE;
        let typeResult: FileTypeResult;

        if (fileOrPath instanceof File) {
            typeResult = await extractFileType(fileOrPath);
        } else {
            typeResult = await extractElectronFileType(fileOrPath);
        }

        const mimTypeParts: string[] = typeResult.mime?.split("/");

        if (mimTypeParts?.length !== 2) {
            throw Error(CustomError.INVALID_MIME_TYPE(typeResult.mime));
        }
        switch (mimTypeParts[0]) {
            case "image":
                fileType = FILE_TYPE.IMAGE;
                break;
            case "video":
                fileType = FILE_TYPE.VIDEO;
                break;
            default:
                throw new Error(CustomError.UNSUPPORTED_FILE_FORMAT);
        }
        return {
            fileType,
            extension: typeResult.ext,
            mimeType: typeResult.mime,
        };
    } catch (e) {
        const extension = lowercaseExtension(fileOrPath.name);
        const known = KnownFileTypeInfos.find((f) => f.extension == extension);
        if (known) return known;

        if (KnownNonMediaFileExtensions.includes(extension))
            throw Error(CustomError.UNSUPPORTED_FILE_FORMAT);

        throw e;
    }
};

async function extractFileType(file: File) {
    const chunkSizeForTypeDetection = 4100;
    const fileBlobChunk = file.slice(0, chunkSizeForTypeDetection);
    const fileDataChunk = await getUint8ArrayView(fileBlobChunk);
    return getFileTypeFromBuffer(fileDataChunk);
}

async function extractElectronFileType(file: ElectronFile) {
    const stream = await file.stream();
    const reader = stream.getReader();
    const { value: fileDataChunk } = await reader.read();
    await reader.cancel();
    return getFileTypeFromBuffer(fileDataChunk);
}

async function getFileTypeFromBuffer(buffer: Uint8Array) {
    const result = await FileType.fromBuffer(buffer);
    if (!result?.ext || !result?.mime) {
        throw Error(`Could not deduce file type from buffer`);
    }
    return result;
}
