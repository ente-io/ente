import { existsSync } from "fs";
import StreamZip from "node-stream-zip";
import path from "path";
import * as fs from "promise-fs";
import { Readable } from "stream";
import { ElectronFile } from "../types";
import { logError } from "./logging";

const FILE_STREAM_CHUNK_SIZE: number = 4 * 1024 * 1024;

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
    const file = await fs.open(filePath, "r");
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
                    offset,
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

export async function isFolder(dirPath: string) {
    try {
        const stats = await fs.stat(dirPath);
        return stats.isDirectory();
    } catch (e) {
        let err = e;
        // if code is defined, it's an error from fs.stat
        if (typeof e.code !== "undefined") {
            // ENOENT means the file does not exist
            if (e.code === "ENOENT") {
                return false;
            }
            err = Error(`fs error code: ${e.code}`);
        }
        logError(err, "isFolder failed");
        return false;
    }
}

export const convertBrowserStreamToNode = (
    fileStream: ReadableStream<Uint8Array>,
) => {
    const reader = fileStream.getReader();
    const rs = new Readable();

    rs._read = async () => {
        try {
            const result = await reader.read();

            if (!result.done) {
                rs.push(Buffer.from(result.value));
            } else {
                rs.push(null);
                return;
            }
        } catch (e) {
            rs.emit("error", e);
        }
    };

    return rs;
};

export async function writeNodeStream(
    filePath: string,
    fileStream: NodeJS.ReadableStream,
) {
    const writeable = fs.createWriteStream(filePath);

    fileStream.on("error", (error) => {
        writeable.destroy(error); // Close the writable stream with an error
    });

    fileStream.pipe(writeable);

    await new Promise((resolve, reject) => {
        writeable.on("finish", resolve);
        writeable.on("error", async (e) => {
            if (existsSync(filePath)) {
                await fs.unlink(filePath);
            }
            reject(e);
        });
    });
}

export async function writeStream(
    filePath: string,
    fileStream: ReadableStream<Uint8Array>,
) {
    const readable = convertBrowserStreamToNode(fileStream);
    await writeNodeStream(filePath, readable);
}

export async function readTextFile(filePath: string) {
    if (!existsSync(filePath)) {
        throw new Error("File does not exist");
    }
    return await fs.readFile(filePath, "utf-8");
}

export async function moveFile(
    sourcePath: string,
    destinationPath: string,
): Promise<void> {
    if (!existsSync(sourcePath)) {
        throw new Error("File does not exist");
    }
    if (existsSync(destinationPath)) {
        throw new Error("Destination file already exists");
    }
    // check if destination folder exists
    const destinationFolder = path.dirname(destinationPath);
    if (!existsSync(destinationFolder)) {
        await fs.mkdir(destinationFolder, { recursive: true });
    }
    await fs.rename(sourcePath, destinationPath);
}

export async function deleteFolder(folderPath: string): Promise<void> {
    if (!existsSync(folderPath)) {
        return;
    }
    if (!fs.statSync(folderPath).isDirectory()) {
        throw new Error("Path is not a folder");
    }
    // check if folder is empty
    const files = await fs.readdir(folderPath);
    if (files.length > 0) {
        throw new Error("Folder is not empty");
    }
    await fs.rmdir(folderPath);
}

export async function rename(oldPath: string, newPath: string) {
    if (!existsSync(oldPath)) {
        throw new Error("Path does not exist");
    }
    await fs.rename(oldPath, newPath);
}

export function deleteFile(filePath: string): void {
    if (!existsSync(filePath)) {
        return;
    }
    if (!fs.statSync(filePath).isFile()) {
        throw new Error("Path is not a file");
    }
    fs.rmSync(filePath);
}
