/**
 * @file The preload script
 *
 * The preload script runs in an isolated environment. It has access to some of
 * the Node imports. Its task is to expose these imports and other functions as
 * an object on the DOM, so that the renderer process can invoke functions that
 * live in the main (Node.js) process.
 *
 * Note that this script cannot import other code from `src/`. This is not an
 * inherent limitation, just that we'll need to transpile our TypeScript and
 * bundle it such that it can be imported from here at runtime, when this
 * preload script is run by Electron inside its half-node half-DOM isolated
 * environment.
 */

import { contextBridge } from "electron";
import {
    deleteDiskCache,
    getCacheDirectory,
    openDiskCache,
    setCustomCacheDirectory,
} from "./api/cache";
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
    getCacheDirectory,
    setCustomCacheDirectory,
});
