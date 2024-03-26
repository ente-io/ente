import StreamZip from "node-stream-zip";
import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import path from "node:path";
import { logError } from "../main/log";
import { ElectronFile } from "../types/ipc";

const FILE_STREAM_CHUNK_SIZE: number = 4 * 1024 * 1024;

export async function getDirFiles(dirPath: string) {
    const files = await getDirFilePaths(dirPath);
    const electronFiles = await Promise.all(files.map(getElectronFile));
    return electronFiles;
}

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

const getFileStream = async (filePath: string) => {
    const file = await fs.open(filePath, "r");
    let offset = 0;
    const readableStream = new ReadableStream<Uint8Array>({
        async pull(controller) {
            try {
                const buff = new Uint8Array(FILE_STREAM_CHUNK_SIZE);
                const bytesRead = (await file.read(
                    buff,
                    0,
                    FILE_STREAM_CHUNK_SIZE,
                    offset,
                )) as unknown as number;
                offset += bytesRead;
                if (bytesRead === 0) {
                    controller.close();
                    await file.close();
                } else {
                    controller.enqueue(buff.slice(0, bytesRead));
                }
            } catch (e) {
                await file.close();
            }
        },
        async cancel() {
            await file.close();
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
                throw new Error("electronFile does not exist");
            }
            return await getFileStream(filePath);
        },
        blob: async () => {
            if (!existsSync(filePath)) {
                throw new Error("electronFile does not exist");
            }
            const blob = await fs.readFile(filePath);
            return new Blob([new Uint8Array(blob)]);
        },
        arrayBuffer: async () => {
            if (!existsSync(filePath)) {
                throw new Error("electronFile does not exist");
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
    filePath: string,
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
    stream.on("readable", () => {
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
    stream.on("end", () => {
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
    stream.on("error", (e) => {
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
                logError(e, "readableStream pull failed");
                controller.close();
            }
        },
    });
    return readableStream;
};
