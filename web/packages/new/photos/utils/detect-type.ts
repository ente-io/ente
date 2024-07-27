import { lowercaseExtension } from "@/base/file";
import {
    FileType,
    KnownFileTypeInfos,
    KnownNonMediaFileExtensions,
    type FileTypeInfo,
} from "@/media/file-type";
import { CustomError } from "@ente/shared/error";

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
 * @param file A {@link File} object
 *
 * @returns The detected {@link FileTypeInfo}.
 */
export const detectFileTypeInfo = async (file: File): Promise<FileTypeInfo> =>
    detectFileTypeInfoFromChunk(() => readInitialChunkOfFile(file), file.name);

/**
 * The lower layer implementation of the type detector.
 *
 * Usually, when the code already has a {@link File} object at hand, it is
 * easier to use the higher level {@link detectFileTypeInfo} function.
 *
 * However, this lower level function is also exposed for use in cases like
 * during upload where we might not have a File object and would like to provide
 * the initial chunk of the file's contents in a different way.
 *
 * @param readInitialChunk A function to call to read the initial chunk of the
 * file's data. There is no strict requirement for the size of the chunk this
 * function should return, generally the first few KBs should be good.
 *
 * @param fileNameOrPath The full path or just the file name of the file whose
 * type we're trying to determine. This is used by the fallback layer that tries
 * to detect the type info from the file's extension.
 */
export const detectFileTypeInfoFromChunk = async (
    readInitialChunk: () => Promise<Uint8Array>,
    fileNameOrPath: string,
): Promise<FileTypeInfo> => {
    try {
        const typeResult = await detectFileTypeFromBuffer(
            await readInitialChunk(),
        );

        const mimeType = typeResult.mime;

        let fileType: FileType;
        if (mimeType.startsWith("image/")) {
            fileType = FileType.image;
        } else if (mimeType.startsWith("video/")) {
            fileType = FileType.video;
        } else {
            throw new Error(CustomError.UNSUPPORTED_FILE_FORMAT);
        }

        return {
            fileType,
            // See https://github.com/sindresorhus/file-type/blob/main/core.d.ts
            // for the full list of ext values.
            extension: typeResult.ext,
            mimeType,
        };
    } catch (e) {
        const extension = lowercaseExtension(fileNameOrPath);
        const known = KnownFileTypeInfos.find((f) => f.extension == extension);
        if (known) return known;

        if (extension && KnownNonMediaFileExtensions.includes(extension))
            throw Error(CustomError.UNSUPPORTED_FILE_FORMAT);

        throw e;
    }
};

const readInitialChunkOfFile = async (file: File) => {
    const chunkSizeForTypeDetection = 4100;
    const chunk = file.slice(0, chunkSizeForTypeDetection);
    return new Uint8Array(await chunk.arrayBuffer());
};

const detectFileTypeFromBuffer = async (buffer: Uint8Array) => {
    const result = await FileType.fromBuffer(buffer);
    if (!result)
        throw Error("Could not deduce file type from the file's contents");
    return result;
};
