import path from 'path';
import StreamZip from 'node-stream-zip';
import * as fs from 'promise-fs';
import { FILE_STREAM_CHUNK_SIZE, GOOGLE_PHOTOS_DIR } from '../../config';
import { uploadStatusStore } from '../services/store';
import { ElectronFile } from '../types';

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

const getZipFileStream = async (
    zip: StreamZip.StreamZipAsync,
    filePath: string
) => {
    const stream = await zip.stream(filePath);
    stream.pause();

    let chunkToConsume = new Uint8Array(),
        chunkArray: number[] = [],
        closed = false;

    let resolveObj: (value?: any) => void, rejectObj: (reason?: any) => void;

    stream.on('data', (chunk: Uint8Array) => {
        for (const byte of chunk) {
            chunkArray.push(byte);
        }
        if (chunkArray.length >= FILE_STREAM_CHUNK_SIZE) {
            chunkToConsume = new Uint8Array(
                chunkArray.slice(0, FILE_STREAM_CHUNK_SIZE)
            );
            chunkArray = chunkArray.slice(FILE_STREAM_CHUNK_SIZE);
            resolveObj();
        }
    });

    stream.on('end', () => {
        closed = true;
        resolveObj();
    });

    const resumeDataStream = () => {
        return new Promise((resolve, reject) => {
            resolveObj = resolve;
            rejectObj = reject;
            if (closed) {
                resolveObj();
            } else {
                stream.resume();
            }
        });
    };

    const readableStream = new ReadableStream<Uint8Array>({
        async pull(controller) {
            resumeDataStream().then(() => {
                if (chunkToConsume.length > 0) {
                    controller.enqueue(chunkToConsume);
                    chunkToConsume = new Uint8Array();
                } else if (chunkArray.length > 0) {
                    controller.enqueue(
                        new Uint8Array(
                            chunkArray.slice(0, FILE_STREAM_CHUNK_SIZE)
                        )
                    );
                    chunkArray = chunkArray.slice(FILE_STREAM_CHUNK_SIZE);
                } else {
                    controller.close();
                }
                stream.pause();
            });
        },
    });

    return readableStream;
};

async function getZipEntryasElectronFile(
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

export const setToUploadFiles = (
    filePaths: string[],
    collectionName: string
) => {
    if (filePaths && filePaths.length > 0) {
        uploadStatusStore.set('filePaths', filePaths);
    } else {
        uploadStatusStore.set('filePaths', []);
    }
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
        if (entry.name.startsWith(GOOGLE_PHOTOS_DIR)) {
            files.push(await getZipEntryasElectronFile(zip, entry));
        }
    }

    return files;
};
