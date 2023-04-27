import { getLocalCollections } from 'services/collectionService';
import { getLocalFiles } from 'services/fileService';
import {
    ExportRecordV1,
    ExportRecordV2,
    ExportRecord,
    FileExportNames,
} from 'types/export';
import { EnteFile } from 'types/file';
import { User } from 'types/user';
import { getNonEmptyPersonalCollections } from 'utils/collection';
import {
    getExportedFiles,
    getUniqueFileExportNameForMigration,
    getExportRecordFileUID,
    getFileExportPath,
    convertCollectionIDFolderPathObjectToMap,
} from 'utils/export';
import { getIDBasedSortedFiles, getPersonalFiles } from 'utils/file';
import { addLocalLog, addLogLine } from 'utils/logging';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import exportService from './index';

type UpdatedExportRecord = (
    exportRecord: Partial<ExportRecord>
) => Promise<ExportRecord>;

/*
    this function migrates the exportRecord file to apply any schema changes.
    currently we apply only a single migration to update file and collection name to newer format
    so there is just a if condition check, 
    later this will be converted to a loop which applies the migration one by one 
    till the files reaches the latest version 
    */
export async function migrateExport(
    exportDir: string,
    exportRecord: ExportRecordV1 | ExportRecordV2 | ExportRecord,
    updateExportRecord: UpdatedExportRecord
) {
    try {
        if (!exportRecord) {
            exportRecord = {
                version: 0,
            };
        }
        addLogLine(`current export version: ${exportRecord.version}`);
        if (exportRecord.version === 0) {
            addLogLine('migrating export to version 1');
            await migrationV0ToV1(exportDir, exportRecord);
            exportRecord = await updateExportRecord({ version: 1 });
            addLogLine('migration to version 1 complete');
        }
        if (exportRecord.version === 1) {
            addLogLine('migrating export to version 2');
            await migrationV1ToV2(exportRecord, updateExportRecord);
            exportRecord = await updateExportRecord({ version: 2 });
            addLogLine('migration to version 2 complete');
        }
        if (exportRecord.version === 2) {
            addLogLine('migrating export to version 3');
            await migrationV2ToV3(
                exportDir,
                exportRecord as ExportRecordV2,
                updateExportRecord
            );
            exportRecord = await updateExportRecord({
                version: 3,
            });
            addLogLine('migration to version 3 complete');
        }
    } catch (e) {
        logError(e, 'export record migration failed');
    }
}

async function migrationV0ToV1(
    exportDir: string,
    exportRecord: ExportRecord | ExportRecordV1 | ExportRecordV2
) {
    const collectionIDPathMap = new Map<number, string>();
    const user: User = getData(LS_KEYS.USER);
    const localFiles = await getLocalFiles();
    const localCollections = await getLocalCollections();
    const personalFiles = getIDBasedSortedFiles(
        getPersonalFiles(localFiles, user)
    );
    const nonEmptyPersonalCollections = getNonEmptyPersonalCollections(
        localCollections,
        personalFiles,
        user
    );
    await exportService.migrateCollectionExports(
        nonEmptyPersonalCollections,
        exportDir,
        collectionIDPathMap
    );
    await exportService.migrateFiles(
        exportDir,
        getExportedFiles(personalFiles, exportRecord),
        collectionIDPathMap
    );
}

async function migrationV1ToV2(
    exportRecord: ExportRecordV1,
    updateExportRecord: UpdatedExportRecord
) {
    await removeDeprecatedExportRecordProperties(
        exportRecord,
        updateExportRecord
    );
}

async function migrationV2ToV3(
    exportDir: string,
    exportRecord: ExportRecordV2,
    updateExportRecord: UpdatedExportRecord
) {
    addLocalLog(() => `migrationV2ToV3: ${JSON.stringify(exportRecord)}`);
    await extractExportDirPathPrefix(
        exportDir,
        exportRecord,
        updateExportRecord
    );
    addLocalLog(() => `migrationV2ToV3: ${JSON.stringify(exportRecord)}`);
    const user: User = getData(LS_KEYS.USER);
    const localFiles = await getLocalFiles();
    const personalFiles = getIDBasedSortedFiles(
        getPersonalFiles(localFiles, user)
    );
    addLogLine(`personal files count: ${personalFiles.length}`);
    // earlier the file were sorted by id,
    // which we can use to determine which file got which number suffix
    // this can be used to determine the filepaths of the those already exported files
    // and update the exportedFilePaths property of the exportRecord
    // This is based on the assumption new files have higher ids than the older ones
    await updateExportedFilesToExportedFilePathsProperty(
        exportRecord,
        updateExportRecord,
        getExportedFiles(personalFiles, exportRecord)
    );
}

export async function removeDeprecatedExportRecordProperties(
    exportRecord: ExportRecordV1,
    updateExportRecord: (exportRecord: ExportRecordV1) => Promise<ExportRecord>
) {
    if (exportRecord?.queuedFiles) {
        exportRecord.queuedFiles = undefined;
    }
    if (exportRecord?.progress) {
        exportRecord.progress = undefined;
    }
    if (exportRecord?.failedFiles) {
        exportRecord.failedFiles = undefined;
    }
    await updateExportRecord(exportRecord);
}

async function extractExportDirPathPrefix(
    exportDir: string,
    exportRecord: ExportRecordV2,
    updateExportRecord: UpdatedExportRecord
) {
    const exportedCollectionNames = Object.fromEntries(
        Object.entries(exportRecord.exportedCollectionPaths ?? {}).map(
            ([key, value]) => [key, value.replace(exportDir, '').slice(1)]
        )
    );
    exportRecord.exportedCollectionPaths = undefined;

    const updatedExportRecord: Partial<ExportRecord> = {
        ...exportRecord,
        collectionExportNames: exportedCollectionNames,
        exportFolderPath: exportDir,
    };
    return await updateExportRecord(updatedExportRecord);
}

export async function updateExportedFilesToExportedFilePathsProperty(
    exportRecord: ExportRecordV2,
    updateExportRecord: UpdatedExportRecord,
    exportedFiles: EnteFile[]
) {
    addLocalLog(() => `${JSON.stringify(exportRecord)}}`);
    addLogLine(
        'updating exported files to exported file paths property',
        `got ${exportedFiles.length} files`
    );
    let exportedFileNames: FileExportNames;
    const usedFilePaths = new Map<string, Set<string>>();
    const exportedCollectionPaths = convertCollectionIDFolderPathObjectToMap(
        exportRecord.exportedCollectionPaths
    );
    for (const file of exportedFiles) {
        const collectionPath = exportedCollectionPaths.get(file.collectionID);
        addLocalLog(
            () =>
                `collection path for ${file.collectionID} is ${collectionPath}`
        );
        const fileExportName = getUniqueFileExportNameForMigration(
            collectionPath,
            file.metadata.title,
            usedFilePaths
        );
        addLocalLog(
            () =>
                `file export path for ${
                    file.metadata.title
                } is ${getFileExportPath(collectionPath, fileExportName)}`
        );
        exportedFileNames = {
            ...exportedFileNames,
            [getExportRecordFileUID(file)]: fileExportName,
        };
    }
    exportRecord.exportedFiles = undefined;
    const updatedExportRecord: Partial<ExportRecord> = {
        ...exportRecord,
        fileExportNames: exportedFileNames,
    };

    await updateExportRecord(updatedExportRecord);
}
