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
import { fixHotReloadNext12 } from './utils/preload';
import { selectRootDirectory } from './api/common';
import { getElectronFile } from './services/fs';

fixHotReloadNext12();

const windowObject: any = window;

windowObject['ElectronAPIs'] = {
    exists,
    checkExistsAndCreateCollectionDir,
    checkExistsAndRename,
    saveStreamToDisk,
    saveFileToDisk,
    selectRootDirectory,
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
    clearElectronStore,
    openDiskCache,
    deleteDiskCache,
};
