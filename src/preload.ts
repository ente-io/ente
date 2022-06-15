import * as electron from 'electron';
import {
    getElectronFile,
    getPendingUploads,
    setToUploadFiles,
    getElectronFilesFromGoogleZip,
    setToUploadCollection,
} from './services/upload';
import { logError } from './utils/logging';
import { ElectronFile } from './types';
import {
    getAllFilesFromDir,
    getWatchMappings,
    registerWatcherFunctions,
    setWatchMappings,
    addWatchMapping,
    removeWatchMapping,
    doesFolderExists,
} from './services/watch';
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
} from './services/export';
const { ipcRenderer } = electron;

const selectRootDirectory = async () => {
    try {
        return await ipcRenderer.invoke('select-dir');
    } catch (e) {
        logError(e, 'error while selecting root directory');
    }
};

const sendNotification = (content: string) => {
    ipcRenderer.send('send-notification', content);
};

const showOnTray = (content: string) => {
    ipcRenderer.send('update-tray', content);
};

const reloadWindow = () => {
    ipcRenderer.send('reload-window');
};

const showUploadFilesDialog = async () => {
    try {
        const filePaths: string[] = await ipcRenderer.invoke(
            'show-upload-files-dialog'
        );
        const files = await Promise.all(filePaths.map(getElectronFile));
        return files;
    } catch (e) {
        logError(e, 'error while selecting files');
    }
};

const showUploadDirsDialog = async () => {
    try {
        const filePaths: string[] = await ipcRenderer.invoke(
            'show-upload-dirs-dialog'
        );
        const files = await Promise.all(filePaths.map(getElectronFile));
        return files;
    } catch (e) {
        logError(e, 'error while selecting folders');
    }
};

const showUploadZipDialog = async () => {
    try {
        const filePaths: string[] = await ipcRenderer.invoke(
            'show-upload-zip-dialog'
        );
        const files: ElectronFile[] = [];
        for (const filePath of filePaths) {
            files.push(...(await getElectronFilesFromGoogleZip(filePath)));
        }
        return { zipPaths: filePaths, files };
    } catch (e) {
        logError(e, 'error while selecting zips');
    }
};

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
    getAllFilesFromDir,
    getWatchMappings,
    setWatchMappings,
    addWatchMapping,
    removeWatchMapping,
    registerWatcherFunctions,
    doesFolderExists,
};
