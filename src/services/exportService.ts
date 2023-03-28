import { runningInBrowser } from 'utils/common';
import {
    getUnExportedFiles,
    dedupe,
    getGoogleLikeMetadataFile,
    getExportRecordFileUID,
    getUniqueCollectionFolderPath,
    getUniqueFileSaveName,
    getOldFileSavePath,
    getOldCollectionFolderPath,
    getFileMetadataSavePath,
    getFileSavePath,
    getOldFileMetadataSavePath,
    getExportedFiles,
    getMetadataFolderPath,
    getCollectionsRenamedAfterLastExport,
    getCollectionIDPathMapFromExportRecord,
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
    CollectionIDNameMap,
    CollectionIDPathMap,
    ExportProgress,
    ExportRecord,
    ExportRecordV1,
} from 'types/export';
import { User } from 'types/user';
import { FILE_TYPE, TYPE_JPEG, TYPE_JPG } from 'constants/file';
import { RecordType } from 'constants/export';
import { ElectronAPIs } from 'types/electron';
import { CustomError } from 'utils/error';
import { addLogLine } from 'utils/logging';
import { t } from 'i18next';
import { eventBus, Events } from './events';
import { getCollectionNameMap } from 'utils/collection';

const EXPORT_RECORD_FILE_NAME = 'export_status.json';

export const ENTE_EXPORT_DIRECTORY = 'ente Photos';

class ExportService {
    private electronAPIs: ElectronAPIs;
    private exportInProgress: Promise<void> = null;
    private exportRecordUpdater = new QueueProcessor<void>(1);
    private stopExport: boolean = false;
    private allElectronAPIsExist: boolean = false;
    private fileReader: FileReader = null;
    private continuousExportEventHandler: () => void;

    constructor() {
        this.electronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.electronAPIs?.exists;
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

    enableContinuousExport(startExport: () => Promise<void>) {
        try {
            if (this.continuousExportEventHandler) {
                addLogLine('continuous export already enabled');
                return;
            }
            const reRunNeeded = { current: false };
            this.continuousExportEventHandler = async () => {
                try {
                    addLogLine('continuous export triggered');
                    if (this.exportInProgress) {
                        addLogLine('export in progress, scheduling re-run');
                        reRunNeeded.current = true;
                        return;
                    }
                    await startExport();
                    if (reRunNeeded.current) {
                        reRunNeeded.current = false;
                        addLogLine('re-running export');
                        setTimeout(this.continuousExportEventHandler, 0);
                    }
                } catch (e) {
                    logError(e, 'continuous export failed');
                }
            };
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

    getUpdatedTotalAndPendingFileCount = async () => {
        try {
            const exportRecord = await this.getExportRecord();
            const userPersonalFiles = await getPersonalFiles();
            const unExportedFiles = getUnExportedFiles(
                userPersonalFiles,
                exportRecord
            );
            return {
                totalFiles: userPersonalFiles,
                pendingFiles: unExportedFiles,
            };
        } catch (e) {
            logError(e, 'getUpdateFileLists failed');
            throw e;
        }
    };

    stopRunningExport() {
        this.stopExport = true;
    }

    async exportFiles(updateProgress: (progress: ExportProgress) => void) {
        try {
            // eslint-disable-next-line @typescript-eslint/no-misused-promises
            if (this.exportInProgress) {
                this.electronAPIs.sendNotification(
                    t('EXPORT_NOTIFICATION.IN_PROGRESS')
                );
                return await this.exportInProgress;
            }
            const exportDir = getData(LS_KEYS.EXPORT)?.folder;
            if (!exportDir) {
                // no-export folder set
                return;
            }
            const user: User = getData(LS_KEYS.USER);

            const localFiles = await getLocalFiles();
            const userPersonalFiles = localFiles
                .filter((file) => file.ownerID === user?.id)
                .sort((fileA, fileB) => fileA.id - fileB.id);

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
            if (this.checkAllElectronAPIsExists()) {
                await this.migrateExport(
                    exportDir,
                    collections,
                    userPersonalFiles
                );
            }
            const exportRecord = await this.getExportRecord(exportDir);

            const filesToExport = getUnExportedFiles(
                userPersonalFiles,
                exportRecord
            );

            addLogLine(
                `starting export, filesToExportCount: ${filesToExport?.length}, userPersonalFileCount: ${userPersonalFiles?.length}`
            );

            const collectionIDPathMap: CollectionIDPathMap =
                getCollectionIDPathMapFromExportRecord(exportRecord);
            const collectionIDNameMap = getCollectionNameMap(collections);
            const renamedCollections = getCollectionsRenamedAfterLastExport(
                userCollections,
                exportRecord
            );
            this.exportInProgress = this.fileExporter(
                filesToExport,
                collectionIDNameMap,
                renamedCollections,
                collectionIDPathMap,
                updateProgress,
                exportDir
            );
            const resp = await this.exportInProgress;
            return resp;
        } catch (e) {
            logError(e, 'exportFiles failed');
            return { paused: false };
        } finally {
            this.exportInProgress = null;
        }
    }

    async fileExporter(
        files: EnteFile[],
        collectionIDNameMap: CollectionIDNameMap,
        renamedCollections: Collection[],
        collectionIDPathMap: CollectionIDPathMap,
        updateProgress: (progress: ExportProgress) => void,
        exportDir: string
    ): Promise<void> {
        try {
            if (
                renamedCollections?.length &&
                this.checkAllElectronAPIsExists()
            ) {
                await this.renameCollectionFolders(
                    renamedCollections,
                    exportDir,
                    collectionIDPathMap
                );
            }
            if (!files?.length) {
                this.electronAPIs.sendNotification(
                    t('EXPORT_NOTIFICATION.UP_TO_DATE')
                );
                return;
            }
            this.stopExport = false;
            this.electronAPIs.sendNotification(t('EXPORT_NOTIFICATION.START'));

            for (const [index, file] of files.entries()) {
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
                    await this.downloadAndSave(file, collectionPath);
                    await this.addFileExportedRecord(
                        exportDir,
                        file,
                        RecordType.SUCCESS
                    );
                    updateProgress({ current: index + 1, total: files.length });
                } catch (e) {
                    logError(e, 'export failed for a file');
                    if (
                        e.message ===
                        CustomError.ADD_FILE_EXPORTED_RECORD_FAILED
                    ) {
                        throw e;
                    }
                    await this.addFileExportedRecord(
                        exportDir,
                        file,
                        RecordType.FAILED
                    );
                }
            }
            if (!this.stopExport) {
                this.electronAPIs.sendNotification(
                    t('EXPORT_NOTIFICATION.FINISH')
                );
            }
        } catch (e) {
            logError(e, 'fileExporter failed');
            throw e;
        }
    }

    async addFileExportedRecord(
        folder: string,
        file: EnteFile,
        type: RecordType
    ) {
        try {
            const fileUID = getExportRecordFileUID(file);
            const exportRecord = await this.getExportRecord(folder);
            if (type === RecordType.SUCCESS) {
                if (!exportRecord.exportedFiles) {
                    exportRecord.exportedFiles = [];
                }
                exportRecord.exportedFiles.push(fileUID);
                exportRecord.failedFiles &&
                    (exportRecord.failedFiles = exportRecord.failedFiles.filter(
                        (FailedFileUID) => FailedFileUID !== fileUID
                    ));
            } else {
                if (!exportRecord.failedFiles) {
                    exportRecord.failedFiles = [];
                }
                if (!exportRecord.failedFiles.find((x) => x === fileUID)) {
                    exportRecord.failedFiles.push(fileUID);
                }
            }
            exportRecord.exportedFiles = dedupe(exportRecord.exportedFiles);
            exportRecord.failedFiles = dedupe(exportRecord.failedFiles);
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
        const exportRecord = await this.getExportRecord(folder);
        if (!exportRecord?.exportedCollectionPaths) {
            exportRecord.exportedCollectionPaths = {};
        }
        exportRecord.exportedCollectionPaths = {
            ...exportRecord.exportedCollectionPaths,
            [collectionID]: collectionFolderPath,
        };

        await this.updateExportRecord(exportRecord, folder);
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
                throw Error(CustomError.NO_EXPORT_FOLDER_SELECTED);
            }
            const exportFolderExists = this.exists(folder);
            if (!exportFolderExists) {
                throw Error(CustomError.EXPORT_FOLDER_DOES_NOT_EXIST);
            }
            const recordFile = await this.electronAPIs.getExportRecord(
                `${folder}/${EXPORT_RECORD_FILE_NAME}`
            );
            if (recordFile) {
                return JSON.parse(recordFile);
            } else {
                return {} as ExportRecord;
            }
        } catch (e) {
            logError(e, 'export Record JSON parsing failed ');
            throw e;
        }
    }

    async createNewCollectionFolder(
        exportFolder: string,
        collectionID: number,
        collectionIDNameMap: CollectionIDNameMap,
        collectionIDPathMap: CollectionIDPathMap
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
        collectionIDPathMap: CollectionIDPathMap
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

    async downloadAndSave(file: EnteFile, collectionPath: string) {
        try {
            file.metadata = mergeMetadata([file])[0].metadata;
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
                await this.exportMotionPhoto(fileStream, file, collectionPath);
            } else {
                await this.saveMediaFile(
                    collectionPath,
                    fileSaveName,
                    fileStream
                );
                await this.saveMetadataFile(collectionPath, fileSaveName, file);
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
        return this.exportInProgress !== null;
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
    private async migrateExport(
        exportDir: string,
        collections: Collection[],
        files: EnteFile[]
    ) {
        const exportRecord = await this.getExportRecord(exportDir);
        let currentVersion = exportRecord?.version ?? 0;
        if (currentVersion === 0) {
            const collectionIDPathMap = new Map<number, string>();

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
    }

    /*
    This updates the folder name of already exported folders from the earlier format of 
    `collectionID_collectionName` to newer `collectionName(numbered)` format
    */
    private async migrateCollectionFolders(
        collections: Collection[],
        exportDir: string,
        collectionIDPathMap: CollectionIDPathMap
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
        await this.updateExportRecord(exportRecord);
    }
}
export default new ExportService();
