import { ElectronFile } from "@/next/types/file";

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

async function* fileChunkReaderMaker(file: File, chunkSize: number) {
    let offset = 0;
    while (offset < file.size) {
        const chunk = file.slice(offset, chunkSize + offset);
        yield new Uint8Array(await chunk.arrayBuffer());
        offset += chunkSize;
    }
    return null;
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
