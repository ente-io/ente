import { DataStream, EncryptionResult, isDataStream } from './uploadService';

async function encryptFileStream(worker, fileData: DataStream) {
    const { stream, chunkCount } = fileData;
    const fileStreamReader = stream.getReader();
    const { key, decryptionHeader, pushState } =
        await worker.initChunkEncryption();
    const ref = { pullCount: 1 };
    const encryptedFileStream = new ReadableStream({
        async pull(controller) {
            const { value } = await fileStreamReader.read();
            const encryptedFileChunk = await worker.encryptFileChunk(
                value,
                pushState,
                ref.pullCount === chunkCount,
            );
            controller.enqueue(encryptedFileChunk);
            if (ref.pullCount === chunkCount) {
                controller.close();
            }
            ref.pullCount++;
        },
    });
    return {
        key,
        file: {
            decryptionHeader,
            encryptedData: { stream: encryptedFileStream, chunkCount },
        },
    };
}

export async function encryptFiledata(
    worker,
    filedata: Uint8Array | DataStream,
): Promise<EncryptionResult> {
    return isDataStream(filedata)
        ? await encryptFileStream(worker, filedata)
        : await worker.encryptFile(filedata);
}
