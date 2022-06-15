import { webFrame, ipcRenderer } from 'electron';
import {
    getElectronFile,
    getPendingUploads,
    setToUploadFiles,
    getElectronFilesFromGoogleZip,
    setToUploadCollection,
} from './services/upload';
import { logError } from './utils/logging';
import { ElectronFile } from './types';
import { getEncryptionKey, setEncryptionKey } from './utils/safeStorage';
import { clearElectronStore } from './utils/electronStore';
import { openDiskCache, deleteDiskCache } from './utils/cache';
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

// Patch the global WebSocket constructor to use the correct DevServer url
const fixHotReloadNext12 = () => {
    webFrame.executeJavaScript(`Object.defineProperty(globalThis, 'WebSocket', {
    value: new Proxy(WebSocket, {
      construct: (Target, [url, protocols]) => {
        if (url.endsWith('/_next/webpack-hmr')) {
          // Fix the Next.js hmr client url
          return new Target("ws://localhost:3000/_next/webpack-hmr", protocols)
        } else {
          return new Target(url, protocols)
        }
      }
    })
  });`);
};

fixHotReloadNext12();

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
    getEncryptionKey,
    setEncryptionKey,
    clearElectronStore,
    openDiskCache,
    deleteDiskCache,
};
