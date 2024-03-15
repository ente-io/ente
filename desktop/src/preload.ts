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

import { contextBridge } from "electron";
import { deleteDiskCache, openDiskCache } from "./api/cache";
import { computeImageEmbedding, computeTextEmbedding } from "./api/clip";
import {
    getAppVersion,
    getPlatform,
    logToDisk,
    openDirectory,
    openLogDirectory,
    selectDirectory,
} from "./api/common";
import { clearElectronStore } from "./api/electronStore";
import {
    checkExistsAndCreateDir,
    exists,
    saveFileToDisk,
    saveStreamToDisk,
} from "./api/export";
import { runFFmpegCmd } from "./api/ffmpeg";
import {
    deleteFile,
    deleteFolder,
    getDirFiles,
    isFolder,
    moveFile,
    readTextFile,
    rename,
} from "./api/fs";
import { convertToJPEG, generateImageThumbnail } from "./api/imageProcessor";
import { getEncryptionKey, setEncryptionKey } from "./api/safeStorage";
import {
    muteUpdateNotification,
    registerForegroundEventListener,
    registerUpdateEventListener,
    reloadWindow,
    sendNotification,
    skipAppUpdate,
    updateAndRestart,
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
    sendNotification,
    reloadWindow,
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
    getPlatform,
});
