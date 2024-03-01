import { ENTE_METADATA_FOLDER } from "constants/export";
import exportService from "services/export";
import {
    ExportedCollectionPaths,
    ExportRecordV0,
    ExportRecordV1,
    ExportRecordV2,
} from "types/export";
import { EnteFile } from "types/file";
import { splitFilenameAndExtension } from "utils/ffmpeg";
import { getExportRecordFileUID, sanitizeName } from ".";

export const convertCollectionIDFolderPathObjectToMap = (
    exportedCollectionPaths: ExportedCollectionPaths,
): Map<number, string> => {
    return new Map<number, string>(
        Object.entries(exportedCollectionPaths ?? {}).map((e) => {
            return [Number(e[0]), String(e[1])];
        }),
    );
};

export const getExportedFiles = (
    allFiles: EnteFile[],
    exportRecord: ExportRecordV0 | ExportRecordV1 | ExportRecordV2,
) => {
    if (!exportRecord?.exportedFiles) {
        return [];
    }
    const exportedFileIds = new Set(exportRecord?.exportedFiles);
    const exportedFiles = allFiles.filter((file) => {
        if (exportedFileIds.has(getExportRecordFileUID(file))) {
            return true;
        } else {
            return false;
        }
    });
    return exportedFiles;
};

export const oldSanitizeName = (name: string) =>
    name.replaceAll("/", "_").replaceAll(" ", "_");

export const getUniqueCollectionFolderPath = (
    dir: string,
    collectionName: string,
): string => {
    let collectionFolderPath = `${dir}/${sanitizeName(collectionName)}`;
    let count = 1;
    while (exportService.exists(collectionFolderPath)) {
        collectionFolderPath = `${dir}/${sanitizeName(
            collectionName,
        )}(${count})`;
        count++;
    }
    return collectionFolderPath;
};

export const getMetadataFolderPath = (collectionFolderPath: string) =>
    `${collectionFolderPath}/${ENTE_METADATA_FOLDER}`;

export const getUniqueFileSaveName = (
    collectionPath: string,
    filename: string,
) => {
    let fileSaveName = sanitizeName(filename);
    let count = 1;
    while (
        exportService.exists(getFileSavePath(collectionPath, fileSaveName))
    ) {
        const filenameParts = splitFilenameAndExtension(sanitizeName(filename));
        if (filenameParts[1]) {
            fileSaveName = `${filenameParts[0]}(${count}).${filenameParts[1]}`;
        } else {
            fileSaveName = `${filenameParts[0]}(${count})`;
        }
        count++;
    }
    return fileSaveName;
};

export const getOldFileSaveName = (filename: string, fileID: number) =>
    `${fileID}_${oldSanitizeName(filename)}`;

export const getFileMetadataSavePath = (
    collectionFolderPath: string,
    fileSaveName: string,
) => `${collectionFolderPath}/${ENTE_METADATA_FOLDER}/${fileSaveName}.json`;

export const getFileSavePath = (
    collectionFolderPath: string,
    fileSaveName: string,
) => `${collectionFolderPath}/${fileSaveName}`;

export const getOldCollectionFolderPath = (
    dir: string,
    collectionID: number,
    collectionName: string,
) => `${dir}/${collectionID}_${oldSanitizeName(collectionName)}`;

export const getOldFileSavePath = (
    collectionFolderPath: string,
    file: EnteFile,
) =>
    `${collectionFolderPath}/${file.id}_${oldSanitizeName(
        file.metadata.title,
    )}`;

export const getOldFileMetadataSavePath = (
    collectionFolderPath: string,
    file: EnteFile,
) =>
    `${collectionFolderPath}/${ENTE_METADATA_FOLDER}/${
        file.id
    }_${oldSanitizeName(file.metadata.title)}.json`;

export const getUniqueFileExportNameForMigration = (
    collectionPath: string,
    filename: string,
    usedFilePaths: Map<string, Set<string>>,
) => {
    let fileExportName = sanitizeName(filename);
    let count = 1;
    while (
        usedFilePaths
            .get(collectionPath)
            ?.has(getFileSavePath(collectionPath, fileExportName))
    ) {
        const filenameParts = splitFilenameAndExtension(sanitizeName(filename));
        if (filenameParts[1]) {
            fileExportName = `${filenameParts[0]}(${count}).${filenameParts[1]}`;
        } else {
            fileExportName = `${filenameParts[0]}(${count})`;
        }
        count++;
    }
    if (!usedFilePaths.has(collectionPath)) {
        usedFilePaths.set(collectionPath, new Set());
    }
    usedFilePaths
        .get(collectionPath)
        .add(getFileSavePath(collectionPath, fileExportName));
    return fileExportName;
};
