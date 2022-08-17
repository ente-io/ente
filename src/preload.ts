import { fixHotReloadNext12 } from './utils/next-serve';
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
    getAllFilesFromDir,
    getWatchMappings,
    registerWatcherFunctions,
    setWatchMappings,
    addWatchMapping,
    removeWatchMapping,
} from './api/watch';
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
import { selectRootDirectory, clearElectronStore } from './api/common';
import { getElectronFile, doesFolderExists } from './services/fs';
import { getEncryptionKey, setEncryptionKey } from './api/safeStorage';
import { openDiskCache, deleteDiskCache } from './api/cache';
import { sendNotification, showOnTray, reloadWindow } from './api/system';

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
    getElectronFile,
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
    setWatchMappings,
    addWatchMapping,
    removeWatchMapping,
    registerWatcherFunctions,
    doesFolderExists,
};
