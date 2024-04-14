/**
 * @file file system related functions exposed over the context bridge.
 */
import { createWriteStream, existsSync } from "node:fs";
import fs from "node:fs/promises";
import { Readable } from "node:stream";

export const fsExists = (path: string) => existsSync(path);

export const fsRename = (oldPath: string, newPath: string) =>
    fs.rename(oldPath, newPath);

export const fsMkdirIfNeeded = (dirPath: string) =>
    fs.mkdir(dirPath, { recursive: true });

export const fsRmdir = (path: string) => fs.rmdir(path);

export const fsRm = (path: string) => fs.rm(path);

/**
 * Write a (web) ReadableStream to a file at the given {@link filePath}.
 *
 * The returned promise resolves when the write completes.
 *
 * @param filePath The local filesystem path where the file should be written.
 * @param readableStream A [web
 * ReadableStream](https://developer.mozilla.org/en-US/docs/Web/API/ReadableStream)
 */
export const writeStream = (filePath: string, readableStream: ReadableStream) =>
    writeNodeStream(filePath, convertWebReadableStreamToNode(readableStream));

/**
 * Convert a Web ReadableStream into a Node.js ReadableStream
 *
 * This can be used to, for example, write a ReadableStream obtained via
 * `net.fetch` into a file using the Node.js `fs` APIs
 */
const convertWebReadableStreamToNode = (readableStream: ReadableStream) => {
    const reader = readableStream.getReader();
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

const writeNodeStream = async (
    filePath: string,
    fileStream: NodeJS.ReadableStream,
) => {
    const writeable = createWriteStream(filePath);

    fileStream.on("error", (error) => {
        writeable.destroy(error); // Close the writable stream with an error
    });

    fileStream.pipe(writeable);

    await new Promise((resolve, reject) => {
        writeable.on("finish", resolve);
        writeable.on("error", async (e: unknown) => {
            if (existsSync(filePath)) {
                await fs.unlink(filePath);
            }
            reject(e);
        });
    });
};

/* TODO: Audit below this  */

export const saveStreamToDisk = writeStream;

export const saveFileToDisk = (path: string, contents: string) =>
    fs.writeFile(path, contents);

export const readTextFile = async (filePath: string) =>
    fs.readFile(filePath, "utf-8");

export const isFolder = async (dirPath: string) => {
    if (!existsSync(dirPath)) return false;
    const stats = await fs.stat(dirPath);
    return stats.isDirectory();
};
