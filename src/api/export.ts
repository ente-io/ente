import {} from './common';
import {
    createDirectory,
    doesPathExists,
    readTextFile,
    renameDirectory,
    writeFile,
    writeStream,
} from './../services/fs';
import { ipcRenderer } from 'electron';
import { logError } from '../utils/logging';

export const exists = (path: string) => {
    return doesPathExists(path);
};

export const checkExistsAndCreateCollectionDir = async (dirPath: string) => {
    if (!doesPathExists(dirPath)) {
        await createDirectory(dirPath);
    }
};

export const checkExistsAndRename = async (
    oldDirPath: string,
    newDirPath: string
) => {
    if (doesPathExists(oldDirPath)) {
        await renameDirectory(oldDirPath, newDirPath);
    }
};

export const saveStreamToDisk = (
    filePath: string,
    fileStream: ReadableStream<any>
) => {
    writeStream(filePath, fileStream);
};

export const saveFileToDisk = async (path: string, fileData: any) => {
    await writeFile(path, fileData);
};

export const getExportRecord = async (filePath: string) => {
    try {
        if (!(await doesPathExists(filePath))) {
            return null;
        }
        const recordFile = await readTextFile(filePath);
        return recordFile;
    } catch (e) {
        // ignore exportFile missing
        logError(e, 'error while selecting files');
    }
};

export const setExportRecord = async (filePath: string, data: string) => {
    await writeFile(filePath, data);
};

export const registerResumeExportListener = (resumeExport: () => void) => {
    ipcRenderer.removeAllListeners('resume-export');
    ipcRenderer.on('resume-export', () => resumeExport());
};

export const registerStopExportListener = (abortExport: () => void) => {
    ipcRenderer.removeAllListeners('stop-export');
    ipcRenderer.on('stop-export', () => abortExport());
};

export const registerPauseExportListener = (pauseExport: () => void) => {
    ipcRenderer.removeAllListeners('pause-export');
    ipcRenderer.on('pause-export', () => pauseExport());
};

export const registerRetryFailedExportListener = (
    retryFailedExport: () => void
) => {
    ipcRenderer.removeAllListeners('retry-export');
    ipcRenderer.on('retry-export', () => retryFailedExport());
};
