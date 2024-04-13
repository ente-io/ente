import sanitize from "sanitize-filename";
import exportService from "services/export";
import { splitFilenameAndExtension } from "utils/file";

export const ENTE_TRASH_FOLDER = "Trash";

export const sanitizeName = (name: string) =>
    sanitize(name, { replacement: "_" });

export const getUniqueCollectionExportName = async (
    dir: string,
    collectionName: string,
): Promise<string> => {
    let collectionExportName = sanitizeName(collectionName);
    let count = 1;
    while (
        (await exportService.exists(`${dir}/${collectionExportName}`)) ||
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
    while (
        await exportService.exists(`${collectionExportPath}/${fileExportName}`)
    ) {
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
