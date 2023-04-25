import { runningInBrowser } from 'utils/common';
import {
    getUnExportedFiles,
    getGoogleLikeMetadataFile,
    getExportRecordFileUID,
    getUniqueCollectionFolderPath,
    getUniqueFileSaveName,
    getUniqueFileSaveNameForMigration,
    getOldFileSavePath,
    getOldCollectionFolderPath,
    getFileMetadataSavePath,
    getFileSavePath,
    getOldFileMetadataSavePath,
    getExportedFiles,
    getMetadataFolderPath,
    getRenamedCollections,
    getDeletedExportedFiles,
    convertCollectionIDPathObjectToMap,
    convertFileIDPathObjectToMap,
    getDeletedExportedCollections,
    getTrashedFilePath,
    getMetadataFilePath,
} from 'utils/export';
import { retryAsyncFunction } from 'utils/network';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import {
    getLocalCollections,
    getNonEmptyCollections,
} from './collectionService';
import downloadManager from './downloadManager';
import { getLocalFiles } from './fileService';
import { EnteFile } from 'types/file';

import { decodeMotionPhoto } from './motionPhotoService';
import {
    generateStreamFromArrayBuffer,
    getFileExtension,
    getPersonalFiles,
    mergeMetadata,
} from 'utils/file';

import { updateFileCreationDateInEXIF } from './upload/exifService';
import QueueProcessor from './queueProcessor';
import { Collection } from 'types/collection';
import {
    ExportProgress,
    ExportRecord,
    ExportRecordV1,
    ExportRecordV2,
    ExportUIUpdaters,
    ExportedFilePaths,
    FileExportStats,
} from 'types/export';
import { User } from 'types/user';
import { FILE_TYPE, TYPE_JPEG, TYPE_JPG } from 'constants/file';
import { ExportStage } from 'constants/export';
import { ElectronAPIs } from 'types/electron';
import { CustomError } from 'utils/error';
import { addLocalLog, addLogLine } from 'utils/logging';
import { eventBus, Events } from './events';
import { getCollectionNameMap } from 'utils/collection';

const EXPORT_RECORD_FILE_NAME = 'export_status.json';

export const ENTE_EXPORT_DIRECTORY = 'ente Photos';

class ExportService {
    private electronAPIs: ElectronAPIs;
    private exportInProgress: boolean = false;
    private reRunNeeded = false;
    private exportRecordUpdater = new QueueProcessor<void>(1);
    private stopExport: boolean = false;
    private allElectronAPIsExist: boolean = false;
    private fileReader: FileReader = null;
    private continuousExportEventHandler: () => void;
    private uiUpdater: ExportUIUpdaters;
    private currentExportProgress: ExportProgress = {
        total: 0,
        success: 0,
        failed: 0,
    };

    constructor() {
        if (runningInBrowser()) {
            this.electronAPIs = window['ElectronAPIs'];
            this.allElectronAPIsExist = !!this.electronAPIs?.exists;
            this.fileReader = new FileReader();
            const exportDir = getData(LS_KEYS.EXPORT)?.folder;
            if (!exportDir) {
                return;
            }
            if (this.checkAllElectronAPIsExists()) {
                void this.migrateExport(exportDir);
            }
        }
    }

    async setUIUpdaters(uiUpdater: ExportUIUpdaters) {
        this.uiUpdater = uiUpdater;
        this.uiUpdater.updateExportProgress(this.currentExportProgress);
    }

    private updateExportProgress(exportProgress: ExportProgress) {
        this.currentExportProgress = exportProgress;
        this.uiUpdater.updateExportProgress(exportProgress);
    }

    async changeExportDirectory(callback: (newExportDir: string) => void) {
        try {
            const newRootDir = await this.electronAPIs.selectRootDirectory();
            if (!newRootDir) {
                return;
            }
            const newExportDir = `${newRootDir}/${ENTE_EXPORT_DIRECTORY}`;
            await this.electronAPIs.checkExistsAndCreateDir(newExportDir);
            callback(newExportDir);
        } catch (e) {
            logError(e, 'changeExportDirectory failed');
        }
    }

    async openExportDirectory(exportFolder: string) {
        try {
            await this.electronAPIs.openDirectory(exportFolder);
        } catch (e) {
            logError(e, 'openExportDirectory failed');
        }
    }

    enableContinuousExport() {
        try {
            if (this.continuousExportEventHandler) {
                addLogLine('continuous export already enabled');
                return;
            }
            this.continuousExportEventHandler = this.scheduleExport;
            this.continuousExportEventHandler();
            eventBus.addListener(
                Events.LOCAL_FILES_UPDATED,
                this.continuousExportEventHandler
            );
        } catch (e) {
            logError(e, 'failed to enableContinuousExport ');
            throw e;
        }
    }

    disableContinuousExport() {
        try {
            if (!this.continuousExportEventHandler) {
                addLogLine('continuous export already disabled');
                return;
            }
            eventBus.removeListener(
                Events.LOCAL_FILES_UPDATED,
                this.continuousExportEventHandler
            );
            this.continuousExportEventHandler = null;
        } catch (e) {
            logError(e, 'failed to disableContinuousExport');
            throw e;
        }
    }

    getFileExportStats = async (): Promise<FileExportStats> => {
        try {
            const exportRecord = await this.getExportRecord();
            const userPersonalFiles = await getPersonalFiles();
            const unExportedFiles = getUnExportedFiles(
                userPersonalFiles,
                exportRecord
            );
            return {
                totalCount: userPersonalFiles.length,
                pendingCount: unExportedFiles.length,
            };
        } catch (e) {
            logError(e, 'getUpdateFileLists failed');
            throw e;
        }
    };

    async preExport() {
        this.stopExport = false;
        this.exportInProgress = true;
        await this.uiUpdater.updateExportStage(ExportStage.INPROGRESS);
        this.updateExportProgress({
            success: 0,
            failed: 0,
            total: 0,
        });
    }

    async postExport() {
        await this.uiUpdater.updateExportStage(ExportStage.FINISHED);
        await this.uiUpdater.updateLastExportTime(Date.now());
        this.uiUpdater.updateFileExportStats(await this.getFileExportStats());
    }

    async stopRunningExport() {
        try {
            this.stopExport = true;
            this.reRunNeeded = false;
            await this.postExport();
        } catch (e) {
            logError(e, 'stopRunningExport failed');
        }
    }

    scheduleExport = async () => {
        try {
            if (this.exportInProgress) {
                addLogLine('export in progress, scheduling re-run');
                this.reRunNeeded = true;
                return;
            }
            try {
                await this.preExport();
                addLogLine('export started');
                await this.runExport();
                addLogLine('export completed');
            } finally {
                this.exportInProgress = false;
                if (this.reRunNeeded) {
                    this.reRunNeeded = false;
                    addLogLine('re-running export');
                    setTimeout(this.scheduleExport, 0);
                }
                await this.postExport();
            }
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'scheduleExport failed');
            }
        }
    };

    private async runExport() {
        try {
            const exportDir = getData(LS_KEYS.EXPORT)?.folder;
            if (!exportDir) {
                // no-export folder set
                return;
            }
            const user: User = getData(LS_KEYS.USER);

            const localFiles = await getLocalFiles();
            const userPersonalFiles = mergeMetadata(
                localFiles
                    .filter((file) => file.ownerID === user?.id)
                    .sort((fileA, fileB) => fileA.id - fileB.id)
            );

            const collections = await getLocalCollections();
            const nonEmptyCollections = getNonEmptyCollections(
                collections,
                userPersonalFiles
            );
            const userCollections = nonEmptyCollections
                .filter((collection) => collection.owner.id === user?.id)
                .sort(
                    (collectionA, collectionB) =>
                        collectionA.id - collectionB.id
                );
            const exportRecord = await this.getExportRecord(exportDir);

            const collectionIDPathMap = convertCollectionIDPathObjectToMap(
                exportRecord.exportedCollectionPaths
            );
            const collectionIDNameMap = getCollectionNameMap(collections);

            const removedFileUIDs = getDeletedExportedFiles(
                userPersonalFiles,
                exportRecord
            );

            if (removedFileUIDs?.length > 0) {
                addLogLine(`removing ${removedFileUIDs.length} files`);
                await this.fileRemover(removedFileUIDs, exportDir);
            }

            const renamedCollections = getRenamedCollections(
                userCollections,
                exportRecord
            );

            if (
                renamedCollections?.length > 0 &&
                this.checkAllElectronAPIsExists()
            ) {
                addLogLine(`renaming ${renamedCollections.length} collections`);
                this.collectionRenamer(
                    exportDir,
                    collectionIDPathMap,
                    renamedCollections
                );
            }

            const filesToExport = getUnExportedFiles(
                userPersonalFiles,
                exportRecord
            );

            if (filesToExport?.length > 0) {
                addLogLine(`exporting ${filesToExport.length} files`);
                await this.fileExporter(
                    filesToExport,
                    collectionIDNameMap,
                    collectionIDPathMap,
                    exportDir
                );
            }

            const deletedExportedCollections = getDeletedExportedCollections(
                userCollections,
                exportRecord
            );

            if (deletedExportedCollections?.length > 0) {
                addLogLine(
                    `removing ${deletedExportedCollections.length} collections`
                );
                await this.collectionRemover(
                    deletedExportedCollections,
                    exportDir
                );
            }
        } catch (e) {
            logError(e, 'runExport failed');
        }
    }

    async collectionRenamer(
        exportFolder: string,
        collectionIDPathMap: Map<number, string>,
        renamedCollections: Collection[]
    ) {
        for (const collection of renamedCollections) {
            addLocalLog(
                () =>
                    `renaming collection ${collection.name} with id ${collection.id}`
            );
            const oldCollectionFolderPath = collectionIDPathMap.get(
                collection.id
            );

            const newCollectionFolderPath = getUniqueCollectionFolderPath(
                exportFolder,
                collection.id,
                collection.name
            );
            await this.electronAPIs.checkExistsAndRename(
                oldCollectionFolderPath,
                newCollectionFolderPath
            );

            await this.addCollectionExportedRecord(
                exportFolder,
                collection.id,
                newCollectionFolderPath
            );
            collectionIDPathMap.set(collection.id, newCollectionFolderPath);
        }
    }

    async collectionRemover(
        deletedExportedCollectionIDs: number[],
        exportFolder: string
    ) {
        const exportRecord = await this.getExportRecord(exportFolder);
        const collectionIDPathMap = convertCollectionIDPathObjectToMap(
            exportRecord.exportedCollectionPaths
        );
        for (const collectionID of deletedExportedCollectionIDs) {
            addLocalLog(
                () =>
                    `removing collection with id ${collectionID} from export folder`
            );
            const collectionFolderPath = collectionIDPathMap.get(collectionID);
            await this.electronAPIs.deleteEmptyFolder(collectionFolderPath);
            await this.removeCollectionExportedRecord(
                exportFolder,
                collectionID
            );
        }
    }

    async fileExporter(
        files: EnteFile[],
        collectionIDNameMap: Map<number, string>,
        collectionIDPathMap: Map<number, string>,
        exportDir: string
    ): Promise<void> {
        try {
            let success = 0;
            let failed = 0;
            this.updateExportProgress({
                success,
                failed,
                total: files.length,
            });
            for (const file of files) {
                addLocalLog(
                    () =>
                        `exporting file ${file.metadata.title} with id ${
                            file.id
                        } from collection ${collectionIDNameMap.get(
                            file.collectionID
                        )}`
                );
                if (this.stopExport) {
                    break;
                }
                try {
                    let collectionPath = collectionIDPathMap.get(
                        file.collectionID
                    );
                    if (!collectionPath || !this.exists(collectionPath)) {
                        collectionPath = await this.createNewCollectionFolder(
                            exportDir,
                            file.collectionID,
                            collectionIDNameMap,
                            collectionIDPathMap
                        );
                    }
                    const fileSavePath = await this.downloadAndSave(
                        file,
                        collectionPath
                    );
                    await this.addFileExportedRecord(
                        exportDir,
                        file,
                        fileSavePath
                    );
                    success++;
                } catch (e) {
                    failed++;
                    logError(e, 'export failed for a file');
                    if (
                        e.message ===
                        CustomError.ADD_FILE_EXPORTED_RECORD_FAILED
                    ) {
                        throw e;
                    }
                }
                this.updateExportProgress({
                    success,
                    failed,
                    total: files.length,
                });
            }
        } catch (e) {
            logError(e, 'fileExporter failed');
            throw e;
        }
    }

    async fileRemover(
        removedFileUIDs: string[],
        exportDir: string
    ): Promise<void> {
        try {
            let success = 0;
            let failed = 0;
            this.updateExportProgress({
                success,
                failed,
                total: removedFileUIDs.length,
            });
            const exportRecord = await this.getExportRecord(exportDir);
            const fileIDPathMap = convertFileIDPathObjectToMap(
                exportRecord.exportedFilePaths
            );
            for (const fileUID of removedFileUIDs) {
                addLocalLog(() => `removing file with id ${fileUID}`);
                if (this.stopExport) {
                    break;
                }
                try {
                    const filePath = fileIDPathMap.get(fileUID);
                    await this.electronAPIs.moveFile(
                        filePath,
                        getTrashedFilePath(exportDir, filePath)
                    );
                    const metadataFilePath = getMetadataFilePath(filePath);
                    await this.electronAPIs.moveFile(
                        metadataFilePath,
                        getTrashedFilePath(exportDir, metadataFilePath)
                    );
                    await this.removeFileExportedRecord(exportDir, fileUID);
                    success++;
                } catch (e) {
                    failed++;
                    logError(e, 'remove failed for a file');
                    if (
                        e.message ===
                        CustomError.ADD_FILE_EXPORTED_RECORD_FAILED
                    ) {
                        throw e;
                    }
                }
                this.updateExportProgress({
                    success,
                    failed,
                    total: removedFileUIDs.length,
                });
            }
        } catch (e) {
            logError(e, 'fileRemover failed');
            throw e;
        }
    }

    async addFileExportedRecord(
        folder: string,
        file: EnteFile,
        fileSavePath: string
    ) {
        try {
            const fileUID = getExportRecordFileUID(file);
            const exportRecord = await this.getExportRecord(folder);
            if (!exportRecord.exportedFilePaths) {
                exportRecord.exportedFilePaths = {};
            }
            exportRecord.exportedFilePaths = {
                ...exportRecord.exportedFilePaths,
                [fileUID]: fileSavePath,
            };
            await this.updateExportRecord(exportRecord, folder);
        } catch (e) {
            logError(e, 'addFileExportedRecord failed');
            throw Error(CustomError.ADD_FILE_EXPORTED_RECORD_FAILED);
        }
    }

    async addCollectionExportedRecord(
        folder: string,
        collectionID: number,
        collectionFolderPath: string
    ) {
        try {
            const exportRecord = await this.getExportRecord(folder);
            if (!exportRecord?.exportedCollectionPaths) {
                exportRecord.exportedCollectionPaths = {};
            }
            exportRecord.exportedCollectionPaths = {
                ...exportRecord.exportedCollectionPaths,
                [collectionID]: collectionFolderPath,
            };

            await this.updateExportRecord(exportRecord, folder);
        } catch (e) {
            logError(e, 'addCollectionExportedRecord failed');
            throw Error(CustomError.ADD_FILE_EXPORTED_RECORD_FAILED);
        }
    }

    async removeCollectionExportedRecord(folder: string, collectionID: number) {
        try {
            const exportRecord = await this.getExportRecord(folder);

            exportRecord.exportedCollectionPaths = Object.fromEntries(
                Object.entries(exportRecord.exportedCollectionPaths).filter(
                    ([key]) => key !== collectionID.toString()
                )
            );

            await this.updateExportRecord(exportRecord, folder);
        } catch (e) {
            logError(e, 'removeCollectionExportedRecord failed');
            throw Error(CustomError.ADD_FILE_EXPORTED_RECORD_FAILED);
        }
    }

    async removeFileExportedRecord(folder: string, fileUID: string) {
        try {
            const exportRecord = await this.getExportRecord(folder);
            exportRecord.exportedFilePaths = Object.fromEntries(
                Object.entries(exportRecord.exportedFilePaths).filter(
                    ([key]) => key !== fileUID
                )
            );
            await this.updateExportRecord(exportRecord, folder);
        } catch (e) {
            logError(e, 'removeFileExportedRecord failed');
            throw Error(CustomError.ADD_FILE_EXPORTED_RECORD_FAILED);
        }
    }

    async updateExportRecord(newData: Partial<ExportRecord>, folder?: string) {
        const response = this.exportRecordUpdater.queueUpRequest(() =>
            this.updateExportRecordHelper(folder, newData)
        );
        await response.promise;
    }

    async updateExportRecordHelper(
        folder: string,
        newData: Partial<ExportRecord>
    ) {
        try {
            if (!folder) {
                folder = getData(LS_KEYS.EXPORT)?.folder;
            }
            const exportRecord = await this.getExportRecord(folder);
            const newRecord = { ...exportRecord, ...newData };
            await this.electronAPIs.setExportRecord(
                `${folder}/${EXPORT_RECORD_FILE_NAME}`,
                JSON.stringify(newRecord, null, 2)
            );
        } catch (e) {
            logError(e, 'error updating Export Record');
            throw e;
        }
    }

    async getExportRecord(folder?: string): Promise<ExportRecord> {
        try {
            if (!folder) {
                folder = getData(LS_KEYS.EXPORT)?.folder;
            }
            if (!folder) {
                return null;
            }
            const exportFolderExists = this.exists(folder);
            if (!exportFolderExists) {
                return null;
            }
            const recordFile = await this.electronAPIs.getExportRecord(
                `${folder}/${EXPORT_RECORD_FILE_NAME}`
            );
            return JSON.parse(recordFile);
        } catch (e) {
            logError(e, 'export Record JSON parsing failed ');
            throw e;
        }
    }

    async createNewCollectionFolder(
        exportFolder: string,
        collectionID: number,
        collectionIDNameMap: Map<number, string>,
        collectionIDPathMap: Map<number, string>
    ) {
        const collectionName = collectionIDNameMap.get(collectionID);
        const collectionFolderPath = getUniqueCollectionFolderPath(
            exportFolder,
            collectionID,
            collectionName
        );
        await this.electronAPIs.checkExistsAndCreateDir(collectionFolderPath);
        await this.electronAPIs.checkExistsAndCreateDir(
            getMetadataFolderPath(collectionFolderPath)
        );
        await this.addCollectionExportedRecord(
            exportFolder,
            collectionID,
            collectionFolderPath
        );
        collectionIDPathMap.set(collectionID, collectionFolderPath);
        return collectionFolderPath;
    }
    async renameCollectionFolders(
        renamedCollections: Collection[],
        exportFolder: string,
        collectionIDPathMap: Map<number, string>
    ) {
        for (const collection of renamedCollections) {
            const oldCollectionFolderPath = collectionIDPathMap.get(
                collection.id
            );

            const newCollectionFolderPath = getUniqueCollectionFolderPath(
                exportFolder,
                collection.id,
                collection.name
            );
            await this.electronAPIs.checkExistsAndRename(
                oldCollectionFolderPath,
                newCollectionFolderPath
            );

            await this.addCollectionExportedRecord(
                exportFolder,
                collection.id,
                newCollectionFolderPath
            );
            collectionIDPathMap.set(collection.id, newCollectionFolderPath);
        }
    }

    async downloadAndSave(
        file: EnteFile,
        collectionPath: string
    ): Promise<string> {
        try {
            const fileSaveName = getUniqueFileSaveName(
                collectionPath,
                file.metadata.title,
                file.id
            );
            let fileStream = await retryAsyncFunction(() =>
                downloadManager.downloadFile(file)
            );
            const fileType = getFileExtension(file.metadata.title);
            if (
                file.pubMagicMetadata?.data.editedTime &&
                (fileType === TYPE_JPEG || fileType === TYPE_JPG)
            ) {
                const fileBlob = await new Response(fileStream).blob();
                if (!this.fileReader) {
                    this.fileReader = new FileReader();
                }
                const updatedFileBlob = await updateFileCreationDateInEXIF(
                    this.fileReader,
                    fileBlob,
                    new Date(file.pubMagicMetadata.data.editedTime / 1000)
                );
                fileStream = updatedFileBlob.stream();
            }
            if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
                return await this.exportMotionPhoto(
                    fileStream,
                    file,
                    collectionPath
                );
            } else {
                await this.saveMediaFile(
                    collectionPath,
                    fileSaveName,
                    fileStream
                );
                await this.saveMetadataFile(collectionPath, fileSaveName, file);
                const fileSavePath = getFileSavePath(
                    collectionPath,
                    fileSaveName
                );
                return fileSavePath;
            }
        } catch (e) {
            logError(e, 'download and save failed');
            throw e;
        }
    }

    private async exportMotionPhoto(
        fileStream: ReadableStream<any>,
        file: EnteFile,
        collectionPath: string
    ) {
        const fileBlob = await new Response(fileStream).blob();
        const motionPhoto = await decodeMotionPhoto(file, fileBlob);
        const imageStream = generateStreamFromArrayBuffer(motionPhoto.image);
        const imageSaveName = getUniqueFileSaveName(
            collectionPath,
            motionPhoto.imageNameTitle,
            file.id
        );
        await this.saveMediaFile(collectionPath, imageSaveName, imageStream);
        await this.saveMetadataFile(collectionPath, imageSaveName, file);

        const videoStream = generateStreamFromArrayBuffer(motionPhoto.video);
        const videoSaveName = getUniqueFileSaveName(
            collectionPath,
            motionPhoto.videoNameTitle,
            file.id
        );
        await this.saveMediaFile(collectionPath, videoSaveName, videoStream);
        await this.saveMetadataFile(collectionPath, videoSaveName, file);

        const imageSavePath = getFileSavePath(collectionPath, imageSaveName);
        const videoSavePath = getFileSavePath(collectionPath, videoSaveName);

        return [imageSavePath, videoSavePath].join('-');
    }

    private async saveMediaFile(
        collectionFolderPath: string,
        fileSaveName: string,
        fileStream: ReadableStream<any>
    ) {
        await this.electronAPIs.saveStreamToDisk(
            getFileSavePath(collectionFolderPath, fileSaveName),
            fileStream
        );
    }
    private async saveMetadataFile(
        collectionFolderPath: string,
        fileSaveName: string,
        file: EnteFile
    ) {
        await this.electronAPIs.saveFileToDisk(
            getFileMetadataSavePath(collectionFolderPath, fileSaveName),
            getGoogleLikeMetadataFile(fileSaveName, file)
        );
    }

    isExportInProgress = () => {
        return this.exportInProgress;
    };

    exists = (path: string) => {
        return this.electronAPIs.exists(path);
    };

    checkAllElectronAPIsExists = () => this.allElectronAPIsExist;

    /*
    this function migrates the exportRecord file to apply any schema changes.
    currently we apply only a single migration to update file and collection name to newer format
    so there is just a if condition check, 
    later this will be converted to a loop which applies the migration one by one 
    till the files reaches the latest version 
    */
    private async migrateExport(exportDir: string) {
        try {
            const exportRecord = await this.getExportRecord(exportDir);
            let currentVersion = exportRecord?.version ?? 0;
            if (currentVersion === 0) {
                const collectionIDPathMap = new Map<number, string>();
                const user: User = getData(LS_KEYS.USER);

                const localFiles = await getLocalFiles();
                const files = localFiles
                    .filter((file) => file.ownerID === user?.id)
                    .sort((fileA, fileB) => fileA.id - fileB.id);

                const localCollections = await getLocalCollections();
                const nonEmptyCollections = getNonEmptyCollections(
                    localCollections,
                    files
                );
                const collections = nonEmptyCollections
                    .filter((collection) => collection.owner.id === user?.id)
                    .sort(
                        (collectionA, collectionB) =>
                            collectionA.id - collectionB.id
                    );
                await this.migrateCollectionFolders(
                    collections,
                    exportDir,
                    collectionIDPathMap
                );
                await this.migrateFiles(
                    getExportedFiles(files, exportRecord),
                    collectionIDPathMap
                );
                currentVersion++;
                await this.updateExportRecord({
                    version: currentVersion,
                });
            }
            if (currentVersion === 1) {
                await this.removeDeprecatedExportRecordProperties();
                currentVersion++;
                await this.updateExportRecord({
                    version: currentVersion,
                });
            }
            if (currentVersion === 2) {
                const user: User = getData(LS_KEYS.USER);

                const localFiles = await getLocalFiles();
                const files = localFiles
                    .filter((file) => file.ownerID === user?.id)
                    .sort((fileA, fileB) => fileA.id - fileB.id);

                await this.updateExportedFilesToExportedFilePathsProperty(
                    getExportedFiles(files, exportRecord)
                );
                currentVersion++;
                await this.updateExportRecord({
                    version: currentVersion,
                });
            }
        } catch (e) {
            logError(e, 'export record migration failed');
        }
    }

    /*
    This updates the folder name of already exported folders from the earlier format of 
    `collectionID_collectionName` to newer `collectionName(numbered)` format
    */
    private async migrateCollectionFolders(
        collections: Collection[],
        exportDir: string,
        collectionIDPathMap: Map<number, string>
    ) {
        for (const collection of collections) {
            const oldCollectionFolderPath = getOldCollectionFolderPath(
                exportDir,
                collection.id,
                collection.name
            );
            const newCollectionFolderPath = getUniqueCollectionFolderPath(
                exportDir,
                collection.id,
                collection.name
            );
            collectionIDPathMap.set(collection.id, newCollectionFolderPath);
            if (this.electronAPIs.exists(oldCollectionFolderPath)) {
                await this.electronAPIs.checkExistsAndRename(
                    oldCollectionFolderPath,
                    newCollectionFolderPath
                );
                await this.addCollectionExportedRecord(
                    exportDir,
                    collection.id,
                    newCollectionFolderPath
                );
            }
        }
    }

    /*
    This updates the file name of already exported files from the earlier format of 
    `fileID_fileName` to newer `fileName(numbered)` format
    */
    private async migrateFiles(
        files: EnteFile[],
        collectionIDPathMap: Map<number, string>
    ) {
        for (let file of files) {
            const oldFileSavePath = getOldFileSavePath(
                collectionIDPathMap.get(file.collectionID),
                file
            );
            const oldFileMetadataSavePath = getOldFileMetadataSavePath(
                collectionIDPathMap.get(file.collectionID),
                file
            );
            file = mergeMetadata([file])[0];
            const newFileSaveName = getUniqueFileSaveName(
                collectionIDPathMap.get(file.collectionID),
                file.metadata.title,
                file.id
            );

            const newFileSavePath = getFileSavePath(
                collectionIDPathMap.get(file.collectionID),
                newFileSaveName
            );

            const newFileMetadataSavePath = getFileMetadataSavePath(
                collectionIDPathMap.get(file.collectionID),
                newFileSaveName
            );
            await this.electronAPIs.checkExistsAndRename(
                oldFileSavePath,
                newFileSavePath
            );
            await this.electronAPIs.checkExistsAndRename(
                oldFileMetadataSavePath,
                newFileMetadataSavePath
            );
        }
    }

    private async removeDeprecatedExportRecordProperties() {
        const exportRecord = (await this.getExportRecord()) as ExportRecordV1;
        if (exportRecord?.queuedFiles) {
            exportRecord.queuedFiles = undefined;
        }
        if (exportRecord?.progress) {
            exportRecord.progress = undefined;
        }
        if (exportRecord?.failedFiles) {
            exportRecord.failedFiles = undefined;
        }
        await this.updateExportRecord(exportRecord);
    }

    private async updateExportedFilesToExportedFilePathsProperty(
        exportedFiles: EnteFile[]
    ) {
        const exportRecord =
            (await this.getExportRecord()) as unknown as ExportRecordV2;
        let exportedFilePaths: ExportedFilePaths;
        const usedFilePaths = new Set<string>();
        const exportedCollectionPaths = convertCollectionIDPathObjectToMap(
            exportRecord.exportedCollectionPaths
        );
        for (const file of exportedFiles) {
            const collectionPath = exportedCollectionPaths.get(
                file.collectionID
            );
            const fileSaveName = getUniqueFileSaveNameForMigration(
                collectionPath,
                file.metadata.title,
                usedFilePaths
            );
            const filePath = getFileSavePath(collectionPath, fileSaveName);
            exportedFilePaths = {
                ...exportedFilePaths,
                [getExportRecordFileUID(file)]: filePath,
            };
        }
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const { exportedFiles: _, ...rest } = exportRecord;
        const updatedExportRecord: ExportRecord = {
            ...rest,
            exportedFilePaths,
        };

        await this.updateExportRecord(updatedExportRecord);
    }
}
export default new ExportService();
