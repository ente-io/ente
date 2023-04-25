import { Collection } from 'types/collection';
import exportService from 'services/exportService';
import {
    ExportRecord,
    ExportedCollectionPaths,
    ExportedFilePaths,
} from 'types/export';

import { EnteFile } from 'types/file';

import { Metadata } from 'types/upload';
import { splitFilenameAndExtension } from 'utils/file';
import { ENTE_METADATA_FOLDER } from 'constants/export';
import sanitize from 'sanitize-filename';
import { formatDateTimeShort } from 'utils/time/format';

export const getExportRecordFileUID = (file: EnteFile) =>
    `${file.id}_${file.collectionID}_${file.updationTime}`;

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
export const convertCollectionIDPathObjectToMap = (
    exportedCollectionPaths: ExportedCollectionPaths
): Map<number, string> => {
    return new Map<number, string>(
        Object.entries(exportedCollectionPaths ?? {}).map((e) => {
            return [Number(e[0]), String(e[1])];
        })
    );
};

export const convertFileIDPathObjectToMap = (
    exportedFilePaths: ExportedFilePaths
): Map<string, string> => {
    return new Map<string, string>(
        Object.entries(exportedFilePaths ?? {}).map((e) => {
            return [String(e[0]), String(e[1])];
        })
    );
};

export const getRenamedCollections = (
    collections: Collection[],
    exportRecord: ExportRecord
) => {
    const collectionIDPathMap = convertCollectionIDPathObjectToMap(
        exportRecord.exportedCollectionPaths
    );
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

export const getDeletedExportedCollections = (
    collections: Collection[],
    exportRecord: ExportRecord
) => {
    const presentCollections = new Set(
        collections?.map((collection) => collection.id)
    );
    const deletedExportedCollections = Object.keys(
        exportRecord?.exportedCollectionPaths
    )
        .map(Number)
        .filter((collectionID) => {
            if (!presentCollections.has(collectionID)) {
                return true;
            }
            return false;
        });
    return deletedExportedCollections;
};

export const getUnExportedFiles = (
    allFiles: EnteFile[],
    exportRecord: ExportRecord
) => {
    const exportedFiles = new Set(Object.keys(exportRecord?.exportedFilePaths));
    const unExportedFiles = allFiles.filter((file) => {
        if (!exportedFiles.has(getExportRecordFileUID(file))) {
            return true;
        }
        return false;
    });
    return unExportedFiles;
};

export const getExportedFiles = (
    allFiles: EnteFile[],
    exportRecord: ExportRecord
) => {
    const exportedFileIds = new Set(
        Object.keys(exportRecord?.exportedFilePaths)
    );
    const exportedFiles = allFiles.filter((file) => {
        if (exportedFileIds.has(getExportRecordFileUID(file))) {
            return true;
        }
        return false;
    });
    return exportedFiles;
};

export const getDeletedExportedFiles = (
    allFiles: EnteFile[],
    exportRecord: ExportRecord
): string[] => {
    const presentFileUIDs = new Set(
        allFiles?.map((file) => getExportRecordFileUID(file))
    );
    const deletedExportedFiles = Object.keys(
        exportRecord?.exportedFilePaths
    ).filter((fileUID) => {
        if (!presentFileUIDs.has(fileUID)) {
            return true;
        }
        return false;
    });
    return deletedExportedFiles;
};

export const getGoogleLikeMetadataFile = (
    fileSaveName: string,
    file: EnteFile
) => {
    const metadata: Metadata = file.metadata;
    const creationTime = Math.floor(metadata.creationTime / 1000000);
    const modificationTime = Math.floor(
        (metadata.modificationTime ?? metadata.creationTime) / 1000000
    );
    const captionValue: string = file?.pubMagicMetadata?.data?.caption;
    return JSON.stringify(
        {
            title: fileSaveName,
            caption: captionValue,
            creationTime: {
                timestamp: creationTime,
                formatted: formatDateTimeShort(creationTime * 1000),
            },
            modificationTime: {
                timestamp: modificationTime,
                formatted: formatDateTimeShort(modificationTime * 1000),
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
    sanitize(name, { replacement: '_' });

export const getUniqueCollectionFolderPath = (
    dir: string,
    collectionID: number,
    collectionName: string
): string => {
    if (!exportService.checkAllElectronAPIsExists()) {
        return getOldCollectionFolderPath(dir, collectionID, collectionName);
    }
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
    `${collectionFolderPath}/${ENTE_METADATA_FOLDER}`;

export const getUniqueFileSaveName = (
    collectionPath: string,
    filename: string,
    fileID: number
) => {
    if (!exportService.checkAllElectronAPIsExists()) {
        return getOldFileSaveName(filename, fileID);
    }
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
    fileSaveName: string
) => `${collectionFolderPath}/${ENTE_METADATA_FOLDER}/${fileSaveName}.json`;

export const getFileSavePath = (
    collectionFolderPath: string,
    fileSaveName: string
) => `${collectionFolderPath}/${fileSaveName}`;

export const getOldCollectionFolderPath = (
    dir: string,
    collectionID: number,
    collectionName: string
) => `${dir}/${collectionID}_${oldSanitizeName(collectionName)}`;

export const getOldFileSavePath = (
    collectionFolderPath: string,
    file: EnteFile
) =>
    `${collectionFolderPath}/${file.id}_${oldSanitizeName(
        file.metadata.title
    )}`;

export const getOldFileMetadataSavePath = (
    collectionFolderPath: string,
    file: EnteFile
) =>
    `${collectionFolderPath}/${ENTE_METADATA_FOLDER}/${
        file.id
    }_${oldSanitizeName(file.metadata.title)}.json`;

export const getUniqueFileSaveNameForMigration = (
    collectionPath: string,
    filename: string,
    usedFilePaths: Set<string>
) => {
    let fileSaveName = sanitizeName(filename);
    let count = 1;
    while (usedFilePaths.has(getFileSavePath(collectionPath, fileSaveName))) {
        usedFilePaths.add(getFileSavePath(collectionPath, fileSaveName));
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
