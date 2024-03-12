import * as fs from "promise-fs";
import { writeStream } from "./../services/fs";

export const exists = (path: string) => {
    return fs.existsSync(path);
};

export const checkExistsAndCreateDir = async (dirPath: string) => {
    if (!fs.existsSync(dirPath)) {
        await fs.mkdir(dirPath);
    }
};

export const saveStreamToDisk = async (
    filePath: string,
    fileStream: ReadableStream<Uint8Array>,
) => {
    await writeStream(filePath, fileStream);
};

export const saveFileToDisk = async (path: string, fileData: string) => {
    await fs.writeFile(path, fileData);
};
