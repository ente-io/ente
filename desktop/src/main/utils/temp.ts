import { app } from "electron/main";
import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import path from "node:path";
import type { ZipItem } from "../../types/ipc";
import log from "../log";
import { markClosableZip, openZip } from "../services/zip";
import { writeStream } from "./stream";

/**
 * Our very own directory within the system temp directory. Go crazy, but
 * remember to clean up, especially in exception handlers.
 */
const enteTempDirPath = async () => {
    const result = path.join(app.getPath("temp"), "ente");
    await fs.mkdir(result, { recursive: true });
    return result;
};

/** Generate a random string suitable for being used as a file name prefix */
const randomPrefix = () => {
    const ch = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    const randomChar = () => ch[Math.floor(Math.random() * ch.length)]!;

    return Array(10).fill("").map(randomChar).join("");
};

/**
 * Return the path to a temporary file with an optional {@link extension}.
 *
 * The function returns the path to a file in the system temp directory (in an
 * Ente specific folder therin) with a random prefix and an (optional)
 * {@link extension}. The parent directory is guaranteed to exist.
 *
 * @param extension A string, if provided, is used as the extension for the
 * generated path. It will be automatically prefixed by a dot, so don't include
 * the dot in the provided string.
 *
 * It ensures that there is no existing item with the same name already.
 *
 * Use {@link deleteTempFile} to remove this file when you're done.
 */
export const makeTempFilePath = async (extension?: string) => {
    const tempDir = await enteTempDirPath();
    const suffix = extension ? "." + extension : "";
    let result: string;
    do {
        result = path.join(tempDir, randomPrefix() + suffix);
    } while (existsSync(result));
    return result;
};

/**
 * Delete a temporary file at the given path if it exists.
 *
 * This is the same as a vanilla {@link fs.rm}, except it first checks that the
 * given path is within the Ente specific directory in the system temp
 * directory. This acts as an additional safety check.
 *
 * @param tempFilePath The path to the temporary file to delete. This path
 * should've been previously created using {@link makeTempFilePath}.
 */
export const deleteTempFile = async (tempFilePath: string) => {
    const tempDir = await enteTempDirPath();
    if (!tempFilePath.startsWith(tempDir))
        throw new Error(`Attempting to delete a non-temp file ${tempFilePath}`);
    await fs.rm(tempFilePath, { force: true });
};

/**
 * A variant of {@link deleteTempFile} that suppresses any errors, making it
 * safe to call them in a sequence without needing to handle the scenario where
 * one of them failing causes the rest to be skipped.
 */
export const deleteTempFileIgnoringErrors = async (tempFilePath: string) => {
    try {
        await deleteTempFile(tempFilePath);
    } catch (e) {
        log.error(`Could not delete temporary file at path ${tempFilePath}`, e);
    }
};

/** The result of {@link makeFileForStreamOrPathOrZipItem}. */
interface FileForStreamOrPathOrZipItem {
    /**
     * The path to the file (possibly temporary).
     */
    path: string;
    /**
     * `true` if {@link path} points to a temporary file which should be deleted
     * once we are done processing.
     */
    isFileTemporary: boolean;
    /**
     * A function that can be called to actually write the contents of the
     * source `Uint8Array | string | ZipItem` into the file at {@link path}.
     *
     * It will do nothing in the case when the source is already a path. In the
     * other two cases this function will write the data or zip item into the
     * file at {@link path}.
     */
    writeToTemporaryFile: () => Promise<void>;
}

/**
 * Return the path to a file, a boolean indicating if this is a temporary path
 * that needs to be deleted after processing, and a function to write the given
 * {@link item} into that temporary file if needed.
 *
 * @param item A {@link ReadableStream} with the contents of the file, or the
 * path to an existing file, or a (path to a zip file, name of an entry within
 * that zip file) tuple.
 */
export const makeFileForStreamOrPathOrZipItem = async (
    item: ReadableStream | string | ZipItem,
): Promise<FileForStreamOrPathOrZipItem> => {
    let path: string;
    let isFileTemporary: boolean;
    let writeToTemporaryFile = async () => {
        /* no-op */
    };

    if (typeof item == "string") {
        path = item;
        isFileTemporary = false;
    } else {
        path = await makeTempFilePath();
        isFileTemporary = true;
        if (item instanceof ReadableStream) {
            writeToTemporaryFile = () => writeStream(path, item);
        } else {
            writeToTemporaryFile = async () => {
                const [zipPath, entryName] = item;
                const zip = openZip(zipPath);
                try {
                    await zip.extract(entryName, path);
                } finally {
                    markClosableZip(zipPath);
                }
            };
        }
    }

    return { path, isFileTemporary, writeToTemporaryFile };
};
