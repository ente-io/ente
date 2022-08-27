import { readTextFile, writeStream } from './../services/fs';
import { ipcRenderer } from 'electron';
import * as fs from 'promise-fs';

export const exists = (path: string) => {
    return fs.existsSync(path);
};

export const checkExistsAndCreateCollectionDir = async (dirPath: string) => {
    if (!fs.existsSync(dirPath)) {
        await fs.mkdir(dirPath);
    }
};

export const checkExistsAndRename = async (
    oldDirPath: string,
    newDirPath: string
) => {
    if (fs.existsSync(oldDirPath)) {
        await fs.rename(oldDirPath, newDirPath);
    }
};

export const saveStreamToDisk = (
    filePath: string,
    fileStream: ReadableStream<any>
) => {
    writeStream(filePath, fileStream);
};

export const saveFileToDisk = async (path: string, fileData: any) => {
    await fs.writeFile(path, fileData);
};

export const getExportRecord = async (filePath: string) => {
    if (!fs.existsSync(filePath)) {
        return null;
    }
    const recordFile = await readTextFile(filePath);
    return recordFile;
};

export const setExportRecord = async (filePath: string, data: string) => {
    await fs.writeFile(filePath, data);
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
