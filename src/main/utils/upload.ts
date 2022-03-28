import Store, { Schema } from 'electron-store';
import path from 'path';
import * as fs from 'promise-fs';
import { FILE_STREAM_CHUNK_SIZE } from '../../config';
import { ElectronFile, StoreType } from '../types';

export const uploadStoreSchema: Schema<StoreType> = {
    filePaths: {
        type: 'array',
        items: {
            type: 'string',
        },
    },
    collectionName: {
        type: 'string',
    },
};

const store = new Store({
    name: 'upload-status',
    schema: uploadStoreSchema,
});

// https://stackoverflow.com/a/63111390
export const getFilesFromDir = async (dirPath: string) => {
    if (!(await fs.stat(dirPath)).isDirectory()) {
        return [dirPath];
    }

    let files: string[] = [];
    const filePaths = await fs.readdir(dirPath);

    for (const filePath of filePaths) {
        const absolute = path.join(dirPath, filePath);
        files = files.concat(await getFilesFromDir(absolute));
    }

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
    done: boolean
) => {
    if (done) {
        store.delete('filePaths');
        store.delete('collectionName');
    } else {
        store.set('filePaths', filePaths);
        store.set('collectionName', collectionName);
    }
};

export const getPendingUploads = async () => {
    const filePaths = store.get('filePaths') as string[];
    const collectionName = store.get('collectionName') as string;
    return {
        files: await Promise.all(filePaths.map(getElectronFile)),
        collectionName,
    };
};

export const hasPendingUploads = async () => {
    const pendingFiles = store.get('filePaths');
    return pendingFiles && pendingFiles.length > 0;
};

export const updatePendingUploadsFilePaths = (filePaths: string[]) => {
    store.set('filePaths', filePaths);
};
