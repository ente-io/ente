import { ensureElectron } from "@/next/electron";
import sanitize from "sanitize-filename";
import { splitFilenameAndExtension } from "utils/file";

export const ENTE_TRASH_FOLDER = "Trash";

export const sanitizeName = (name: string) =>
    sanitize(name, { replacement: "_" });

const exists = (path: string) => ensureElectron().fs.exists(path);

export const getUniqueCollectionExportName = async (
    dir: string,
    collectionName: string,
): Promise<string> => {
    let collectionExportName = sanitizeName(collectionName);
    let count = 1;
    while (
        (await exists(`${dir}/${collectionExportName}`)) ||
        collectionExportName === ENTE_TRASH_FOLDER
    ) {
        collectionExportName = `${sanitizeName(collectionName)}(${count})`;
        count++;
    }
    return collectionExportName;
};

export const getUniqueFileExportName = async (
    collectionExportPath: string,
    filename: string,
) => {
    let fileExportName = sanitizeName(filename);
    let count = 1;
    while (await exists(`${collectionExportPath}/${fileExportName}`)) {
        const filenameParts = splitFilenameAndExtension(sanitizeName(filename));
        if (filenameParts[1]) {
            fileExportName = `${filenameParts[0]}(${count}).${filenameParts[1]}`;
        } else {
            fileExportName = `${filenameParts[0]}(${count})`;
        }
        count++;
    }
    return fileExportName;
};
