import { ensureElectron } from "@/next/electron";
import { nameAndExtension } from "@/next/file";
import sanitize from "sanitize-filename";
import {
    exportMetadataDirectoryName,
    exportTrashDirectoryName,
} from "services/export";

/**
 * Sanitize string for use as file or directory name.
 *
 * Return a string suitable for use as a file or directory name by replacing
 * directory separators and invalid characters in the input string {@link s}
 * with "_".
 */
export const sanitizeFilename = (s: string) =>
    sanitize(s, { replacement: "_" });

/**
 * Return a new sanitized and unique directory name based on {@link name} that
 * is not the same as any existing item in the given {@link directoryPath}.
 *
 * We also ensure we don't return names which might collide with our own special
 * directories.
 *
 * This function only works when we are running inside an electron app (since it
 * requires permissionless access to the native filesystem to find a new
 * filename that doesn't conflict with any existing items).
 *
 * See also: {@link safeDirectoryName}
 */
export const safeDirectoryName = async (
    directoryPath: string,
    name: string,
): Promise<string> => {
    const specialDirectoryNames = [
        exportTrashDirectoryName,
        exportMetadataDirectoryName,
    ];

    let result = sanitizeFilename(name);
    let count = 1;
    while (
        (await exists(`${directoryPath}/${result}`)) ||
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
 * This function only works when we are running inside an electron app.
 * @see {@link safeDirectoryName}.
 */
export const safeFileName = async (directoryPath: string, name: string) => {
    let result = sanitizeFilename(name);
    let count = 1;
    while (await exists(`${directoryPath}/${result}`)) {
        const [fn, ext] = nameAndExtension(sanitizeFilename(name));
        if (ext) result = `${fn}(${count}).${ext}`;
        else result = `${fn}(${count})`;
        count++;
    }
    return result;
};

const exists = (path: string) => ensureElectron().fs.exists(path);
