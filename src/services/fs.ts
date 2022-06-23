import { FILE_STREAM_CHUNK_SIZE } from '../config';
import path from 'path';
import * as fs from 'promise-fs';
import { ElectronFile } from '../types';
import { logError } from '../utils/logging';
import StreamZip from 'node-stream-zip';
import { Readable } from 'stream';

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

export const getFileStream = async (filePath: string) => {
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

export const getValidPaths = (paths: string[]) => {
    if (!paths) {
        return [] as string[];
    }
    return paths.filter(async (path) => {
        try {
            await fs.stat(path).then((stat) => stat.isFile());
        } catch (e) {
            return false;
        }
    });
};
export const getZipFileStream = async (
    zip: StreamZip.StreamZipAsync,
    filePath: string
) => {
    const stream = await zip.stream(filePath);
    const done = {
        current: false,
    };
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

export async function doesFolderExists(dirPath: string) {
    return await fs
        .stat(dirPath)
        .then((stats) => {
            return stats.isDirectory();
        })
        .catch(() => false);
}

export async function doesPathExists(dirPath: string) {
    return await fs
        .stat(dirPath)
        .then((stats: fs.Stats) => {
            return stats.isFile() || stats.isDirectory();
        })
        .catch(() => false);
}

export const convertBrowserStreamToNode = (fileStream: any) => {
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

export async function createDirectory(dirPath: string) {
    await fs.mkdir(dirPath);
}

export async function renameDirectory(oldDirPath: string, newDirPath: string) {
    await fs.rename(oldDirPath, newDirPath);
}

export async function writeFile(filePath: string, fileData: any) {
    await fs.writeFile(filePath, fileData);
}

export function writeStream(filePath: string, fileStream: any) {
    const writeable = fs.createWriteStream(filePath);
    const readable = convertBrowserStreamToNode(fileStream);
    readable.pipe(writeable);
}

export async function readTextFile(filePath: string) {
    await fs.readFile(filePath, 'utf-8');
}
