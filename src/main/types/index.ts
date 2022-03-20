export interface ElectronFile {
    name: string;
    path: string;
    size: number;
    lastModified: number;
    type: {
        mimeType: string;
        ext: string;
    };
    createReadStream: () => Promise<ReadableStream<Uint8Array>>;
    toBlob: () => Promise<Blob>;
    toUInt8Array: () => Promise<Uint8Array>;
}
