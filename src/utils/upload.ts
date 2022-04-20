import path from 'path';
import StreamZip from 'node-stream-zip';
import * as fs from 'promise-fs';
import { FILE_STREAM_CHUNK_SIZE } from '../config';
import { uploadStatusStore } from '../services/store';
import { ElectronFile } from '../types';
import { logError } from './logging';

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
            const buff = new Uint8Array(FILE_STREAM_CHUNK_SIZE);

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

const getZipFileStream = async (
    zip: StreamZip.StreamZipAsync,
    filePath: string
) => {
    const stream = await zip.stream(filePath);
    const done = { current: false };

    let resolveObj: (value?: any) => void = null;
    let rejectObj: (reason?: any) => void = null;

    stream.on('readable', () => {
        if (resolveObj) {
            const chunk = stream.read(FILE_STREAM_CHUNK_SIZE) as Buffer;
            if (chunk) {
                resolveObj(new Uint8Array(chunk));
                resolveObj = null;
            }
        }
    });

    stream.on('end', () => {
        done.current = true;
    });

    stream.on('error', (e) => {
        done.current = true;
        if (rejectObj) {
            rejectObj(e);
            rejectObj = null;
        }
    });

    const readStreamData = () => {
        return new Promise<Uint8Array>((resolve, reject) => {
            const chunk = stream.read(FILE_STREAM_CHUNK_SIZE) as Buffer;
            if (chunk || done.current) {
                resolve(chunk);
            } else {
                resolveObj = resolve;
                rejectObj = reject;
            }
        });
    };

    const readableStream = new ReadableStream<Uint8Array>({
        async pull(controller) {
            try {
                const data = await readStreamData();
                if (data) {
                    controller.enqueue(data);
                } else {
                    controller.close();
                }
            } catch (e) {
                logError(e, 'stream reading failed');
                controller.close();
            }
        },
    });

    return readableStream;
};

async function getZipEntryAsElectronFile(
    zip: StreamZip.StreamZipAsync,
    entry: StreamZip.ZipEntry
): Promise<ElectronFile> {
    return {
        path: entry.name,
        name: path.basename(entry.name),
        size: entry.size,
        lastModified: entry.time,
        stream: async () => {
            return await getZipFileStream(zip, entry.name);
        },
        blob: async () => {
            const buffer = await zip.entryData(entry.name);
            return new Blob([new Uint8Array(buffer)]);
        },
        arrayBuffer: async () => {
            const buffer = await zip.entryData(entry.name);
            return new Uint8Array(buffer);
        },
    };
}

export async function getElectronFile(filePath: string): Promise<ElectronFile> {
    const fileStats = await fs.stat(filePath);
    return {
        path: filePath.split(path.sep).join(path.posix.sep),
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

export const setToUploadFiles = (filePaths: string[]) => {
    if (filePaths && filePaths.length > 0) {
        uploadStatusStore.set('filePaths', filePaths);
    } else {
        uploadStatusStore.set('filePaths', []);
    }
};

export const setToUploadCollection = (collectionName: string) => {
    if (collectionName) {
        uploadStatusStore.set('collectionName', collectionName);
    } else {
        uploadStatusStore.delete('collectionName');
    }
};

export const getPendingUploads = async () => {
    const filePaths = uploadStatusStore.get('filePaths') as string[];
    const collectionName = uploadStatusStore.get('collectionName') as string;
    const validFilePaths = filePaths?.filter(
        async (filePath) =>
            await fs.stat(filePath).then((stat) => stat.isFile())
    );
    return {
        files: validFilePaths
            ? await Promise.all(validFilePaths.map(getElectronFile))
            : [],
        collectionName,
    };
};

export const updatePendingUploadsFilePaths = (filePaths: string[]) => {
    uploadStatusStore.set('filePaths', filePaths);
};

export const getElectronFilesFromGoogleZip = async (filePath: string) => {
    const zip = new StreamZip.async({
        file: filePath,
    });

    const entries = await zip.entries();
    const files: ElectronFile[] = [];

    for (const entry of Object.values(entries)) {
        const basename = entry.name.substring(entry.name.lastIndexOf('/'));
        if (entry.isFile && basename.length > 1 && basename[1] !== '.') {
            files.push(await getZipEntryAsElectronFile(zip, entry));
        }
    }

    return files;
};
