import { ElectronFile } from 'types/upload';

export async function getUint8ArrayView(
    reader: FileReader,
    file: Blob
): Promise<Uint8Array> {
    return await new Promise((resolve, reject) => {
        reader.onabort = () => reject(Error('file reading was aborted'));
        reader.onerror = () => {
            reject(Error('file reading has failed - ' + reader.error));
        };
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

export function getFileStream(
    reader: FileReader,
    file: File,
    chunkSize: number
) {
    const fileChunkReader = fileChunkReaderMaker(reader, file, chunkSize);

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

async function* fileChunkReaderMaker(
    reader: FileReader,
    file: File,
    chunkSize: number
) {
    let offset = 0;
    while (offset < file.size) {
        const blob = file.slice(offset, chunkSize + offset);
        const fileChunk = await getUint8ArrayView(reader, blob);
        yield fileChunk;
        offset += chunkSize;
    }
    return null;
}
