import { Collection } from 'types/collection';
import exportService from 'services/export';
import {
    ExportRecord,
    ExportRecordV1,
    ExportRecordV2,
    CollectionExportNames,
    FileExportNames,
    ExportedCollectionPaths,
} from 'types/export';

import { EnteFile } from 'types/file';

import { Metadata } from 'types/upload';
import { splitFilenameAndExtension } from 'utils/file';
import { ENTE_METADATA_FOLDER, ENTE_TRASH_FOLDER } from 'constants/export';
import sanitize from 'sanitize-filename';
import { formatDateTimeShort } from 'utils/time/format';

export const getExportRecordFileUID = (file: EnteFile) =>
    `${file.id}_${file.collectionID}_${file.updationTime}`;

export const convertCollectionIDFolderPathObjectToMap = (
    exportedCollectionPaths: ExportedCollectionPaths
): Map<number, string> => {
    return new Map<number, string>(
        Object.entries(exportedCollectionPaths ?? {}).map((e) => {
            return [Number(e[0]), String(e[1])];
        })
    );
};

export const convertCollectionIDExportNameObjectToMap = (
    exportedCollectionNames: CollectionExportNames
): Map<number, string> => {
    return new Map<number, string>(
        Object.entries(exportedCollectionNames ?? {}).map((e) => {
            return [Number(e[0]), String(e[1])];
        })
    );
};

export const convertFileIDExportNameObjectToMap = (
    exportedFileNames: FileExportNames
): Map<string, string> => {
    return new Map<string, string>(
        Object.entries(exportedFileNames ?? {}).map((e) => {
            return [String(e[0]), String(e[1])];
        })
    );
};

export const getRenamedCollections = (
    collections: Collection[],
    exportRecord: ExportRecord
) => {
    if (!exportRecord?.collectionExportNames) {
        return [];
    }
    const collectionIDFolderMap = convertCollectionIDExportNameObjectToMap(
        exportRecord.collectionExportNames
    );
    const renamedCollections = collections.filter((collection) => {
        if (collectionIDFolderMap.has(collection.id)) {
            const currentFolderName = collectionIDFolderMap.get(collection.id);

            if (currentFolderName !== sanitizeName(collection.name)) {
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
    if (!exportRecord?.collectionExportNames) {
        return [];
    }
    const presentCollections = new Set(
        collections.map((collection) => collection.id)
    );
    const deletedExportedCollections = Object.keys(
        exportRecord?.collectionExportNames
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
    if (!exportRecord?.fileExportNames) {
        return allFiles;
    }
    const exportedFiles = new Set(Object.keys(exportRecord?.fileExportNames));
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
    exportRecord: ExportRecordV1 | ExportRecordV2
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

export const getExportedFilePaths = (
    allFiles: EnteFile[],
    exportRecord: ExportRecord
) => {
    if (!exportRecord?.fileExportNames) {
        return [];
    }
    const exportedFileIds = new Set(Object.keys(exportRecord?.fileExportNames));
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
    if (!exportRecord?.fileExportNames) {
        return [];
    }
    const presentFileUIDs = new Set(
        allFiles?.map((file) => getExportRecordFileUID(file))
    );
    const deletedExportedFiles = Object.keys(
        exportRecord?.fileExportNames
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
    if (!exportRecord?.fileExportNames) {
        return [];
    }
    const collectionExportedFiles = Object.keys(
        exportRecord?.fileExportNames
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
    fileExportName: string,
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
            title: fileExportName,
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

export const getUniqueCollectionExportName = (
    dir: string,
    collectionID: number,
    collectionName: string
): string => {
    if (!exportService.checkAllElectronAPIsExists()) {
        return getOldCollectionExportPath(dir, collectionID, collectionName);
    }
    let collectionExportName = sanitizeName(collectionName);
    let count = 1;
    while (
        exportService.exists(getCollectionExportPath(dir, collectionExportName))
    ) {
        collectionExportName = `${collectionExportName}(${count})`;
        count++;
    }
    return collectionExportName;
};

export const getMetadataFolderPath = (collectionExportPath: string) =>
    `${collectionExportPath}/${ENTE_METADATA_FOLDER}`;

export const getUniqueFileExportName = (
    collectionExportPath: string,
    filename: string,
    fileID: number
) => {
    if (!exportService.checkAllElectronAPIsExists()) {
        return getOldFileExportName(filename, fileID);
    }
    let fileExportName = sanitizeName(filename);
    let count = 1;
    while (
        exportService.exists(
            getFileExportPath(collectionExportPath, fileExportName)
        )
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

export const getOldFileExportName = (filename: string, fileID: number) =>
    `${fileID}_${oldSanitizeName(filename)}`;

export const getFileMetadataExportPath = (
    collectionExportPath: string,
    fileExportName: string
) => `${collectionExportPath}/${ENTE_METADATA_FOLDER}/${fileExportName}.json`;

export const getCollectionExportPath = (
    exportFolder: string,
    collectionExportName: string
) => `${exportFolder}/${collectionExportName}`;

export const getFileExportPath = (
    collectionExportPath: string,
    fileExportName: string
) => `${collectionExportPath}/${fileExportName}`;

export const getOldCollectionExportPath = (
    dir: string,
    collectionID: number,
    collectionName: string
) => `${dir}/${collectionID}_${oldSanitizeName(collectionName)}`;

export const getOldfileExportPath = (
    collectionExportPath: string,
    file: EnteFile
) =>
    `${collectionExportPath}/${file.id}_${oldSanitizeName(
        file.metadata.title
    )}`;

export const getOldFileMetadataexportPath = (
    collectionExportPath: string,
    file: EnteFile
) =>
    `${collectionExportPath}/${ENTE_METADATA_FOLDER}/${
        file.id
    }_${oldSanitizeName(file.metadata.title)}.json`;

export const getUniqueFileExportNameForMigration = (
    collectionPath: string,
    filename: string,
    usedFilePaths: Map<string, Set<string>>
) => {
    let fileExportName = sanitizeName(filename);
    let count = 1;
    while (
        usedFilePaths
            .get(collectionPath)
            ?.has(getFileExportPath(collectionPath, fileExportName))
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
        .add(getFileExportPath(collectionPath, fileExportName));
    return fileExportName;
};

export const getTrashedFileExportPath = (exportDir: string, path: string) => {
    const fileRelativePath = path.replace(`${exportDir}/`, '');
    return `${exportDir}/${ENTE_TRASH_FOLDER}/${fileRelativePath}`;
};

// if filepath is /home/user/Ente/Export/Collection1/1.jpg
// then metadata path is /home/user/Ente/Export/Collection1/ENTE_METADATA_FOLDER/1.jpg.json
export const getMetadataFileExportPath = (filePath: string) => {
    // extract filename and collection folder path
    const filename = filePath.split('/').pop();
    const collectionExportPath = filePath.replace(`/${filename}`, '');
    return `${collectionExportPath}/${ENTE_METADATA_FOLDER}/${filename}.json`;
};
