import { logError } from "@ente/shared/sentry";
import { convertBytesToHumanReadable } from "@ente/shared/utils/size";
import { ElectronFile } from "types/upload";

export async function getUint8ArrayView(
    file: Blob | ElectronFile,
): Promise<Uint8Array> {
    try {
        return new Uint8Array(await file.arrayBuffer());
    } catch (e) {
        logError(e, "reading file blob failed", {
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
    chunkSize: number,
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
