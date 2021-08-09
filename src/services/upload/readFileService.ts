import { FILE_TYPE } from 'pages/gallery';
import { ENCRYPTION_CHUNK_SIZE } from 'types';
import { logError } from 'utils/sentry';

const TYPE_VIDEO = 'video';
const TYPE_HEIC = 'HEIC';
export const TYPE_IMAGE = 'image';
const MIN_STREAM_FILE_SIZE = 20 * 1024 * 1024;
const EDITED_FILE_SUFFIX = '-edited';


export async function getFileData(reader:FileReader, file:globalThis.File) {
    return file.size > MIN_STREAM_FILE_SIZE ?
        getFileStream(reader, file) :
        await getUint8ArrayView(reader, file);
}

export function getFileType(receivedFile:globalThis.File) {
    let fileType: FILE_TYPE;
    switch (receivedFile.type.split('/')[0]) {
        case TYPE_IMAGE:
            fileType = FILE_TYPE.IMAGE;
            break;
        case TYPE_VIDEO:
            fileType = FILE_TYPE.VIDEO;
            break;
        default:
            fileType = FILE_TYPE.OTHERS;
    }
    if (
        fileType === FILE_TYPE.OTHERS &&
        receivedFile.type.length === 0 &&
        receivedFile.name.endsWith(TYPE_HEIC)
    ) {
        fileType = FILE_TYPE.IMAGE;
    }
    return fileType;
}


export function getFileOriginalName(file:globalThis.File) {
    let originalName:string=null;

    const isEditedFile=file.name.endsWith(EDITED_FILE_SUFFIX);
    if (isEditedFile) {
        originalName = file.name.slice(
            0,
            -1 * EDITED_FILE_SUFFIX.length,
        );
    } else {
        originalName=file.name;
    }
    return originalName;
}

function getFileStream(reader: FileReader, file: globalThis.File) {
    const fileChunkReader = fileChunkReaderMaker(reader, file);
    return {
        stream: new ReadableStream<Uint8Array>({
            async pull(controller: ReadableStreamDefaultController) {
                const chunk = await fileChunkReader.next();
                if (chunk.done) {
                    controller.close();
                } else {
                    controller.enqueue(chunk.value);
                }
            },
        }),
        chunkCount: Math.ceil(file.size / ENCRYPTION_CHUNK_SIZE),
    };
}

async function* fileChunkReaderMaker(reader:FileReader, file:globalThis.File) {
    let offset = 0;
    while (offset < file.size) {
        const blob = file.slice(offset, ENCRYPTION_CHUNK_SIZE + offset);
        const fileChunk = await getUint8ArrayView(reader, blob);
        yield fileChunk;
        offset += ENCRYPTION_CHUNK_SIZE;
    }
    return null;
}

export async function getUint8ArrayView(
    reader: FileReader,
    file: Blob,
): Promise<Uint8Array> {
    try {
        return await new Promise((resolve, reject) => {
            reader.onabort = () => reject(Error('file reading was aborted'));
            reader.onerror = () => reject(Error('file reading has failed'));
            reader.onload = () => {
                // Do whatever you want with the file contents
                const result =
                    typeof reader.result === 'string' ?
                        new TextEncoder().encode(reader.result) :
                        new Uint8Array(reader.result);
                resolve(result);
            };
            reader.readAsArrayBuffer(file);
        });
    } catch (e) {
        logError(e, 'error reading file to byte-array');
        throw e;
    }
}


