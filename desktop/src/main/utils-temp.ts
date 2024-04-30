import { app } from "electron/main";
import StreamZip from "node-stream-zip";
import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import path from "path";
import type { ZipEntry } from "../types/ipc";

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
    const alphabet =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    let result = "";
    for (let i = 0; i < 10; i++)
        result += alphabet[Math.floor(Math.random() * alphabet.length)];
    return result;
};

/**
 * Return the path to a temporary file with the given {@link suffix}.
 *
 * The function returns the path to a file in the system temp directory (in an
 * Ente specific folder therin) with a random prefix and an (optional)
 * {@link extension}.
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

/** The result of {@link makeFileForDataOrPathOrZipEntry}. */
interface FileForDataOrPathOrZipEntry {
    /** The path to the file (possibly temporary) */
    path: string;
    /**
     * `true` if {@link path} points to a temporary file which should be deleted
     * once we are done processing.
     */
    isFileTemporary: boolean;
    /**
     * If set, this'll be a function that can be called to actually write the
     * contents of the source `Uint8Array | string | ZipEntry` into the file at
     * {@link path}.
     *
     * It will be undefined if the source is already a path since nothing needs
     * to be written in that case. In the other two cases this function will
     * write the data or zip entry into the file at {@link path}.
     */
    writeToTemporaryFile?: () => Promise<void>;
}

/**
 * Return the path to a file, a boolean indicating if this is a temporary path
 * that needs to be deleted after processing, and a function to write the given
 * {@link dataOrPathOrZipEntry} into that temporary file if needed.
 *
 * @param dataOrPathOrZipEntry The contents of the file, or the path to an
 * existing file, or a (path to a zip file, name of an entry within that zip
 * file) tuple.
 */
export const makeFileForDataOrPathOrZipEntry = async (
    dataOrPathOrZipEntry: Uint8Array | string | ZipEntry,
): Promise<FileForDataOrPathOrZipEntry> => {
    let path: string;
    let isFileTemporary: boolean;
    let writeToTemporaryFile: () => Promise<void> | undefined;

    if (typeof dataOrPathOrZipEntry == "string") {
        path = dataOrPathOrZipEntry;
        isFileTemporary = false;
    } else {
        path = await makeTempFilePath();
        isFileTemporary = true;
        if (dataOrPathOrZipEntry instanceof Uint8Array) {
            writeToTemporaryFile = () =>
                fs.writeFile(path, dataOrPathOrZipEntry);
        } else {
            writeToTemporaryFile = async () => {
                const [zipPath, entryName] = dataOrPathOrZipEntry;
                const zip = new StreamZip.async({ file: zipPath });
                await zip.extract(entryName, path);
                zip.close();
            };
        }
    }

    return { path, isFileTemporary, writeToTemporaryFile };
};
