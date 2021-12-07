import { Collection } from 'services/collectionService';
import exportService, {
    CollectionIDPathMap,
    ExportRecord,
    METADATA_FOLDER_NAME,
} from 'services/exportService';
import { File } from 'services/fileService';
import { MetadataObject } from 'services/upload/uploadService';
import { formatDate, splitFilenameAndExtension } from 'utils/file';

export const getExportRecordFileUID = (file: File) =>
    `${file.id}_${file.collectionID}_${file.updationTime}`;

export const getExportQueuedFiles = (
    allFiles: File[],
    exportRecord: ExportRecord
) => {
    const queuedFiles = new Set(exportRecord?.queuedFiles);
    const unExportedFiles = allFiles.filter((file) => {
        if (queuedFiles.has(getExportRecordFileUID(file))) {
            return true;
        }
        return false;
    });
    return unExportedFiles;
};

export const getCollectionsCreatedAfterLastExport = (
    collections: Collection[],
    exportRecord: ExportRecord
) => {
    const exportedCollections = new Set(
        Object.keys(exportRecord?.exportedCollectionPaths ?? {}).map((x) =>
            Number(x)
        )
    );
    const unExportedCollections = collections.filter((collection) => {
        if (!exportedCollections.has(collection.id)) {
            return true;
        }
        return false;
    });
    return unExportedCollections;
};
export const getCollectionIDPathMapFromExportRecord = (
    exportRecord: ExportRecord
): CollectionIDPathMap => {
    return new Map<number, string>(
        Object.entries(exportRecord.exportedCollectionPaths ?? {}).map((e) => {
            return [Number(e[0]), String(e[1])];
        })
    );
};

export const getCollectionsRenamedAfterLastExport = (
    collections: Collection[],
    exportRecord: ExportRecord
) => {
    const collectionIDPathMap =
        getCollectionIDPathMapFromExportRecord(exportRecord);
    const renamedCollections = collections.filter((collection) => {
        if (collectionIDPathMap.has(collection.id)) {
            const currentFolderName = collectionIDPathMap.get(collection.id);
            const startIndex = currentFolderName.lastIndexOf('/');
            const lastIndex = currentFolderName.lastIndexOf('(');
            const nameRoot = currentFolderName.slice(
                startIndex + 1,
                lastIndex !== -1 ? lastIndex : currentFolderName.length
            );

            if (nameRoot !== sanitizeName(collection.name)) {
                return true;
            }
        }
        return false;
    });
    return renamedCollections;
};

export const getFilesUploadedAfterLastExport = (
    allFiles: File[],
    exportRecord: ExportRecord
) => {
    const exportedFiles = new Set(exportRecord?.exportedFiles);
    const unExportedFiles = allFiles.filter((file) => {
        if (!exportedFiles.has(getExportRecordFileUID(file))) {
            return true;
        }
        return false;
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
            return true;
        }
        return false;
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
            return true;
        }
        return false;
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

export const oldSanitizeName = (name: string) =>
    name.replaceAll('/', '_').replaceAll(' ', '_');

export const sanitizeName = (name: string) =>
    name.replace(/[^a-z0-9.]/gi, '_').toLowerCase();

export const getUniqueCollectionFolderPath = (
    dir: string,
    collectionName: string
): string => {
    let collectionFolderPath = `${dir}/${sanitizeName(collectionName)}`;
    let count = 1;
    while (exportService.exists(collectionFolderPath)) {
        collectionFolderPath = `${dir}/${sanitizeName(
            collectionName
        )}(${count})`;
        count++;
    }
    return collectionFolderPath;
};

export const getMetadataFolderPath = (collectionFolderPath: string) =>
    `${collectionFolderPath}/${METADATA_FOLDER_NAME}`;

export const getUniqueFileSaveName = (
    collectionPath: string,
    filename: string
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
) => `${dir}/${collection.id}_${oldSanitizeName(collection.name)}`;

export const getOldFileSavePath = (collectionFolderPath: string, file: File) =>
    `${collectionFolderPath}/${file.id}_${oldSanitizeName(
        file.metadata.title
    )}`;

export const getOldFileMetadataSavePath = (
    collectionFolderPath: string,
    file: File
) =>
    `${collectionFolderPath}/${METADATA_FOLDER_NAME}/${
        file.id
    }_${oldSanitizeName(file.metadata.title)}.json`;
