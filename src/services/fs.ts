import { FILE_STREAM_CHUNK_SIZE } from '../config';
import path from 'path';
import * as fs from 'promise-fs';
import { ElectronFile } from '../types';
import StreamZip from 'node-stream-zip';
import { Readable } from 'stream';
import { logError } from './logging';
import { existsSync } from 'fs';

// https://stackoverflow.com/a/63111390
export const getDirFilePaths = async (dirPath: string) => {
    if (!(await fs.stat(dirPath)).isDirectory()) {
        return [dirPath];
    }

    let files: string[] = [];
    const filePaths = await fs.readdir(dirPath);

    for (const filePath of filePaths) {
        const absolute = path.join(dirPath, filePath);
        files = [...files, ...(await getDirFilePaths(absolute))];
    }

    return files;
};

export const getFileStream = async (filePath: string) => {
    const file = await fs.open(filePath, 'r');
    let offset = 0;
    const readableStream = new ReadableStream<Uint8Array>({
        async pull(controller) {
            try {
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
                    await fs.close(file);
                } else {
                    controller.enqueue(buff.slice(0, bytesRead));
                }
            } catch (e) {
                await fs.close(file);
            }
        },
        async cancel() {
            await fs.close(file);
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
            if (!existsSync(filePath)) {
                throw new Error('electronFile does not exist');
            }
            return await getFileStream(filePath);
        },
        blob: async () => {
            if (!existsSync(filePath)) {
                throw new Error('electronFile does not exist');
            }
            const blob = await fs.readFile(filePath);
            return new Blob([new Uint8Array(blob)]);
        },
        arrayBuffer: async () => {
            if (!existsSync(filePath)) {
                throw new Error('electronFile does not exist');
            }
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
    const inProgress = {
        current: false,
    };
    let resolveObj: (value?: any) => void = null;
    let rejectObj: (reason?: any) => void = null;
    stream.on('readable', () => {
        try {
            if (resolveObj) {
                inProgress.current = true;
                const chunk = stream.read(FILE_STREAM_CHUNK_SIZE) as Buffer;
                if (chunk) {
                    resolveObj(new Uint8Array(chunk));
                    resolveObj = null;
                }
                inProgress.current = false;
            }
        } catch (e) {
            rejectObj(e);
        }
    });
    stream.on('end', () => {
        try {
            done.current = true;
            if (resolveObj && !inProgress.current) {
                resolveObj(null);
                resolveObj = null;
            }
        } catch (e) {
            rejectObj(e);
        }
    });
    stream.on('error', (e) => {
        try {
            done.current = true;
            if (rejectObj) {
                rejectObj(e);
                rejectObj = null;
            }
        } catch (e) {
            rejectObj(e);
        }
    });

    const readStreamData = async () => {
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
                logError(e, 'readableStream pull failed');
                controller.close();
            }
        },
    });
    return readableStream;
};

export async function isFolder(dirPath: string) {
    try {
        const stats = await fs.stat(dirPath);
        return stats.isDirectory();
    } catch (e) {
        return false;
    }
}

export const convertBrowserStreamToNode = (
    fileStream: ReadableStream<Uint8Array>
) => {
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

export async function writeStream(
    filePath: string,
    fileStream: ReadableStream<Uint8Array>
) {
    const writeable = fs.createWriteStream(filePath);
    const readable = convertBrowserStreamToNode(fileStream);
    readable.pipe(writeable);
    await new Promise((resolve, reject) => {
        writeable.on('finish', resolve);
        writeable.on('error', reject);
    });
}

export async function readTextFile(filePath: string) {
    if (!existsSync(filePath)) {
        throw new Error('File does not exist');
    }
    return await fs.readFile(filePath, 'utf-8');
}
