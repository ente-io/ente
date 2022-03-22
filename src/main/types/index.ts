export interface ElectronFile {
    name: string;
    path: string;
    size: number;
    lastModified: number;
    type: {
        mimeType: string;
        ext: string;
    };
    stream: () => Promise<ReadableStream<Uint8Array>>;
    blob: () => Promise<Blob>;
    arrayBuffer: () => Promise<Uint8Array>;
}

export interface StoreType {
    done: boolean;
    filesPaths: string[];
    collectionName: string;
    collectionIDs: number[];
}
