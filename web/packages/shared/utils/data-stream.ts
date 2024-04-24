export interface DataStream {
    stream: ReadableStream<Uint8Array>;
    chunkCount: number;
}

export function isDataStream(object: any): object is DataStream {
    return "stream" in object;
}
