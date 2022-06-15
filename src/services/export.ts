import { ipcRenderer } from 'electron';
import * as fs from 'promise-fs';
import { Readable } from 'stream';
import { logError } from '../utils/logging';

export const responseToReadable = (fileStream: any) => {
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
    path: string,
    fileStream: ReadableStream<any>
) => {
    const writeable = fs.createWriteStream(path);
    const readable = responseToReadable(fileStream);
    readable.pipe(writeable);
};

export const saveFileToDisk = async (path: string, file: any) => {
    await fs.writeFile(path, file);
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

export const getExportRecord = async (filePath: string) => {
    try {
        const filepath = `${filePath}`;
        if (!(await fs.stat(filePath)).isFile()) {
            return null;
        }
        const recordFile = await fs.readFile(filepath, 'utf-8');
        return recordFile;
    } catch (e) {
        // ignore exportFile missing
        logError(e, 'error while selecting files');
    }
};

export const setExportRecord = async (filePath: string, data: string) => {
    const filepath = `${filePath}`;
    await fs.writeFile(filepath, data);
};
