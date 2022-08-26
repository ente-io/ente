import { reloadWindow, sendNotification, showOnTray } from './api/system';
import {
    showUploadDirsDialog,
    showUploadFilesDialog,
    showUploadZipDialog,
    getPendingUploads,
    setToUploadFiles,
    getElectronFilesFromGoogleZip,
    setToUploadCollection,
} from './api/upload';
import {
    registerWatcherFunctions,
    addWatchMapping,
    removeWatchMapping,
    updateMappingFiles,
    getWatchMappings,
} from './api/watch';
import { getEncryptionKey, setEncryptionKey } from './api/safeStorage';
import { clearElectronStore } from './api/electronStore';
import { openDiskCache, deleteDiskCache } from './api/cache';
import {
    checkExistsAndCreateCollectionDir,
    checkExistsAndRename,
    saveStreamToDisk,
    saveFileToDisk,
    registerResumeExportListener,
    registerStopExportListener,
    registerPauseExportListener,
    registerRetryFailedExportListener,
    getExportRecord,
    setExportRecord,
    exists,
} from './api/export';
import { selectRootDirectory } from './api/common';
import { fixHotReloadNext12 } from './utils/preload';
import { doesFolderExists, getAllFilesFromDir } from './api/fs';

fixHotReloadNext12();

const windowObject: any = window;

windowObject['ElectronAPIs'] = {
    exists,
    checkExistsAndCreateCollectionDir,
    checkExistsAndRename,
    saveStreamToDisk,
    saveFileToDisk,
    selectRootDirectory,
    clearElectronStore,
    sendNotification,
    showOnTray,
    reloadWindow,
    registerResumeExportListener,
    registerStopExportListener,
    registerPauseExportListener,
    registerRetryFailedExportListener,
    getExportRecord,
    setExportRecord,
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
    getAllFilesFromDir,
    getWatchMappings,
    addWatchMapping,
    removeWatchMapping,
    registerWatcherFunctions,
    doesFolderExists,
    updateMappingFiles,
};
