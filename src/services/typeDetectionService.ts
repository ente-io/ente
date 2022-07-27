import { FILE_TYPE } from 'constants/file';
import { ElectronFile, FileTypeInfo } from 'types/upload';
import { FORMAT_MISSED_BY_FILE_TYPE_LIB } from 'constants/upload';
import { CustomError } from 'utils/error';
import { getFileExtension } from 'utils/file';
import { logError } from 'utils/sentry';
import { getUint8ArrayView } from './readerService';
import FileType, { FileTypeResult } from 'file-type';

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
            throw Error(CustomError.TYPE_DETECTION_FAILED);
        }
        switch (mimTypeParts[0]) {
            case TYPE_IMAGE:
                fileType = FILE_TYPE.IMAGE;
                break;
            case TYPE_VIDEO:
                fileType = FILE_TYPE.VIDEO;
                break;
            default:
                fileType = FILE_TYPE.OTHERS;
        }
        return {
            fileType,
            exactType: typeResult.ext,
            mimeType: typeResult.mime,
        };
    } catch (e) {
        const fileFormat = getFileExtension(receivedFile.name);
        const formatMissedByTypeDetection = FORMAT_MISSED_BY_FILE_TYPE_LIB.find(
            (a) => a.exactType === fileFormat
        );
        if (formatMissedByTypeDetection) {
            return formatMissedByTypeDetection;
        }
        logError(e, CustomError.TYPE_DETECTION_FAILED, {
            fileFormat,
        });
        return {
            fileType: FILE_TYPE.OTHERS,
            exactType: fileFormat,
            mimeType: receivedFile instanceof File ? receivedFile.type : null,
        };
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
    return getFileTypeFromBuffer(fileDataChunk);
}

async function getFileTypeFromBuffer(buffer: Uint8Array) {
    try {
        const result = await FileType.fromBuffer(buffer);
        if (!result.mime) {
            logError(
                Error('mimetype missing from file type result'),
                CustomError.TYPE_DETECTION_FAILED,
                { result }
            );
            throw Error(CustomError.TYPE_DETECTION_FAILED);
        }
        return result;
    } catch (e) {
        throw Error(CustomError.TYPE_DETECTION_FAILED);
    }
}
