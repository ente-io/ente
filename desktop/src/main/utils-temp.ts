import { app } from "electron/main";
import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import path from "path";

/**
 * Our very own directory within the system temp directory. Go crazy, but
 * remember to clean up, especially in exception handlers.
 */
const enteTempDirPath = async () => {
    const result = path.join(app.getPath("temp"), "ente");
    await fs.mkdir(result, { recursive: true });
    return result;
};

const randomPrefix = (length: number) => {
    const CHARACTERS =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    let result = "";
    const charactersLength = CHARACTERS.length;
    for (let i = 0; i < length; i++) {
        result += CHARACTERS.charAt(
            Math.floor(Math.random() * charactersLength),
        );
    }
    return result;
};

/**
 * Return the path to a temporary file with the given {@link formatSuffix}.
 *
 * The function returns the path to a file in the system temp directory (in an
 * Ente specific folder therin) with a random prefix and the given
 * {@link formatSuffix}. It ensures that there is no existing file with the same
 * name already.
 *
 * Use {@link deleteTempFile} to remove this file when you're done.
 */
export const makeTempFilePath = async (formatSuffix: string) => {
    const tempDir = await enteTempDirPath();
    let result: string;
    do {
        result = path.join(tempDir, randomPrefix(10) + "-" + formatSuffix);
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
