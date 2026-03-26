/**
 * @file Utilities for native file system access.
 *
 * While they don't have any direct dependencies to our desktop app, they were
 * written for use by the code that runs in our desktop app.
 */

import { joinPath, nameAndExtension } from "ente-base/file-name";
import {
    exportMetadataDirectoryName,
    exportTrashDirectoryName,
} from "ente-gallery/export-dirs";
import sanitize from "sanitize-filename";

/**
 * Sanitize string for use as file or directory name.
 *
 * Return a string suitable for use as a file or directory name by replacing
 * directory separators and invalid characters in the input string {@link s}
 * with "_".
 */
const sanitizeFilename = (s: string) => sanitize(s, { replacement: "_" });

/**
 * Return a new sanitized and unique directory name based on {@link name} that
 * is not the same as any existing item in the given {@link directoryPath}.
 *
 * We also ensure we don't return names which might collide with our own special
 * directories.
 *
 * @param exists A function to check if an item already exists at the given
 * path. Usually, you'd pass `fs.exists` from {@link Electron}.
 *
 * See also: {@link safeFileame}
 */
export const safeDirectoryName = async (
    directoryPath: string,
    name: string,
    exists: (path: string) => Promise<boolean>,
): Promise<string> => {
    const specialDirectoryNames = [
        exportTrashDirectoryName,
        exportMetadataDirectoryName,
    ];

    let result = sanitizeFilename(name);
    let count = 1;
    while (
        (await exists(joinPath(directoryPath, result))) ||
        specialDirectoryNames.includes(result)
    ) {
        result = `${sanitizeFilename(name)}(${count})`;
        count++;
    }
    return result;
};

/**
 * Return a new sanitized and unique file name based on {@link name} that is not
 * the same as any existing item in the given {@link directoryPath}.
 *
 * This is a sibling of {@link safeDirectoryName} for use with file names.
 */
export const safeFileName = async (
    directoryPath: string,
    name: string,
    exists: (path: string) => Promise<boolean>,
) => {
    let result = sanitizeFilename(name);
    let count = 1;
    while (await exists(joinPath(directoryPath, result))) {
        const [fn, ext] = nameAndExtension(sanitizeFilename(name));
        if (ext) result = `${fn}(${count}).${ext}`;
        else result = `${fn}(${count})`;
        count++;
    }
    return result;
};
