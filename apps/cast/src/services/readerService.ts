import { logError } from '@ente/shared/sentry';
import { convertBytesToHumanReadable } from '@ente/shared/utils/size';
import { ElectronFile } from 'types/upload';

export async function getUint8ArrayView(
    file: Blob | ElectronFile
): Promise<Uint8Array> {
    try {
        return new Uint8Array(await file.arrayBuffer());
    } catch (e) {
        logError(e, 'reading file blob failed', {
            fileSize: convertBytesToHumanReadable(file.size),
        });
        throw e;
    }
}

export function getFileStream(file: File, chunkSize: number) {
    const fileChunkReader = fileChunkReaderMaker(file, chunkSize);

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

export async function getElectronFileStream(
    file: ElectronFile,
    chunkSize: number
) {
    const chunkCount = Math.ceil(file.size / chunkSize);
    return {
        stream: await file.stream(),
        chunkCount,
    };
}

async function* fileChunkReaderMaker(file: File, chunkSize: number) {
    let offset = 0;
    while (offset < file.size) {
        const blob = file.slice(offset, chunkSize + offset);
        const fileChunk = await getUint8ArrayView(blob);
        yield fileChunk;
        offset += chunkSize;
    }
    return null;
}

// depreciated
// eslint-disable-next-line @typescript-eslint/no-unused-vars
async function getUint8ArrayViewOld(
    reader: FileReader,
    file: Blob
): Promise<Uint8Array> {
    return await new Promise((resolve, reject) => {
        reader.onabort = () =>
            reject(
                Error(
                    `file reading was aborted, file size= ${convertBytesToHumanReadable(
                        file.size
                    )}`
                )
            );
        reader.onerror = () =>
            reject(
                Error(
                    `file reading has failed, file size= ${convertBytesToHumanReadable(
                        file.size
                    )} , reason= ${reader.error}`
                )
            );
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
}
