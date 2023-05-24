import { FILE_TYPE } from 'constants/file';
import { ElectronFile, FileTypeInfo } from 'types/upload';
import {
    WHITELISTED_FILE_FORMATS,
    KNOWN_NON_MEDIA_FORMATS,
} from 'constants/upload';
import { CustomError } from 'utils/error';
import { getFileExtension } from 'utils/file';
import { logError } from 'utils/sentry';
import { getUint8ArrayView } from './readerService';
import FileType, { FileTypeResult } from 'file-type';
import { getFileSize } from './upload/fileService';
import { convertBytesToHumanReadable } from 'utils/file/size';

const TYPE_VIDEO = 'video';
const TYPE_IMAGE = 'image';
const CHUNK_SIZE_FOR_TYPE_DETECTION = 4100;

export async function getFileType(
    receivedFile: File | ElectronFile
): Promise<FileTypeInfo> {
    try {
        let fileType: FILE_TYPE;
        let typeResult: FileTypeResult;

        if (receivedFile instanceof File) {
            typeResult = await extractFileType(receivedFile);
        } else {
            typeResult = await extractElectronFileType(receivedFile);
        }

        const mimTypeParts: string[] = typeResult.mime?.split('/');

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
        const fileFormat = getFileExtension(receivedFile.name);
        const fileSize = convertBytesToHumanReadable(getFileSize(receivedFile));
        const whiteListedFormat = WHITELISTED_FILE_FORMATS.find(
            (a) => a.exactType === fileFormat
        );
        if (whiteListedFormat) {
            return whiteListedFormat;
        }
        if (KNOWN_NON_MEDIA_FORMATS.includes(fileFormat)) {
            throw Error(CustomError.UNSUPPORTED_FILE_FORMAT);
        }
        if (e.message === CustomError.NON_MEDIA_FILE) {
            logError(e, 'unsupported file format', {
                fileFormat,
                fileSize,
            });
            throw Error(CustomError.UNSUPPORTED_FILE_FORMAT);
        }
        logError(e, 'type detection failed', {
            fileFormat,
            fileSize,
        });
        throw Error(CustomError.TYPE_DETECTION_FAILED(fileFormat));
    }
}

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
        let logableInfo = '';
        try {
            logableInfo = `result: ${JSON.stringify(result)}`;
        } catch (e) {
            logableInfo = 'failed to stringify result';
        }
        throw Error(`mimetype missing from file type result - ${logableInfo}`);
    }
    return result;
}
