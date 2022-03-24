import { FILE_TYPE } from 'constants/file';
import { ElectronFile, FileTypeInfo } from 'types/upload';
import { CustomError } from 'utils/error';
import { getFileExtension } from 'utils/file';
import { logError } from 'utils/sentry';
import { getUint8ArrayView } from './readerService';
import FileType, { FileTypeResult } from 'file-type';

const TYPE_VIDEO = 'video';
const TYPE_IMAGE = 'image';
const CHUNK_SIZE_FOR_TYPE_DETECTION = 4100;

// list of format whose detection should be skipped
export const FORMATS_TO_SKIP_TYPE_DETECTION = [
    { fileType: FILE_TYPE.IMAGE, exactType: 'jpeg' },
    { fileType: FILE_TYPE.IMAGE, exactType: 'jpg' },
];

export async function getFileType(
    reader: FileReader,
    receivedFile: File | ElectronFile
): Promise<FileTypeInfo> {
    const fileExtension = getFileExtension(receivedFile.name);
    try {
        const formatToBeSkipped = FORMATS_TO_SKIP_TYPE_DETECTION.find(
            (a) => a.exactType === fileExtension
        );
        if (formatToBeSkipped) {
            return formatToBeSkipped;
        }
        let fileType: FILE_TYPE;
        let typeResult: FileTypeResult;

        if (receivedFile instanceof File) {
            typeResult = await extractFileType(reader, receivedFile);
        } else {
            typeResult = await extractFileTypeFromElectronFile(receivedFile);
            console.log('typeResult', typeResult);
        }

        const mimTypeParts: string[] = typeResult.mime?.split('/');
        const ext: string = typeResult.ext;

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
        return { fileType, exactType: ext };
    } catch (e) {
        logError(e, CustomError.TYPE_DETECTION_FAILED, {
            fileExtension,
        });
        return { fileType: FILE_TYPE.OTHERS, exactType: fileExtension };
    }
}

async function extractFileType(reader: FileReader, file: File) {
    const fileChunkBlob = file.slice(0, CHUNK_SIZE_FOR_TYPE_DETECTION);
    return getFileTypeFromBlob(reader, fileChunkBlob);
}

async function extractFileTypeFromElectronFile(file: ElectronFile) {
    const stream = await file.stream();
    const reader = stream.getReader();
    const { value } = await reader.read();
    const fileTypeResult = await FileType.fromBuffer(value);
    return fileTypeResult;
}

export async function getFileTypeFromBlob(reader: FileReader, fileBlob: Blob) {
    try {
        const initialFiledata = await getUint8ArrayView(reader, fileBlob);
        return await FileType.fromBuffer(initialFiledata);
    } catch (e) {
        throw Error(CustomError.TYPE_DETECTION_FAILED);
    }
}
