import { Readable } from 'stream';
import * as fs from 'promise-fs';
import * as electron from 'electron';
import {
    getElectronFile,
    getPendingUploads,
    setToUploadFiles,
    getElectronFilesFromGoogleZip,
    setToUploadCollection,
} from './utils/upload';
import { logError } from './utils/logging';
import { ElectronFile } from './types';
import {
    getPosixFilePathsFromDir,
    getWatchMappings,
    initWatcher,
    registerWatcherFunctions,
    setWatchMappings,
    addWatchMapping,
    removeWatchMapping,
    isFolderExists,
} from './utils/watch';
import path from 'path';

const { ipcRenderer } = electron;

const responseToReadable = (fileStream: any) => {
    const reader = fileStream.getReader();
    const rs = new Readable();
    rs._read = async () => {
        const result = await reader.read();
        if (!result.done) {
            rs.push(Buffer.from(result.value));
        } else {
            rs.push(null);
            return;
        }
    };
    return rs;
};

const exists = (path: string) => {
    return fs.existsSync(path);
};

const checkExistsAndCreateCollectionDir = async (dirPath: string) => {
    if (!fs.existsSync(dirPath)) {
        await fs.mkdir(dirPath);
    }
};

const checkExistsAndRename = async (oldDirPath: string, newDirPath: string) => {
    if (fs.existsSync(oldDirPath)) {
        await fs.rename(oldDirPath, newDirPath);
    }
};

const saveStreamToDisk = (path: string, fileStream: ReadableStream<any>) => {
    const writeable = fs.createWriteStream(path);
    const readable = responseToReadable(fileStream);
    readable.pipe(writeable);
};

const saveFileToDisk = async (path: string, file: any) => {
    await fs.writeFile(path, file);
};

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

const registerResumeExportListener = (resumeExport: () => void) => {
    ipcRenderer.removeAllListeners('resume-export');
    ipcRenderer.on('resume-export', () => resumeExport());
};
const registerStopExportListener = (abortExport: () => void) => {
    ipcRenderer.removeAllListeners('stop-export');
    ipcRenderer.on('stop-export', () => abortExport());
};

const registerPauseExportListener = (pauseExport: () => void) => {
    ipcRenderer.removeAllListeners('pause-export');
    ipcRenderer.on('pause-export', () => pauseExport());
};

const registerRetryFailedExportListener = (retryFailedExport: () => void) => {
    ipcRenderer.removeAllListeners('retry-export');
    ipcRenderer.on('retry-export', () => retryFailedExport());
};

const reloadWindow = () => {
    ipcRenderer.send('reload-window');
};

const getExportRecord = async (filePath: string) => {
    try {
        const filepath = `${filePath}`;
        const recordFile = await fs.readFile(filepath, 'utf-8');
        return recordFile;
    } catch (e) {
        // ignore exportFile missing
        logError(e, 'error while selecting files');
    }
};

const setExportRecord = async (filePath: string, data: string) => {
    const filepath = `${filePath}`;
    await fs.writeFile(filepath, data);
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

const selectFolder = async () => {
    try {
        let folderPath: string = await ipcRenderer.invoke('select-folder');
        folderPath = folderPath.split(path.sep).join(path.posix.sep);
        return folderPath;
    } catch (e) {
        logError(e, 'error while selecting folder');
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
    getPosixFilePathsFromDir,
    selectFolder,
    getWatchMappings,
    setWatchMappings,
    initWatcher,
    addWatchMapping,
    removeWatchMapping,
    registerWatcherFunctions,
    isFolderExists,
};
