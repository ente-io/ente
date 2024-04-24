import {
    FILE_TYPE,
    KnownFileTypeInfos,
    KnownNonMediaFileExtensions,
    type FileTypeInfo,
} from "@/media/file-type";
import log from "@/next/log";
import { ElectronFile } from "@/next/types/file";
import { CustomError } from "@ente/shared/error";
import FileType, { type FileTypeResult } from "file-type";
import { getFileExtension } from "utils/file";
import { getUint8ArrayView } from "./readerService";

const TYPE_VIDEO = "video";
const TYPE_IMAGE = "image";
const CHUNK_SIZE_FOR_TYPE_DETECTION = 4100;

/**
 * Read the file's initial contents or use the file's name to deduce its type.
 *
 * This function first reads an initial chunk of the file and tries to deduce
 * the file's {@link FileTypeInfo} from it. If that doesn't work, it then falls
 * back to using the file's name to deduce it.
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
 * @returns The deduced {@link FileTypeInfo}.
 */
export const deduceFileTypeInfo = async (
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
            case TYPE_IMAGE:
                fileType = FILE_TYPE.IMAGE;
                break;
            case TYPE_VIDEO:
                fileType = FILE_TYPE.VIDEO;
                break;
            default:
                throw Error(CustomError.NON_MEDIA_FILE);
        }
        return {
            fileType,
            exactType: typeResult.ext,
            mimeType: typeResult.mime,
        };
    } catch (e) {
        const fileFormat = getFileExtension(fileOrPath.name);
        const whiteListedFormat = KnownFileTypeInfos.find(
            (a) => a.exactType === fileFormat,
        );
        if (whiteListedFormat) {
            return whiteListedFormat;
        }
        if (KnownNonMediaFileExtensions.includes(fileFormat)) {
            throw Error(CustomError.UNSUPPORTED_FILE_FORMAT);
        }
        if (e.message === CustomError.NON_MEDIA_FILE) {
            log.error(`unsupported file format ${fileFormat}`, e);
            throw Error(CustomError.UNSUPPORTED_FILE_FORMAT);
        }
        log.error(`type detection failed for format ${fileFormat}`, e);
        throw new Error(`type detection failed ${fileFormat}`);
    }
};

async function extractFileType(file: File) {
    const fileBlobChunk = file.slice(0, CHUNK_SIZE_FOR_TYPE_DETECTION);
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
    if (!result?.mime) {
        let logableInfo = "";
        try {
            logableInfo = `result: ${JSON.stringify(result)}`;
        } catch (e) {
            logableInfo = "failed to stringify result";
        }
        throw Error(`mimetype missing from file type result - ${logableInfo}`);
    }
    return result;
}
