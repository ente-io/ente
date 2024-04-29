/*
 * ElectronFile is a custom interface that is used to represent
 * any file on disk as a File-like object in the Electron desktop app.
 *
 * This was added to support the auto-resuming of failed uploads
 * which needed absolute paths to the files which the
 * normal File interface does not provide.
 */
export interface ElectronFile {
    name: string;
    path: string;
    size: number;
    lastModified: number;
    stream: () => Promise<ReadableStream<Uint8Array>>;
    blob: () => Promise<Blob>;
    arrayBuffer: () => Promise<Uint8Array>;
}

/**
 * When we are running in the context of our desktop app, we have access to the
 * absolute path of the file under consideration. This type combines these two
 * bits of information to remove the need to query it again and again.
 */
export interface FileAndPath {
    file: File;
    path: string;
}

export interface EventQueueItem {
    type: "upload" | "trash";
    folderPath: string;
    collectionName?: string;
    paths?: string[];
    files?: ElectronFile[];
}
