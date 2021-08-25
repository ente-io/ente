import { FILE_TYPE } from 'services/fileService';
import { logError } from 'utils/sentry';
import { FILE_READER_CHUNK_SIZE, MULTIPART_PART_SIZE } from './uploadService';
import FileType from 'file-type/browser';

const TYPE_VIDEO = 'video';
const TYPE_IMAGE = 'image';
const EDITED_FILE_SUFFIX = '-edited';
const CHUNK_SIZE_FOR_TYPE_DETECTION = 4100;

export async function getFileData(worker, file: globalThis.File) {
    if (file.size > MULTIPART_PART_SIZE) {
        return getFileStream(worker, file, FILE_READER_CHUNK_SIZE);
    } else {
        return await worker.getUint8ArrayView(file);
    }
}

export interface FileTypeInfo {
    fileType: FILE_TYPE;
    exactType: string;
}

export async function getFileType(
    worker,
    receivedFile: globalThis.File
): Promise<FileTypeInfo> {
    let fileType: FILE_TYPE;
    const mimeType = await getMimeType(worker, receivedFile);
    const typeParts = mimeType?.split('/');
    if (typeParts?.length !== 2) {
        return { fileType: FILE_TYPE.OTHERS, exactType: null };
    }
    switch (typeParts[0]) {
        case TYPE_IMAGE:
            fileType = FILE_TYPE.IMAGE;
            break;
        case TYPE_VIDEO:
            fileType = FILE_TYPE.VIDEO;
            break;
        default:
            fileType = FILE_TYPE.OTHERS;
    }
    return { fileType, exactType: typeParts[1] };
}

/*
    Get the original file name for edited file to associate it to original file's metadataJSON file 
    as edited file doesn't have their own metadata file
*/
export function getFileOriginalName(file: globalThis.File) {
    let originalName: string = null;

    const isEditedFile = file.name.endsWith(EDITED_FILE_SUFFIX);
    if (isEditedFile) {
        originalName = file.name.slice(0, -1 * EDITED_FILE_SUFFIX.length);
    } else {
        originalName = file.name;
    }
    return originalName;
}

async function getMimeType(worker, file: globalThis.File) {
    const fileChunkBlob = file.slice(0, CHUNK_SIZE_FOR_TYPE_DETECTION);
    return getMimeTypeFromBlob(worker, fileChunkBlob);
}

export async function getMimeTypeFromBlob(worker, fileBlob: Blob) {
    const initialFiledata = await worker.getUint8ArrayView(fileBlob);
    const result = await FileType.fromBuffer(initialFiledata);
    return result?.mime;
}

function getFileStream(worker, file: globalThis.File, chunkSize: number) {
    const fileChunkReader = fileChunkReaderMaker(worker, file, chunkSize);

    const stream = new ReadableStream<Uint8Array>({
        async pull(controller: ReadableStreamDefaultController) {
            const chunk = await fileChunkReader.next();
            if (chunk.done) {
                controller.close();
            } else {
                controller.enqueue(chunk.value);
            }
        },
    });
    const chunkCount = Math.ceil(file.size / chunkSize);
    return {
        stream,
        chunkCount,
    };
}

async function* fileChunkReaderMaker(
    worker,
    file: globalThis.File,
    chunkSize: number
) {
    let offset = 0;
    while (offset < file.size) {
        const blob = file.slice(offset, chunkSize + offset);
        const fileChunk = await worker.getUint8ArrayView(blob);
        yield fileChunk;
        offset += chunkSize;
    }
    return null;
}

export async function getUint8ArrayView(
    reader: FileReader,
    file: Blob
): Promise<Uint8Array> {
    try {
        return await new Promise((resolve, reject) => {
            reader.onabort = () => reject(Error('file reading was aborted'));
            reader.onerror = () => reject(Error('file reading has failed'));
            reader.onload = () => {
                // Do whatever you want with the file contents
                const result =
                    typeof reader.result === 'string'
                        ? new TextEncoder().encode(reader.result)
                        : new Uint8Array(reader.result);
                resolve(result);
            };
            reader.readAsArrayBuffer(file);
        });
    } catch (e) {
        logError(e, 'error reading file to byte-array');
        throw e;
    }
}
