/**
 * @file The preload script
 *
 * The preload script runs in a renderer process before its web contents begin
 * loading. During their execution they have access to a subset of Node.js APIs
 * and imports. Its purpose is to expose the relevant imports and other
 * functions as an object on the DOM, so that the renderer process can invoke
 * functions that live in the main (Node.js) process if needed.
 *
 * Note that this script cannot import other code from `src/` - conceptually it
 * can be thought of as running in a separate, third, process different from
 * both the main or a renderer process (technically, it runs in a BrowserWindow
 * context that runs prior to the renderer process).
 *
 * That said, this can be split into multiple files if we wished. However,
 * that'd require us setting up a bundler to package it back up into a single JS
 * file that can be used at runtime.
 *
 * > Since enabling the sandbox disables Node.js integration in your preload
 * > scripts, you can no longer use require("../my-script"). In other words,
 * > your preload script needs to be a single file.
 * >
 * > https://www.electronjs.org/blog/breach-to-barrier
 *
 * Since most of this is just boilerplate code providing a bridge between the
 * main and renderer, we avoid introducing another moving part into the mix and
 * just keep the entire preload setup in this single file.
 */

import { contextBridge, ipcRenderer } from "electron";
import { existsSync } from "fs";
import path from "path";
import * as fs from "promise-fs";
import { Readable } from "stream";
import { deleteDiskCache, openDiskCache } from "./api/cache";
import { logToDisk, openLogDirectory } from "./api/common";
import { clearElectronStore } from "./api/electronStore";
import {
    checkExistsAndCreateDir,
    exists,
    saveFileToDisk,
    saveStreamToDisk,
} from "./api/export";
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
import { setupLogging } from "./utils/logging";

/* Some of the code below has been duplicated to make this file self contained.
Enhancement: consider alternatives */

/* preload: duplicated logError */
export function logError(error: Error, message: string, info?: string): void {
    ipcRenderer.invoke("log-error", error, message, info);
}

// -

export const convertBrowserStreamToNode = (
    fileStream: ReadableStream<Uint8Array>,
) => {
    const reader = fileStream.getReader();
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

export async function writeNodeStream(
    filePath: string,
    fileStream: NodeJS.ReadableStream,
) {
    const writeable = fs.createWriteStream(filePath);

    fileStream.on("error", (error) => {
        writeable.destroy(error); // Close the writable stream with an error
    });

    fileStream.pipe(writeable);

    await new Promise((resolve, reject) => {
        writeable.on("finish", resolve);
        writeable.on("error", async (e) => {
            if (existsSync(filePath)) {
                await fs.unlink(filePath);
            }
            reject(e);
        });
    });
}

/* preload: duplicated writeStream */
export async function writeStream(
    filePath: string,
    fileStream: ReadableStream<Uint8Array>,
) {
    const readable = convertBrowserStreamToNode(fileStream);
    await writeNodeStream(filePath, readable);
}

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
    if (!existsSync(destinationFolder)) {
        await fs.mkdir(destinationFolder, { recursive: true });
    }
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
    if (!fs.statSync(folderPath).isDirectory()) {
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

function deleteFile(filePath: string): void {
    if (!existsSync(filePath)) {
        return;
    }
    if (!fs.statSync(filePath).isFile()) {
        throw new Error("Path is not a file");
    }
    fs.rmSync(filePath);
}

// -

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

// -

const selectDirectory = async (): Promise<string> => {
    try {
        return await ipcRenderer.invoke("select-dir");
    } catch (e) {
        logError(e, "error while selecting root directory");
    }
};

const getAppVersion = async (): Promise<string> => {
    try {
        return await ipcRenderer.invoke("get-app-version");
    } catch (e) {
        logError(e, "failed to get release version");
        throw e;
    }
};

const openDirectory = async (dirPath: string): Promise<void> => {
    try {
        await ipcRenderer.invoke("open-dir", dirPath);
    } catch (e) {
        logError(e, "error while opening directory");
        throw e;
    }
};

// -

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

setupLogging();

// These objects exposed here will become available to the JS code in our
// renderer (the web/ code) as `window.ElectronAPIs.*`
//
// https://www.electronjs.org/docs/latest/tutorial/tutorial-preload
contextBridge.exposeInMainWorld("ElectronAPIs", {
    exists,
    checkExistsAndCreateDir,
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
    openDiskCache,
    deleteDiskCache,
    getDirFiles,
    getWatchMappings,
    addWatchMapping,
    removeWatchMapping,
    registerWatcherFunctions,
    isFolder,
    updateWatchMappingSyncedFiles,
    updateWatchMappingIgnoredFiles,
    logToDisk,
    convertToJPEG,
    openLogDirectory,
    registerUpdateEventListener,
    updateAndRestart,
    skipAppUpdate,
    getAppVersion,
    runFFmpegCmd,
    muteUpdateNotification,
    generateImageThumbnail,
    registerForegroundEventListener,
    openDirectory,
    moveFile,
    deleteFolder,
    rename,
    deleteFile,
    computeImageEmbedding,
    computeTextEmbedding,
});
