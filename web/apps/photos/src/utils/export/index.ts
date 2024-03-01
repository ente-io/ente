import exportService from "services/export";
import { Collection } from "types/collection";
import {
    CollectionExportNames,
    ExportRecord,
    FileExportNames,
} from "types/export";

import { EnteFile } from "types/file";

import { formatDateTimeShort } from "@ente/shared/time/format";
import {
    ENTE_METADATA_FOLDER,
    ENTE_TRASH_FOLDER,
    ExportStage,
} from "constants/export";
import sanitize from "sanitize-filename";
import { Metadata } from "types/upload";
import { getCollectionUserFacingName } from "utils/collection";
import { splitFilenameAndExtension } from "utils/file";

export const getExportRecordFileUID = (file: EnteFile) =>
    `${file.id}_${file.collectionID}_${file.updationTime}`;

export const getCollectionIDFromFileUID = (fileUID: string) =>
    Number(fileUID.split("_")[1]);

export const convertCollectionIDExportNameObjectToMap = (
    collectionExportNames: CollectionExportNames,
): Map<number, string> => {
    return new Map<number, string>(
        Object.entries(collectionExportNames ?? {}).map((e) => {
            return [Number(e[0]), String(e[1])];
        }),
    );
};

export const convertFileIDExportNameObjectToMap = (
    fileExportNames: FileExportNames,
): Map<string, string> => {
    return new Map<string, string>(
        Object.entries(fileExportNames ?? {}).map((e) => {
            return [String(e[0]), String(e[1])];
        }),
    );
};

export const getRenamedExportedCollections = (
    collections: Collection[],
    exportRecord: ExportRecord,
) => {
    if (!exportRecord?.collectionExportNames) {
        return [];
    }
    const collectionIDExportNameMap = convertCollectionIDExportNameObjectToMap(
        exportRecord.collectionExportNames,
    );
    const renamedCollections = collections.filter((collection) => {
        if (collectionIDExportNameMap.has(collection.id)) {
            const currentExportName = collectionIDExportNameMap.get(
                collection.id,
            );

            const collectionExportName =
                getCollectionUserFacingName(collection);

            if (currentExportName === collectionExportName) {
                return false;
            }
            const hasNumberedSuffix = currentExportName.match(/\(\d+\)$/);
            const currentExportNameWithoutNumberedSuffix = hasNumberedSuffix
                ? currentExportName.replace(/\(\d+\)$/, "")
                : currentExportName;

            return (
                collectionExportName !== currentExportNameWithoutNumberedSuffix
            );
        }
        return false;
    });
    return renamedCollections;
};

export const getDeletedExportedCollections = (
    collections: Collection[],
    exportRecord: ExportRecord,
) => {
    if (!exportRecord?.collectionExportNames) {
        return [];
    }
    const presentCollections = new Set(
        collections.map((collection) => collection.id),
    );
    const deletedExportedCollections = Object.keys(
        exportRecord?.collectionExportNames,
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
    exportRecord: ExportRecord,
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

export const getDeletedExportedFiles = (
    allFiles: EnteFile[],
    exportRecord: ExportRecord,
): string[] => {
    if (!exportRecord?.fileExportNames) {
        return [];
    }
    const presentFileUIDs = new Set(
        allFiles?.map((file) => getExportRecordFileUID(file)),
    );
    const deletedExportedFiles = Object.keys(
        exportRecord?.fileExportNames,
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
    collectionID: number,
): string[] => {
    if (!exportRecord?.fileExportNames) {
        return [];
    }
    const collectionExportedFiles = Object.keys(
        exportRecord?.fileExportNames,
    ).filter((fileUID) => {
        const fileCollectionID = Number(fileUID.split("_")[1]);
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
    file: EnteFile,
) => {
    const metadata: Metadata = file.metadata;
    const creationTime = Math.floor(metadata.creationTime / 1000000);
    const modificationTime = Math.floor(
        (metadata.modificationTime ?? metadata.creationTime) / 1000000,
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
        2,
    );
};

export const sanitizeName = (name: string) =>
    sanitize(name, { replacement: "_" });

export const getUniqueCollectionExportName = (
    dir: string,
    collectionName: string,
): string => {
    let collectionExportName = sanitizeName(collectionName);
    let count = 1;
    while (
        exportService.exists(
            getCollectionExportPath(dir, collectionExportName),
        ) ||
        collectionExportName === ENTE_TRASH_FOLDER
    ) {
        collectionExportName = `${sanitizeName(collectionName)}(${count})`;
        count++;
    }
    return collectionExportName;
};

export const getMetadataFolderExportPath = (collectionExportPath: string) =>
    `${collectionExportPath}/${ENTE_METADATA_FOLDER}`;

export const getUniqueFileExportName = (
    collectionExportPath: string,
    filename: string,
) => {
    let fileExportName = sanitizeName(filename);
    let count = 1;
    while (
        exportService.exists(
            getFileExportPath(collectionExportPath, fileExportName),
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

export const getFileMetadataExportPath = (
    collectionExportPath: string,
    fileExportName: string,
) => `${collectionExportPath}/${ENTE_METADATA_FOLDER}/${fileExportName}.json`;

export const getCollectionExportPath = (
    exportFolder: string,
    collectionExportName: string,
) => `${exportFolder}/${collectionExportName}`;

export const getFileExportPath = (
    collectionExportPath: string,
    fileExportName: string,
) => `${collectionExportPath}/${fileExportName}`;

export const getTrashedFileExportPath = (exportDir: string, path: string) => {
    const fileRelativePath = path.replace(`${exportDir}/`, "");
    let trashedFilePath = `${exportDir}/${ENTE_TRASH_FOLDER}/${fileRelativePath}`;
    let count = 1;
    while (exportService.exists(trashedFilePath)) {
        const trashedFilePathParts = splitFilenameAndExtension(trashedFilePath);
        if (trashedFilePathParts[1]) {
            trashedFilePath = `${trashedFilePathParts[0]}(${count}).${trashedFilePathParts[1]}`;
        } else {
            trashedFilePath = `${trashedFilePathParts[0]}(${count})`;
        }
        count++;
    }
    return trashedFilePath;
};

// if filepath is /home/user/Ente/Export/Collection1/1.jpg
// then metadata path is /home/user/Ente/Export/Collection1/ENTE_METADATA_FOLDER/1.jpg.json
export const getMetadataFileExportPath = (filePath: string) => {
    // extract filename and collection folder path
    const filename = filePath.split("/").pop();
    const collectionExportPath = filePath.replace(`/${filename}`, "");
    return `${collectionExportPath}/${ENTE_METADATA_FOLDER}/${filename}.json`;
};

export const getLivePhotoExportName = (
    imageExportName: string,
    videoExportName: string,
) =>
    JSON.stringify({
        image: imageExportName,
        video: videoExportName,
    });

export const isLivePhotoExportName = (exportName: string) => {
    try {
        JSON.parse(exportName);
        return true;
    } catch (e) {
        return false;
    }
};

export const parseLivePhotoExportName = (
    livePhotoExportName: string,
): { image: string; video: string } => {
    const { image, video } = JSON.parse(livePhotoExportName);
    return { image, video };
};

export const isExportInProgress = (exportStage: ExportStage) =>
    exportStage > ExportStage.INIT && exportStage < ExportStage.FINISHED;
