import {
    registerUpdateEventListener,
    reloadWindow,
    sendNotification,
    showOnTray,
    updateAndRestart,
    skipAppVersion,
} from './api/system';
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
    updateWatchMappingSyncedFiles,
    updateWatchMappingIgnoredFiles,
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
import {
    selectRootDirectory,
    logToDisk,
    openLogDirectory,
    getSentryUserID,
    getAppVersion,
} from './api/common';
import { fixHotReloadNext12 } from './utils/preload';
import { isFolder, getDirFiles } from './api/fs';
import { convertHEIC } from './api/heicConvert';
import { setupLogging } from './utils/logging';
import { setupRendererProcessStatsLogger } from './utils/processStats';
import { runFFmpegCmd } from './api/ffmpeg';

fixHotReloadNext12();
setupLogging(true);
setupRendererProcessStatsLogger();

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
    getDirFiles,
    getWatchMappings,
    addWatchMapping,
    removeWatchMapping,
    registerWatcherFunctions,
    isFolder,
    updateWatchMappingSyncedFiles,
    updateWatchMappingIgnoredFiles,
    logToDisk,
    convertHEIC,
    openLogDirectory,
    registerUpdateEventListener,
    updateAndRestart,
    skipAppVersion,
    getSentryUserID,
    getAppVersion,
    runFFmpegCmd,
};
