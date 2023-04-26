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
import { ENTE_METADATA_FOLDER, ENTE_TRASH_FOLDER } from 'constants/export';
import sanitize from 'sanitize-filename';
import { formatDateTimeShort } from 'utils/time/format';

export const getExportRecordFileUID = (file: EnteFile) =>
    `${file.id}_${file.collectionID}_${file.updationTime}`;

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
    if (!exportRecord?.exportedCollectionPaths) {
        return [];
    }
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
    if (!exportRecord?.exportedCollectionPaths) {
        return [];
    }
    const presentCollections = new Set(
        collections.map((collection) => collection.id)
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
    if (!exportRecord?.exportedFilePaths) {
        return allFiles;
    }
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
    if (!exportRecord?.exportedFilePaths) {
        return [];
    }
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
    if (!exportRecord?.exportedFilePaths) {
        return [];
    }
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

export const getCollectionExportedFiles = (
    exportRecord: ExportRecord,
    collectionID: number
): string[] => {
    if (!exportRecord?.exportedFilePaths) {
        return [];
    }
    const collectionExportedFiles = Object.keys(
        exportRecord?.exportedFilePaths
    ).filter((fileUID) => {
        const fileCollectionID = Number(fileUID.split('_')[1]);
        if (fileCollectionID === collectionID) {
            return true;
        } else {
            return false;
        }
    });
    return collectionExportedFiles;
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

export const getTrashedFilePath = (exportDir: string, path: string) => {
    const fileRelativePath = path.replace(`${exportDir}/`, '');
    return `${exportDir}/${ENTE_TRASH_FOLDER}/${fileRelativePath}`;
};

// if filepath is /home/user/Ente/Export/Collection1/1.jpg
// then metadata path is /home/user/Ente/Export/Collection1/ENTE_METADATA_FOLDER/1.jpg.json
export const getMetadataFilePath = (filePath: string) => {
    // extract filename and collection folder path
    const filename = filePath.split('/').pop();
    const collectionFolderPath = filePath.replace(`/${filename}`, '');
    return `${collectionFolderPath}/${ENTE_METADATA_FOLDER}/${filename}.json`;
};
