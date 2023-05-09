import { readTextFile, writeStream } from './../services/fs';
import { logError } from '../services/logging';
import * as fs from 'promise-fs';

export const exists = (path: string) => {
    return fs.existsSync(path);
};

export const checkExistsAndCreateDir = async (dirPath: string) => {
    if (!fs.existsSync(dirPath)) {
        await fs.mkdir(dirPath);
    }
};

export const saveStreamToDisk = async (
    filePath: string,
    fileStream: ReadableStream<Uint8Array>
) => {
    await writeStream(filePath, fileStream);
};

export const saveFileToDisk = async (path: string, fileData: any) => {
    await fs.writeFile(path, fileData);
};

export const getExportRecord = async (filePath: string) => {
    try {
        if (!fs.existsSync(filePath)) {
            return null;
        }
        const recordFile = await readTextFile(filePath);
        return recordFile;
    } catch (e) {
        logError(e, 'error while selecting files');
    }
};

export const setExportRecord = async (filePath: string, data: string) => {
    await fs.writeFile(filePath, data);
};
