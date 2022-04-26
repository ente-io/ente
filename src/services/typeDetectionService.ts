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
    reader: FileReader,
    receivedFile: File | ElectronFile
): Promise<FileTypeInfo> {
    try {
        let fileType: FILE_TYPE;
        let typeResult: FileTypeResult;

        if (receivedFile instanceof File) {
            typeResult = await extractFileType(reader, receivedFile);
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

async function extractFileType(reader: FileReader, file: File) {
    const fileChunkBlob = file.slice(0, CHUNK_SIZE_FOR_TYPE_DETECTION);
    return getFileTypeFromBlob(reader, fileChunkBlob);
}

async function extractElectronFileType(file: ElectronFile) {
    const stream = await file.stream();
    const reader = stream.getReader();
    const { value } = await reader.read();
    const fileTypeResult = await FileType.fromBuffer(value);
    return fileTypeResult;
}

async function getFileTypeFromBlob(reader: FileReader, fileBlob: Blob) {
    try {
        const initialFiledata = await getUint8ArrayView(reader, fileBlob);
        return await FileType.fromBuffer(initialFiledata);
    } catch (e) {
        throw Error(CustomError.TYPE_DETECTION_FAILED);
    }
}
