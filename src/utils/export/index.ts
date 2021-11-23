import { Collection } from 'services/collectionService';
import { ExportRecord, METADATA_FOLDER_NAME } from 'services/exportService';
import { File } from 'services/fileService';
import { MetadataObject } from 'services/upload/uploadService';
import { formatDate, splitFilenameAndExtension } from 'utils/file';

export const getExportRecordFileUID = (file: File) =>
    `${file.id}_${file.collectionID}_${file.updationTime}`;

export const getExportPendingFiles = (
    allFiles: File[],
    exportRecord: ExportRecord
) => {
    const queuedFiles = new Set(exportRecord?.queuedFiles);
    const unExportedFiles = allFiles.filter((file) => {
        if (queuedFiles.has(getExportRecordFileUID(file))) {
            return file;
        }
    });
    return unExportedFiles;
};

export const getFilesUploadedAfterLastExport = (
    allFiles: File[],
    exportRecord: ExportRecord
) => {
    const exportedFiles = new Set(exportRecord?.exportedFiles);
    const unExportedFiles = allFiles.filter((file) => {
        if (!exportedFiles.has(getExportRecordFileUID(file))) {
            return file;
        }
    });
    return unExportedFiles;
};

export const getExportedFiles = (
    allFiles: File[],
    exportRecord: ExportRecord
) => {
    const exportedFileIds = new Set(exportRecord?.exportedFiles);
    const exportedFiles = allFiles.filter((file) => {
        if (exportedFileIds.has(getExportRecordFileUID(file))) {
            return file;
        }
    });
    return exportedFiles;
};

export const getExportFailedFiles = (
    allFiles: File[],
    exportRecord: ExportRecord
) => {
    const failedFiles = new Set(exportRecord?.failedFiles);
    const filesToExport = allFiles.filter((file) => {
        if (failedFiles.has(getExportRecordFileUID(file))) {
            return file;
        }
    });
    return filesToExport;
};

export const dedupe = (files: any[]) => {
    const fileSet = new Set(files);
    const dedupedArray = new Array(...fileSet);
    return dedupedArray;
};

export const getGoogleLikeMetadataFile = (
    fileSaveName: string,
    metadata: MetadataObject
) => {
    const creationTime = Math.floor(metadata.creationTime / 1000000);
    const modificationTime = Math.floor(
        (metadata.modificationTime ?? metadata.creationTime) / 1000000
    );
    return JSON.stringify(
        {
            title: fileSaveName,
            creationTime: {
                timestamp: creationTime,
                formatted: formatDate(creationTime * 1000),
            },
            modificationTime: {
                timestamp: modificationTime,
                formatted: formatDate(modificationTime * 1000),
            },
            geoData: {
                latitude: metadata.latitude,
                longitude: metadata.longitude,
            },
        },
        null,
        2
    );
};

export const sanitizeName = (name: string) =>
    name.replaceAll('/', '_').replaceAll(' ', '_');

export const getUniqueCollectionFolderPath = (
    dir: string,
    collectionName: string,
    usedCollectionPaths: Set<string>
): string => {
    let collectionFolderPath = `${dir}/${sanitizeName(collectionName)}`;
    let count = 1;
    while (usedCollectionPaths.has(collectionFolderPath)) {
        collectionFolderPath = `${dir}/${sanitizeName(
            collectionName
        )}(${count})`;
        count++;
    }
    usedCollectionPaths.add(collectionFolderPath);
    return collectionFolderPath;
};

export const getMetadataFolderPath = (collectionFolderPath: string) =>
    `${collectionFolderPath}/${METADATA_FOLDER_NAME}`;

export const getUniqueFileSaveName = (
    filename: string,
    usedFilenamesInCollection: Set<string>
) => {
    let fileSaveName = sanitizeName(filename);
    const count = 1;
    while (usedFilenamesInCollection.has(fileSaveName)) {
        const filenameParts = splitFilenameAndExtension(fileSaveName);
        if (filenameParts[1]) {
            fileSaveName = `${filenameParts[0]}(${count}).${filenameParts[1]}`;
        } else {
            fileSaveName = `${filenameParts[0]}(${count})`;
        }
    }
    usedFilenamesInCollection.add(fileSaveName);
    return fileSaveName;
};

export const getFileMetadataSavePath = (
    collectionFolderPath: string,
    fileSaveName: string
) => `${collectionFolderPath}/${METADATA_FOLDER_NAME}/${fileSaveName}.json`;

export const getFileSavePath = (
    collectionFolderPath: string,
    fileSaveName: string
) => `${collectionFolderPath}/${fileSaveName}`;

export const getOldCollectionFolderPath = (
    dir: string,
    collection: Collection
) => `${dir}/${collection.id}_${sanitizeName(collection.name)}`;

export const getOldFileSavePath = (collectionFolderPath: string, file: File) =>
    `${collectionFolderPath}/${file.id}_${sanitizeName(file.metadata.title)}`;

export const getOldFileMetadataSavePath = (
    collectionFolderPath: string,
    file: File
) =>
    `${collectionFolderPath}/${METADATA_FOLDER_NAME}/${file.id}_${sanitizeName(
        file.metadata.title
    )}.json`;
