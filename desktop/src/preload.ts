/**
 * @file The preload script
 *
 * The preload script runs in a renderer process before its web contents begin
 * loading. During their execution they have access to a subset of Node.js APIs
 * and imports. Its purpose is to expose the relevant imports and other
 * functions as an object on the DOM, so that the renderer process can invoke
 * functions that live in the main (Node.js) process if needed.
 *
 * Ref: https://www.electronjs.org/docs/latest/tutorial/tutorial-preload
 *
 * Note that this script cannot import other code from `src/` - conceptually it
 * can be thought of as running in a separate, third, process different from
 * both the main or a renderer process (technically, it runs in a BrowserWindow
 * context that runs prior to the renderer process).
 *
 * > Since enabling the sandbox disables Node.js integration in your preload
 * > scripts, you can no longer use require("../my-script"). In other words,
 * > your preload script needs to be a single file.
 * >
 * > https://www.electronjs.org/blog/breach-to-barrier
 *
 * If we really wanted, we could setup a bundler to package this into a single
 * file. However, since this is just boilerplate code providing a bridge between
 * the main and renderer, we avoid introducing another moving part into the mix
 * and just keep the entire preload setup in this single file.
 */

import { contextBridge, ipcRenderer } from "electron";
import { createWriteStream, existsSync } from "node:fs";
import * as fs from "node:fs/promises";
import { Readable } from "node:stream";
import path from "path";
import { runFFmpegCmd } from "./api/ffmpeg";
import { getDirFiles } from "./api/fs";
import { convertToJPEG, generateImageThumbnail } from "./api/imageProcessor";
import { getEncryptionKey, setEncryptionKey } from "./api/safeStorage";
import {
    registerForegroundEventListener,
    registerUpdateEventListener,
} from "./api/system";
import {
    getElectronFilesFromGoogleZip,
    getPendingUploads,
    setToUploadCollection,
    setToUploadFiles,
    showUploadDirsDialog,
    showUploadFilesDialog,
    showUploadZipDialog,
} from "./api/upload";
import {
    addWatchMapping,
    getWatchMappings,
    registerWatcherFunctions,
    removeWatchMapping,
    updateWatchMappingIgnoredFiles,
    updateWatchMappingSyncedFiles,
} from "./api/watch";
import { logErrorSentry, setupLogging } from "./main/log";

setupLogging();

// - General

/** Return the version of the desktop app. */
const appVersion = (): Promise<string> => ipcRenderer.invoke("appVersion");

/**
 * Open the given {@link dirPath} in the system's folder viewer.
 *
 * For example, on macOS this'll open {@link dirPath} in Finder.
 */
const openDirectory = (dirPath: string): Promise<void> =>
    ipcRenderer.invoke("openDirectory");

/**
 * Open the app's log directory in the system's folder viewer.
 *
 * @see {@link openDirectory}
 */
const openLogDirectory = (): Promise<void> =>
    ipcRenderer.invoke("openLogDirectory");

/**
 * Log the given {@link message} to the on-disk log file maintained by the
 * desktop app.
 */
const logToDisk = (message: string): void =>
    ipcRenderer.send("logToDisk", message);

/**
 * Return true if there is a file or directory at the given
 * {@link path}.
 */
const fsExists = (path: string): Promise<boolean> =>
    ipcRenderer.invoke("fsExists", path);

// - AUDIT below this

const checkExistsAndCreateDir = (dirPath: string): Promise<void> =>
    ipcRenderer.invoke("checkExistsAndCreateDir", dirPath);

// - FIXME below this

/* preload: duplicated logError */
const logError = (error: Error, message: string, info?: any) => {
    logErrorSentry(error, message, info);
};

/* preload: duplicated writeStream */
/**
 * Write a (web) ReadableStream to a file at the given {@link filePath}.
 *
 * The returned promise resolves when the write completes.
 *
 * @param filePath The local filesystem path where the file should be written.
 * @param readableStream A [web
 * ReadableStream](https://developer.mozilla.org/en-US/docs/Web/API/ReadableStream)
 */
const writeStream = (filePath: string, readableStream: ReadableStream) =>
    writeNodeStream(filePath, convertWebReadableStreamToNode(readableStream));

/**
 * Convert a Web ReadableStream into a Node.js ReadableStream
 *
 * This can be used to, for example, write a ReadableStream obtained via
 * `net.fetch` into a file using the Node.js `fs` APIs
 */
const convertWebReadableStreamToNode = (readableStream: ReadableStream) => {
    const reader = readableStream.getReader();
    const rs = new Readable();

    rs._read = async () => {
        try {
            const result = await reader.read();

            if (!result.done) {
                rs.push(Buffer.from(result.value));
            } else {
                rs.push(null);
                return;
            }
        } catch (e) {
            rs.emit("error", e);
        }
    };

    return rs;
};

const writeNodeStream = async (
    filePath: string,
    fileStream: NodeJS.ReadableStream,
) => {
    const writeable = createWriteStream(filePath);

    fileStream.on("error", (error) => {
        writeable.destroy(error); // Close the writable stream with an error
    });

    fileStream.pipe(writeable);

    await new Promise((resolve, reject) => {
        writeable.on("finish", resolve);
        writeable.on("error", async (e: unknown) => {
            if (existsSync(filePath)) {
                await fs.unlink(filePath);
            }
            reject(e);
        });
    });
};

// - Export

const saveStreamToDisk = writeStream;

const saveFileToDisk = (path: string, contents: string) =>
    fs.writeFile(path, contents);

// -

async function readTextFile(filePath: string) {
    if (!existsSync(filePath)) {
        throw new Error("File does not exist");
    }
    return await fs.readFile(filePath, "utf-8");
}

async function moveFile(
    sourcePath: string,
    destinationPath: string,
): Promise<void> {
    if (!existsSync(sourcePath)) {
        throw new Error("File does not exist");
    }
    if (existsSync(destinationPath)) {
        throw new Error("Destination file already exists");
    }
    // check if destination folder exists
    const destinationFolder = path.dirname(destinationPath);
    await fs.mkdir(destinationFolder, { recursive: true });
    await fs.rename(sourcePath, destinationPath);
}

export async function isFolder(dirPath: string) {
    try {
        const stats = await fs.stat(dirPath);
        return stats.isDirectory();
    } catch (e) {
        let err = e;
        // if code is defined, it's an error from fs.stat
        if (typeof e.code !== "undefined") {
            // ENOENT means the file does not exist
            if (e.code === "ENOENT") {
                return false;
            }
            err = Error(`fs error code: ${e.code}`);
        }
        logError(err, "isFolder failed");
        return false;
    }
}

async function deleteFolder(folderPath: string): Promise<void> {
    if (!existsSync(folderPath)) {
        return;
    }
    const stat = await fs.stat(folderPath);
    if (!stat.isDirectory()) {
        throw new Error("Path is not a folder");
    }
    // check if folder is empty
    const files = await fs.readdir(folderPath);
    if (files.length > 0) {
        throw new Error("Folder is not empty");
    }
    await fs.rmdir(folderPath);
}

async function rename(oldPath: string, newPath: string) {
    if (!existsSync(oldPath)) {
        throw new Error("Path does not exist");
    }
    await fs.rename(oldPath, newPath);
}

const deleteFile = async (filePath: string) => {
    if (!existsSync(filePath)) {
        return;
    }
    const stat = await fs.stat(filePath);
    if (!stat.isFile()) {
        throw new Error("Path is not a file");
    }
    return fs.rm(filePath);
};

// - ML

/* preload: duplicated Model */
export enum Model {
    GGML_CLIP = "ggml-clip",
    ONNX_CLIP = "onnx-clip",
}

const computeImageEmbedding = async (
    model: Model,
    imageData: Uint8Array,
): Promise<Float32Array> => {
    let tempInputFilePath = null;
    try {
        tempInputFilePath = await ipcRenderer.invoke("get-temp-file-path", "");
        const imageStream = new Response(imageData.buffer).body;
        await writeStream(tempInputFilePath, imageStream);
        const embedding = await ipcRenderer.invoke(
            "compute-image-embedding",
            model,
            tempInputFilePath,
        );
        return embedding;
    } catch (err) {
        if (isExecError(err)) {
            const parsedExecError = parseExecError(err);
            throw Error(parsedExecError);
        } else {
            throw err;
        }
    } finally {
        if (tempInputFilePath) {
            await ipcRenderer.invoke("remove-temp-file", tempInputFilePath);
        }
    }
};

export async function computeTextEmbedding(
    model: Model,
    text: string,
): Promise<Float32Array> {
    try {
        const embedding = await ipcRenderer.invoke(
            "compute-text-embedding",
            model,
            text,
        );
        return embedding;
    } catch (err) {
        if (isExecError(err)) {
            const parsedExecError = parseExecError(err);
            throw Error(parsedExecError);
        } else {
            throw err;
        }
    }
}

// -

/**
 * [Note: Custom errors across Electron/Renderer boundary]
 *
 * We need to use the `message` field to disambiguate between errors thrown by
 * the main process when invoked from the renderer process. This is because:
 *
 * > Errors thrown throw `handle` in the main process are not transparent as
 * > they are serialized and only the `message` property from the original error
 * > is provided to the renderer process.
 * >
 * > - https://www.electronjs.org/docs/latest/tutorial/ipc
 * >
 * > Ref: https://github.com/electron/electron/issues/24427
 */
/* preload: duplicated CustomErrors */
const CustomErrorsP = {
    WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED:
        "Windows native image processing is not supported",
    INVALID_OS: (os: string) => `Invalid OS - ${os}`,
    WAIT_TIME_EXCEEDED: "Wait time exceeded",
    UNSUPPORTED_PLATFORM: (platform: string, arch: string) =>
        `Unsupported platform - ${platform} ${arch}`,
    MODEL_DOWNLOAD_PENDING:
        "Model download pending, skipping clip search request",
    INVALID_FILE_PATH: "Invalid file path",
    INVALID_CLIP_MODEL: (model: string) => `Invalid Clip model - ${model}`,
};

const isExecError = (err: any) => {
    return err.message.includes("Command failed:");
};

const parseExecError = (err: any) => {
    const errMessage = err.message;
    if (errMessage.includes("Bad CPU type in executable")) {
        return CustomErrorsP.UNSUPPORTED_PLATFORM(
            process.platform,
            process.arch,
        );
    } else {
        return errMessage;
    }
};

// - General

const selectDirectory = async (): Promise<string> => {
    try {
        return await ipcRenderer.invoke("select-dir");
    } catch (e) {
        logError(e, "error while selecting root directory");
    }
};

const clearElectronStore = () => {
    ipcRenderer.send("clear-electron-store");
};

// - App update

const updateAndRestart = () => {
    ipcRenderer.send("update-and-restart");
};

const skipAppUpdate = (version: string) => {
    ipcRenderer.send("skip-app-update", version);
};

const muteUpdateNotification = (version: string) => {
    ipcRenderer.send("mute-update-notification", version);
};

// -

// These objects exposed here will become available to the JS code in our
// renderer (the web/ code) as `window.ElectronAPIs.*`
//
// There are a few related concepts at play here, and it might be worthwhile to
// read their (excellent) documentation to get an understanding;
//`
// - ContextIsolation:
//   https://www.electronjs.org/docs/latest/tutorial/context-isolation
//
// - IPC https://www.electronjs.org/docs/latest/tutorial/ipc
//
// [Note: Transferring large amount of data over IPC]
//
// Electron's IPC implementation uses the HTML standard Structured Clone
// Algorithm to serialize objects passed between processes.
// https://www.electronjs.org/docs/latest/tutorial/ipc#object-serialization
//
// In particular, both ArrayBuffer is eligible for structured cloning.
// https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm
//
// Also, ArrayBuffer is "transferable", which means it is a zero-copy operation
// operation when it happens across threads.
// https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Transferable_objects
//
// In our case though, we're not dealing with threads but separate processes. So
// the ArrayBuffer will be copied:
// > "parameters, errors and return values are **copied** when they're sent over
//   the bridge".
//   https://www.electronjs.org/docs/latest/api/context-bridge#methods
//
// The copy itself is relatively fast, but the problem with transfering large
// amounts of data is potentially running out of memory during the copy.
contextBridge.exposeInMainWorld("ElectronAPIs", {
    // General
    appVersion,
    openDirectory,

    // Logging
    openLogDirectory,
    logToDisk,

    // - App update
    updateAndRestart,
    skipAppUpdate,
    muteUpdateNotification,

    // - FS
    fs: {
        exists: fsExists,
    },

    // - FS legacy
    // TODO: Move these into fs + document + rename if needed
    checkExistsAndCreateDir,

    // - Export
    saveStreamToDisk,
    saveFileToDisk,

    selectDirectory,
    clearElectronStore,
    readTextFile,
    showUploadFilesDialog,
    showUploadDirsDialog,
    getPendingUploads,
    setToUploadFiles,
    showUploadZipDialog,
    getElectronFilesFromGoogleZip,
    setToUploadCollection,
    getEncryptionKey,
    setEncryptionKey,
    getDirFiles,
    getWatchMappings,
    addWatchMapping,
    removeWatchMapping,
    registerWatcherFunctions,
    isFolder,
    updateWatchMappingSyncedFiles,
    updateWatchMappingIgnoredFiles,
    convertToJPEG,
    registerUpdateEventListener,

    runFFmpegCmd,
    generateImageThumbnail,
    registerForegroundEventListener,
    moveFile,
    deleteFolder,
    rename,
    deleteFile,

    // - ML
    computeImageEmbedding,
    computeTextEmbedding,
});
