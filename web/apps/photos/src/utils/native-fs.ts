import { ensureElectron } from "@/next/electron";
import sanitize from "sanitize-filename";
import { splitFilenameAndExtension } from "utils/file";

export const ENTE_TRASH_FOLDER = "Trash";

/**
 * Sanitize string for use as file or directory name.
 *
 * Return a string suitable for use as a file or directory name by replacing
 * directory separators and invalid characters in the input string {@link s}
 * with "_".
 */
export const sanitizeFilename = (s: string) =>
    sanitize(s, { replacement: "_" });

const exists = (path: string) => ensureElectron().fs.exists(path);

export const getUniqueCollectionExportName = async (
    dir: string,
    collectionName: string,
): Promise<string> => {
    let collectionExportName = sanitizeFilename(collectionName);
    let count = 1;
    while (
        (await exists(`${dir}/${collectionExportName}`)) ||
        collectionExportName === ENTE_TRASH_FOLDER
    ) {
        collectionExportName = `${sanitizeFilename(collectionName)}(${count})`;
        count++;
    }
    return collectionExportName;
};

export const getUniqueFileExportName = async (
    collectionExportPath: string,
    filename: string,
) => {
    let fileExportName = sanitizeFilename(filename);
    let count = 1;
    while (await exists(`${collectionExportPath}/${fileExportName}`)) {
        const filenameParts = splitFilenameAndExtension(
            sanitizeFilename(filename),
        );
        if (filenameParts[1]) {
            fileExportName = `${filenameParts[0]}(${count}).${filenameParts[1]}`;
        } else {
            fileExportName = `${filenameParts[0]}(${count})`;
        }
        count++;
    }
    return fileExportName;
};
