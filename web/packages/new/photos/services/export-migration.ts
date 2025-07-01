// TODO: Audit this file
/* eslint-disable @typescript-eslint/require-await */
/* eslint-disable @typescript-eslint/ban-ts-comment */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
import type { User } from "ente-accounts/services/user";
import { ensureElectron } from "ente-base/electron";
import { joinPath, nameAndExtension } from "ente-base/file-name";
import log from "ente-base/log";
import { exportMetadataDirectoryName } from "ente-gallery/export-dirs";
import { downloadManager } from "ente-gallery/services/download";
import type { Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { decodeLivePhoto } from "ente-media/live-photo";
import {
    safeDirectoryName,
    safeFileName,
    sanitizeFilename,
} from "ente-new/photos/utils/native-fs";
import { getData } from "ente-shared/storage/localStorage";
import { wait } from "ente-utils/promise";
import exportService, {
    getCollectionIDFromFileUID,
    getExportRecordFileUID,
    getLivePhotoExportName,
    getMetadataFolderExportPath,
    type CollectionExportNames,
    type ExportProgress,
    type ExportStage,
    type FileExportNames,
} from "./export";
import { savedCollectionFiles, savedCollections } from "./photos-fdb";

type ExportedCollectionPaths = Record<number, string>;

interface ExportRecordV0 {
    stage: ExportStage;
    lastAttemptTimestamp: number;
    progress: ExportProgress;
    queuedFiles: string[];
    exportedFiles: string[];
    failedFiles: string[];
}

interface ExportRecordV1 {
    version: number;
    stage: ExportStage;
    lastAttemptTimestamp: number;
    progress: ExportProgress;
    queuedFiles: string[];
    exportedFiles: string[];
    failedFiles: string[];
    exportedCollectionPaths: ExportedCollectionPaths;
}

interface ExportRecordV2 {
    version: number;
    stage: ExportStage;
    lastAttemptTimestamp: number;
    exportedFiles: string[];
    exportedCollectionPaths: ExportedCollectionPaths;
}

export interface ExportRecord {
    version: number;
    stage: ExportStage;
    lastAttemptTimestamp: number;
    collectionExportNames: CollectionExportNames;
    fileExportNames: FileExportNames;
}

export async function migrateExport(
    exportDir: string,
    exportRecord: ExportRecordV1 | ExportRecordV2 | ExportRecord,
    updateProgress: (progress: ExportProgress) => void,
) {
    try {
        log.info(`current export version: ${exportRecord.version}`);
        if (exportRecord.version === 0) {
            log.info("migrating export to version 1");
            await migrationV0ToV1(exportDir, exportRecord as ExportRecordV0);
            exportRecord = await exportService.updateExportRecord(exportDir, {
                version: 1,
            });
            log.info("migration to version 1 complete");
        }
        if (exportRecord.version === 1) {
            log.info("migrating export to version 2");
            await migrationV1ToV2(exportRecord as ExportRecordV1, exportDir);
            exportRecord = await exportService.updateExportRecord(exportDir, {
                version: 2,
            });
            log.info("migration to version 2 complete");
        }
        if (exportRecord.version === 2) {
            log.info("migrating export to version 3");
            await migrationV2ToV3(
                exportDir,
                exportRecord as ExportRecordV2,
                updateProgress,
            );
            exportRecord = await exportService.updateExportRecord(exportDir, {
                version: 3,
            });
            log.info("migration to version 3 complete");
        }

        if (exportRecord.version === 3) {
            log.info("migrating export to version 4");
            await migrationV3ToV4(exportDir, exportRecord as ExportRecord);
            exportRecord = await exportService.updateExportRecord(exportDir, {
                version: 4,
            });
            log.info("migration to version 4 complete");
        }
        if (exportRecord.version === 4) {
            log.info("migrating export to version 5");
            await migrationV4ToV5(exportDir, exportRecord as ExportRecord);
            exportRecord = await exportService.updateExportRecord(exportDir, {
                version: 5,
            });
            log.info("migration to version 5 complete");
        }
        log.info(`Record at latest version`);
    } catch (e) {
        log.error("export record migration failed", e);
        throw e;
    }
}

async function migrationV0ToV1(
    exportDir: string,
    exportRecord: ExportRecordV0,
) {
    if (!exportRecord?.exportedFiles) {
        return;
    }
    const collectionIDPathMap = new Map<number, string>();
    const user: User = getData("user");
    const localFiles = await savedCollectionFiles();
    const localCollections = await savedCollections();
    const personalFiles = getIDBasedSortedFiles(
        localFiles.filter((file) => file.ownerID == user.id),
    );
    const personalCollections = localCollections.filter(
        (collection) => collection.owner.id === user?.id,
    );
    await migrateCollectionFolders(
        personalCollections,
        exportDir,
        collectionIDPathMap,
    );
    await migrateFiles(
        getExportedFiles(personalFiles, exportRecord),
        collectionIDPathMap,
    );
}

const getIDBasedSortedFiles = (files: EnteFile[]) => {
    return files.sort((a, b) => a.id - b.id);
};

async function migrationV1ToV2(
    exportRecord: ExportRecordV1,
    exportDir: string,
) {
    await removeDeprecatedExportRecordProperties(exportRecord, exportDir);
}

async function migrationV2ToV3(
    exportDir: string,
    exportRecord: ExportRecordV2,
    updateProgress: (progress: ExportProgress) => void,
) {
    if (!exportRecord?.exportedFiles) {
        return;
    }
    const user: User = getData("user");
    const localFiles = await savedCollectionFiles();
    const personalFiles = getIDBasedSortedFiles(
        localFiles.filter((file) => file.ownerID == user.id),
    );

    const collectionExportNames =
        await getCollectionExportNamesFromExportedCollectionPaths(exportRecord);

    const fileExportNames = await getFileExportNamesFromExportedFiles(
        exportRecord,
        getExportedFiles(personalFiles, exportRecord),
        updateProgress,
    );

    // @ts-ignore
    exportRecord.exportedCollectionPaths = undefined;
    // @ts-ignore
    exportRecord.exportedFiles = undefined;
    const updatedExportRecord: ExportRecord = {
        ...exportRecord,
        fileExportNames,
        collectionExportNames,
    };
    await exportService.updateExportRecord(exportDir, updatedExportRecord);
}

async function migrationV3ToV4(exportDir: string, exportRecord: ExportRecord) {
    if (!exportRecord?.collectionExportNames) {
        return;
    }

    const collectionExportNames = reMigrateCollectionExportNames(exportRecord);

    const updatedExportRecord: ExportRecord = {
        ...exportRecord,
        collectionExportNames,
    };

    await exportService.updateExportRecord(exportDir, updatedExportRecord);
}

async function migrationV4ToV5(exportDir: string, exportRecord: ExportRecord) {
    await removeCollectionExportMissingMetadataFolder(exportDir, exportRecord);
}

/**
 * Update the folder name of already exported folders from the earlier format of
 * `collectionID_collectionName` to newer `collectionName(numbered)` format.
 */
const migrateCollectionFolders = async (
    collections: Collection[],
    exportDir: string,
    collectionIDPathMap: Map<number, string>,
) => {
    const fs = ensureElectron().fs;
    for (const collection of collections) {
        const oldPath = joinPath(
            exportDir,
            `${collection.id}_${oldSanitizeName(collection.name)}`,
        );
        const newPath = await safeDirectoryName(
            exportDir,
            collection.name,
            fs.exists,
        );
        collectionIDPathMap.set(collection.id, newPath);
        if (!(await fs.exists(oldPath))) continue;
        await fs.rename(oldPath, newPath);
        await addCollectionExportedRecordV1(exportDir, collection.id, newPath);
    }
};

/*
    This updates the file name of already exported files from the earlier format of
    `fileID_fileName` to newer `fileName(numbered)` format
*/
async function migrateFiles(
    files: EnteFile[],
    collectionIDPathMap: Map<number, string>,
) {
    const fs = ensureElectron().fs;
    for (const file of files) {
        const collectionPath = collectionIDPathMap.get(file.collectionID);
        const metadataPath = joinPath(
            // @ts-ignore
            collectionPath,
            exportMetadataDirectoryName,
        );

        const oldFileName = `${file.id}_${oldSanitizeName(fileFileName(file))}`;
        // @ts-ignore
        const oldFilePath = joinPath(collectionPath, oldFileName);
        const oldFileMetadataPath = joinPath(
            metadataPath,
            `${oldFileName}.json`,
        );

        const newFileName = await safeFileName(
            // @ts-ignore
            collectionPath,
            fileFileName(file),
            fs.exists,
        );
        // @ts-ignore
        const newFilePath = joinPath(collectionPath, newFileName);
        const newFileMetadataPath = joinPath(
            metadataPath,
            `${newFileName}.json`,
        );

        if (!(await fs.exists(oldFilePath))) continue;

        await fs.rename(oldFilePath, newFilePath);
        await fs.rename(oldFileMetadataPath, newFileMetadataPath);
    }
}

async function removeDeprecatedExportRecordProperties(
    exportRecord: ExportRecordV1,
    exportDir: string,
) {
    if (exportRecord?.queuedFiles) {
        // @ts-ignore
        exportRecord.queuedFiles = undefined;
    }
    if (exportRecord?.progress) {
        // @ts-ignore
        exportRecord.progress = undefined;
    }
    if (exportRecord?.failedFiles) {
        // @ts-ignore
        exportRecord.failedFiles = undefined;
    }
    await exportService.updateExportRecord(exportDir, exportRecord);
}

async function getCollectionExportNamesFromExportedCollectionPaths(
    exportRecord: ExportRecordV2,
): Promise<CollectionExportNames> {
    if (!exportRecord.exportedCollectionPaths) {
        // @ts-ignore
        return;
    }
    const exportedCollectionNames = Object.fromEntries(
        Object.entries(exportRecord.exportedCollectionPaths).map(
            ([key, exportedCollectionPath]) => {
                const exportedCollectionName = exportedCollectionPath
                    .split("/")
                    .pop();
                return [key, exportedCollectionName];
            },
        ),
    );
    // @ts-ignore
    return exportedCollectionNames;
}

/*
    Earlier the file were sorted by id,
    which we can use to determine which file got which number suffix
    this can be used to determine the filepaths of the those already exported files
    and update the exportedFilePaths property of the exportRecord
    This is based on the assumption new files have higher ids than the older ones
*/
async function getFileExportNamesFromExportedFiles(
    exportRecord: ExportRecordV2,
    exportedFiles: EnteFile[],
    updateProgress: (progress: ExportProgress) => void,
): Promise<FileExportNames> {
    if (!exportedFiles.length) {
        // @ts-ignore
        return;
    }
    log.info(
        `updating exported files to exported file paths property, got ${exportedFiles.length} files`,
    );
    let exportedFileNames: FileExportNames;
    const usedFilePaths = new Map<string, Set<string>>();
    const exportedCollectionPaths = convertCollectionIDFolderPathObjectToMap(
        exportRecord.exportedCollectionPaths,
    );
    let success = 0;
    for (const file of exportedFiles) {
        await wait(0);
        const collectionPath = exportedCollectionPaths.get(file.collectionID);
        log.debug(
            () =>
                `collection path for ${file.collectionID} is ${collectionPath}`,
        );
        const fileName = fileFileName(file);
        let fileExportName: string;
        /*
            For Live Photos we need to download the file to get the image and video name
        */
        if (file.metadata.fileType == FileType.livePhoto) {
            const fileBlob = await downloadManager.fileBlob(file);
            const { imageFileName, videoFileName } = await decodeLivePhoto(
                fileName,
                fileBlob,
            );
            const imageExportName = getUniqueFileExportNameForMigration(
                // @ts-ignore
                collectionPath,
                imageFileName,
                usedFilePaths,
            );
            const videoExportName = getUniqueFileExportNameForMigration(
                // @ts-ignore
                collectionPath,
                videoFileName,
                usedFilePaths,
            );
            fileExportName = getLivePhotoExportName(
                imageExportName,
                videoExportName,
            );
        } else {
            fileExportName = getUniqueFileExportNameForMigration(
                // @ts-ignore
                collectionPath,
                fileName,
                usedFilePaths,
            );
        }
        log.debug(
            () => `file export name for ${fileName} is ${fileExportName}`,
        );
        exportedFileNames = {
            // @ts-ignore
            ...exportedFileNames,
            [getExportRecordFileUID(file)]: fileExportName,
        };
        updateProgress({
            total: exportedFiles.length,
            success: success++,
            failed: 0,
        });
    }
    // @ts-ignore
    return exportedFileNames;
}

function reMigrateCollectionExportNames(
    exportRecord: ExportRecord,
): CollectionExportNames {
    const exportedCollectionNames = Object.fromEntries(
        Object.entries(exportRecord.collectionExportNames).map(
            ([key, exportedCollectionPath]) => {
                const exportedCollectionName = exportedCollectionPath
                    .split("/")
                    .pop();
                return [key, exportedCollectionName];
            },
        ),
    );
    // @ts-ignore
    return exportedCollectionNames;
}

async function addCollectionExportedRecordV1(
    folder: string,
    collectionID: number,
    collectionExportPath: string,
) {
    try {
        const exportRecord = (await exportService.getExportRecord(
            folder,
        )) as unknown as ExportRecordV1;
        if (!exportRecord?.exportedCollectionPaths) {
            exportRecord.exportedCollectionPaths = {};
        }
        exportRecord.exportedCollectionPaths = {
            ...exportRecord.exportedCollectionPaths,
            [collectionID]: collectionExportPath,
        };

        await exportService.updateExportRecord(folder, exportRecord);
    } catch (e) {
        log.error("addCollectionExportedRecord failed", e);
        throw e;
    }
}

async function removeCollectionExportMissingMetadataFolder(
    exportDir: string,
    exportRecord: ExportRecord,
) {
    const fs = ensureElectron().fs;
    if (!exportRecord?.collectionExportNames) {
        return;
    }

    const properlyExportedCollectionsAll = Object.entries(
        exportRecord.collectionExportNames,
    );
    const properlyExportedCollections = [];
    for (const [
        collectionID,
        collectionExportName,
    ] of properlyExportedCollectionsAll) {
        if (
            await fs.exists(
                getMetadataFolderExportPath(
                    joinPath(exportDir, collectionExportName),
                ),
            )
        ) {
            properlyExportedCollections.push([
                collectionID,
                collectionExportName,
            ]);
        }
    }

    const properlyExportedCollectionIDs = properlyExportedCollections.map(
        ([collectionID]) => collectionID,
    );

    const properlyExportedFiles = Object.entries(
        exportRecord.fileExportNames,
    ).filter(([fileUID]) =>
        properlyExportedCollectionIDs.includes(
            getCollectionIDFromFileUID(fileUID).toString(),
        ),
    );

    const updatedExportRecord: ExportRecord = {
        ...exportRecord,
        collectionExportNames: Object.fromEntries(
            properlyExportedCollections,
        ) as CollectionExportNames,
        fileExportNames: Object.fromEntries(
            properlyExportedFiles,
        ) as FileExportNames,
    };
    await exportService.updateExportRecord(exportDir, updatedExportRecord);
}

const convertCollectionIDFolderPathObjectToMap = (
    exportedCollectionPaths: ExportedCollectionPaths,
): Map<number, string> => {
    return new Map<number, string>(
        Object.entries(exportedCollectionPaths ?? {}).map((e) => {
            return [Number(e[0]), String(e[1])];
        }),
    );
};

const getExportedFiles = (
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

const oldSanitizeName = (name: string) =>
    name.replaceAll("/", "_").replaceAll(" ", "_");

const getFileSavePath = (collectionFolderPath: string, fileSaveName: string) =>
    joinPath(collectionFolderPath, fileSaveName);

const getUniqueFileExportNameForMigration = (
    collectionPath: string,
    filename: string,
    usedFilePaths: Map<string, Set<string>>,
) => {
    let fileExportName = sanitizeFilename(filename);
    let count = 1;
    while (
        usedFilePaths
            .get(collectionPath)
            ?.has(getFileSavePath(collectionPath, fileExportName))
    ) {
        const filenameParts = nameAndExtension(sanitizeFilename(filename));
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
    // @ts-ignore
    usedFilePaths
        .get(collectionPath)
        .add(getFileSavePath(collectionPath, fileExportName));
    return fileExportName;
};
