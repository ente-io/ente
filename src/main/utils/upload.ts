import ElectronStore from 'electron-store';
import path from 'path';
import * as fs from 'promise-fs';
import mime from 'mime';
import { ENCRYPTION_CHUNK_SIZE } from '../../config';
import { dialog } from '@electron/remote';
import { ElectronFile } from '../types';

const store = new ElectronStore();

const getFilesFromDir = (dirPath: string) => {
    let files: string[] = [];

    // https://stackoverflow.com/a/63111390
    const getAllFilePaths = (dirPath: string) => {
        fs.readdirSync(dirPath).forEach((filePath) => {
            const absolute = path.join(dirPath, filePath);
            if (fs.statSync(absolute).isDirectory())
                return getAllFilePaths(absolute);
            else return files.push(absolute);
        });
    };

    if (fs.statSync(dirPath).isDirectory()) getAllFilePaths(dirPath);
    else files.push(dirPath);

    return files;
};

const getFileStream = async (filePath: string) => {
    const file = await fs.open(filePath, 'r');
    let offset = 0;
    const readableStream = new ReadableStream<Uint8Array>({
        async pull(controller) {
            let buff = new Uint8Array(ENCRYPTION_CHUNK_SIZE);

            // original types were not working correctly
            const bytesRead = (await fs.read(
                file,
                buff,
                0,
                ENCRYPTION_CHUNK_SIZE,
                offset
            )) as unknown as number;
            offset += bytesRead;
            if (bytesRead === 0) {
                controller.close();
                offset = 0;
            } else {
                controller.enqueue(buff);
            }
        },
    });
    return readableStream;
};

export async function showUploadFilesDialog() {
    const files = await dialog.showOpenDialog({
        properties: ['openFile', 'multiSelections'],
    });
    return files.filePaths;
}

export async function showUploadDirsDialog() {
    const dir = await dialog.showOpenDialog({
        properties: ['openDirectory', 'multiSelections'],
    });

    let files: string[] = [];
    for (const dirPath of dir.filePaths) {
        files = files.concat(getFilesFromDir(dirPath));
    }

    return files;
}

export async function getElectronFile(filePath: string): Promise<ElectronFile> {
    const fileStats = fs.statSync(filePath);
    return {
        path: filePath,
        name: path.basename(filePath),
        size: fileStats.size,
        lastModified: fileStats.mtime.valueOf(),
        type: {
            mimeType: mime.getType(filePath),
            ext: path.extname(filePath).substring(1),
        },
        createReadStream: async () => {
            return await getFileStream(filePath);
        },
        toBlob: async () => {
            const blob = await fs.readFile(filePath);
            return new Blob([new Uint8Array(blob)]);
        },
        toUInt8Array: async () => {
            const blob = await fs.readFile(filePath);
            return new Uint8Array(blob);
        },
    };
}

export const setToUploadFiles = (
    filePaths: string[],
    collectionName: string,
    collectionIDs: number[],
    done: boolean
) => {
    store.set('done', done);
    if (done) {
        store.delete('filesPaths');
        store.delete('collectionName');
        store.delete('collectionIDs');
    } else {
        store.set('filesPaths', filePaths);
        store.set('collectionIDs', collectionIDs);
        if (collectionName) {
            store.set('collectionName', collectionName);
        } else {
            store.delete('collectionName');
        }
    }
};

export const getToUploadFiles = () => {
    const filesPaths = store.get('filesPaths') as string[];
    const collectionName = store.get('collectionName') as string;
    const collectionIDs = store.get('collectionIDs') as number[];
    return {
        filesPaths,
        collectionName,
        collectionIDs,
    };
};

export const getIfToUploadFilesExists = async () => {
    const doneUploadingFiles = store.get('done') as boolean;
    if (doneUploadingFiles === undefined) return false;
    return !doneUploadingFiles;
};
