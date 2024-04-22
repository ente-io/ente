import type { Electron } from "./ipc";

export enum UPLOAD_STRATEGY {
    SINGLE_COLLECTION,
    COLLECTION_PER_FOLDER,
}

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
 * A file path that we obtain from the Node.js layer of our desktop app.
 *
 * When a user drags and drops or otherwise interactively provides us with a
 * file, we get an object that conforms to the [Web File
 * API](https://developer.mozilla.org/en-US/docs/Web/API/File).
 *
 * However, we cannot programmatically create such File objects to arbitrary
 * absolute paths on user's local filesystem for security reasons.
 *
 * This restricts us in cases where the user does want us to, say, watch a
 * folder on disk for changes, or auto-resume previously interrupted uploads
 * when the app gets restarted.
 *
 * For such functionality, we defer to our Node.js layer via the
 * {@link Electron} object. This IPC communication works with absolute paths of
 * disk files or folders, and the native Node.js layer can then perform the
 * relevant operations on them.
 *
 * The {@link DesktopFilePath} interface bundles such a absolute {@link path}
 * with an {@link Electron} object that we can later use to, say, read or write
 * to that file by using the IPC methods.
 *
 * This is the same electron instance as `globalThis.electron`, except it is
 * non-optional here. Thus we're guaranteed that whatever code is passing us an
 * absolute file path is running in the context of our desktop app.
 */
export interface DesktopFilePath {
    /** The absolute path to a file or a folder on the local filesystem. */
    path: string;
    /** The {@link Electron} instance that we can use to operate on the path. */
    electron: Electron;
}

export interface DataStream {
    stream: ReadableStream<Uint8Array>;
    chunkCount: number;
}

export interface EventQueueItem {
    type: "upload" | "trash";
    folderPath: string;
    collectionName?: string;
    paths?: string[];
    files?: ElectronFile[];
}
