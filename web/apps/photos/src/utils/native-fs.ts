import { ensureElectron } from "@/next/electron";
import sanitize from "sanitize-filename";
import { exportTrashDirectoryName } from "services/export";
import { splitFilenameAndExtension } from "utils/file";

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
 * Return a new unique directory name based on {@link name} that is not the same
 * as any existing directory in the given {@link directoryPath}.
 *
 * We also ensure we don't return names which might collide with our own special
 * directories.
 *
 * This function only works when we are running inside an electron app (since it
 * requires permissionless access to the native filesystem to find a new
 * filename that doesn't conflict with any existing items).
 *
 * See also: {@link santizedUniqueFileName}
 */
export const safeDirectoryName = async (
    directoryPath: string,
    name: string,
): Promise<string> => {
    let result = sanitizeFilename(name);
    let count = 1;
    while (
        (await exists(`${directoryPath}/${result}`)) ||
        result == exportTrashDirectoryName
    ) {
        result = `${sanitizeFilename(name)}(${count})`;
        count++;
    }
    return result;
};

/**
 * Return a new unique file name based on {@link name} that is not the same as
 * any existing directory in the given {@link directoryPath}.
 *
 * This function only works when we are running inside an electron app.
 * @see {@link safeDirectoryName}.
 */
export const sanitizedUniqueFileName = async (
    directoryPath: string,
    name: string,
) => {
    let fileExportName = sanitizeFilename(name);
    let count = 1;
    while (await exists(`${directoryPath}/${fileExportName}`)) {
        const filenameParts = splitFilenameAndExtension(sanitizeFilename(name));
        if (filenameParts[1]) {
            fileExportName = `${filenameParts[0]}(${count}).${filenameParts[1]}`;
        } else {
            fileExportName = `${filenameParts[0]}(${count})`;
        }
        count++;
    }
    return fileExportName;
};

const exists = (path: string) => ensureElectron().fs.exists(path);
