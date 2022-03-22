import Store, { Schema } from 'electron-store';
import path from 'path';
import * as fs from 'promise-fs';
import mime from 'mime';
import { FILE_STREAM_CHUNK_SIZE } from '../../config';
import { ElectronFile, StoreType } from '../types';

const storeSchema: Schema<StoreType> = {
    done: {
        type: 'boolean',
    },
    filesPaths: {
        type: 'array',
        items: {
            type: 'string',
        },
    },
    collectionName: {
        type: 'string',
    },
    collectionIDs: {
        type: 'array',
        items: {
            type: 'number',
        },
    },
};

const store = new Store({
    name: 'upload-status',
    schema: storeSchema,
});

// https://stackoverflow.com/a/63111390
const getAllFilePaths = async (dirPath: string) => {
    if (!(await fs.stat(dirPath)).isDirectory()) {
        return [dirPath];
    }

    let files: string[] = [];
    const filePaths = await fs.readdir(dirPath);

    for (const filePath of filePaths) {
        const absolute = path.join(dirPath, filePath);
        files = files.concat(await getAllFilePaths(absolute));
    }

    return files;
};

export const getFilesFromDir = async (dirPath: string) => {
    const files: string[] = await getAllFilePaths(dirPath);

    return files;
};

const getFileStream = async (filePath: string) => {
    const file = await fs.open(filePath, 'r');
    let offset = 0;
    const readableStream = new ReadableStream<Uint8Array>({
        async pull(controller) {
            let buff = new Uint8Array(FILE_STREAM_CHUNK_SIZE);

            // original types were not working correctly
            const bytesRead = (await fs.read(
                file,
                buff,
                0,
                FILE_STREAM_CHUNK_SIZE,
                offset
            )) as unknown as number;
            offset += bytesRead;
            if (bytesRead === 0) {
                controller.close();
            } else {
                controller.enqueue(buff);
            }
        },
    });
    return readableStream;
};

export async function getElectronFile(filePath: string): Promise<ElectronFile> {
    const fileStats = await fs.stat(filePath);
    return {
        path: filePath,
        name: path.basename(filePath),
        size: fileStats.size,
        lastModified: fileStats.mtime.valueOf(),
        type: {
            mimeType: mime.getType(filePath),
            ext: path.extname(filePath).substring(1),
        },
        stream: async () => {
            return await getFileStream(filePath);
        },
        blob: async () => {
            const blob = await fs.readFile(filePath);
            return new Blob([new Uint8Array(blob)]);
        },
        arrayBuffer: async () => {
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

export const pendingToUploadFilePaths = () => {
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
