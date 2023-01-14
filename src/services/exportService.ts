import { runningInBrowser } from 'utils/common';
import {
    getExportQueuedFiles,
    getExportFailedFiles,
    getFilesUploadedAfterLastExport,
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
    getCollectionsCreatedAfterLastExport,
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
    mergeMetadata,
} from 'utils/file';

import { updateFileCreationDateInEXIF } from './upload/exifService';
import QueueProcessor from './queueProcessor';
import { Collection } from 'types/collection';
import {
    ExportProgress,
    CollectionIDPathMap,
    ExportRecord,
} from 'types/export';
import { User } from 'types/user';
import { FILE_TYPE, TYPE_JPEG, TYPE_JPG } from 'constants/file';
import { ExportType, ExportNotification, RecordType } from 'constants/export';
import { ElectronAPIs } from 'types/electron';

const LATEST_EXPORT_VERSION = 1;
const EXPORT_RECORD_FILE_NAME = 'export_status.json';

class ExportService {
    electronAPIs: ElectronAPIs;

    private exportInProgress: Promise<{ paused: boolean }> = null;
    private exportRecordUpdater = new QueueProcessor<void>(1);
    private stopExport: boolean = false;
    private pauseExport: boolean = false;
    private allElectronAPIsExist: boolean = false;
    private fileReader: FileReader = null;

    constructor() {
        this.electronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.electronAPIs?.exists;
    }
    async selectExportDirectory() {
        try {
            return await this.electronAPIs.selectRootDirectory();
        } catch (e) {
            logError(e, 'failed to selectExportDirectory ');
            throw e;
        }
    }

    stopRunningExport() {
        this.stopExport = true;
    }
    pauseRunningExport() {
        this.pauseExport = true;
    }
    async exportFiles(
        updateProgress: (progress: ExportProgress) => void,
        exportType: ExportType
    ) {
        try {
            if (this.exportInProgress) {
                this.electronAPIs.sendNotification(
                    ExportNotification.IN_PROGRESS
                );
                return await this.exportInProgress;
            }
            this.electronAPIs.showOnTray('starting export');
            const exportDir = getData(LS_KEYS.EXPORT)?.folder;
            if (!exportDir) {
                // no-export folder set
                return;
            }
            const user: User = getData(LS_KEYS.USER);

            let filesToExport: EnteFile[];
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

            if (exportType === ExportType.NEW) {
                filesToExport = getFilesUploadedAfterLastExport(
                    userPersonalFiles,
                    exportRecord
                );
            } else if (exportType === ExportType.RETRY_FAILED) {
                filesToExport = getExportFailedFiles(
                    userPersonalFiles,
                    exportRecord
                );
            } else {
                filesToExport = getExportQueuedFiles(
                    userPersonalFiles,
                    exportRecord
                );
            }
            const collectionIDPathMap: CollectionIDPathMap =
                getCollectionIDPathMapFromExportRecord(exportRecord);
            const newCollections = getCollectionsCreatedAfterLastExport(
                userCollections,
                exportRecord
            );

            const renamedCollections = getCollectionsRenamedAfterLastExport(
                userCollections,
                exportRecord
            );
            this.exportInProgress = this.fileExporter(
                filesToExport,
                newCollections,
                renamedCollections,
                collectionIDPathMap,
                updateProgress,
                exportDir
            );
            const resp = await this.exportInProgress;
            this.exportInProgress = null;
            return resp;
        } catch (e) {
            logError(e, 'exportFiles failed');
            return { paused: false };
        }
    }

    async fileExporter(
        files: EnteFile[],
        newCollections: Collection[],
        renamedCollections: Collection[],
        collectionIDPathMap: CollectionIDPathMap,
        updateProgress: (progress: ExportProgress) => void,
        exportDir: string
    ): Promise<{ paused: boolean }> {
        try {
            if (newCollections?.length) {
                await this.createNewCollectionFolders(
                    newCollections,
                    exportDir,
                    collectionIDPathMap
                );
            }
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
                    ExportNotification.UP_TO_DATE
                );
                return { paused: false };
            }
            this.stopExport = false;
            this.pauseExport = false;
            this.addFilesQueuedRecord(exportDir, files);
            const failedFileCount = 0;

            this.electronAPIs.showOnTray({
                export_progress: `0 / ${files.length} files exported`,
            });
            updateProgress({
                current: 0,
                total: files.length,
            });
            this.electronAPIs.sendNotification(ExportNotification.START);

            for (const [index, file] of files.entries()) {
                if (this.stopExport || this.pauseExport) {
                    if (this.pauseExport) {
                        this.electronAPIs.showOnTray({
                            export_progress: `${index} / ${files.length} files exported (paused)`,
                            paused: true,
                        });
                    }
                    break;
                }
                const collectionPath = collectionIDPathMap.get(
                    file.collectionID
                );
                try {
                    await this.downloadAndSave(file, collectionPath);
                    await this.addFileExportedRecord(
                        exportDir,
                        file,
                        RecordType.SUCCESS
                    );
                } catch (e) {
                    await this.addFileExportedRecord(
                        exportDir,
                        file,
                        RecordType.FAILED
                    );

                    logError(
                        e,
                        'download and save failed for file during export'
                    );
                }
                this.electronAPIs.showOnTray({
                    export_progress: `${index + 1} / ${
                        files.length
                    } files exported`,
                });
                updateProgress({ current: index + 1, total: files.length });
            }
            if (this.stopExport) {
                this.electronAPIs.sendNotification(ExportNotification.ABORT);
                this.electronAPIs.showOnTray();
            } else if (this.pauseExport) {
                this.electronAPIs.sendNotification(ExportNotification.PAUSE);
                return { paused: true };
            } else if (failedFileCount > 0) {
                this.electronAPIs.sendNotification(ExportNotification.FAILED);
                this.electronAPIs.showOnTray({
                    retry_export: `export failed - retry export`,
                });
            } else {
                this.electronAPIs.sendNotification(ExportNotification.FINISH);
                this.electronAPIs.showOnTray();
            }
            return { paused: false };
        } catch (e) {
            logError(e, 'fileExporter failed');
            throw e;
        }
    }
    async addFilesQueuedRecord(folder: string, files: EnteFile[]) {
        const exportRecord = await this.getExportRecord(folder);
        exportRecord.queuedFiles = files.map(getExportRecordFileUID);
        await this.updateExportRecord(exportRecord, folder);
    }

    async addFileExportedRecord(
        folder: string,
        file: EnteFile,
        type: RecordType
    ) {
        const fileUID = getExportRecordFileUID(file);
        const exportRecord = await this.getExportRecord(folder);
        exportRecord.queuedFiles = exportRecord.queuedFiles.filter(
            (queuedFilesUID) => queuedFilesUID !== fileUID
        );
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
        exportRecord.queuedFiles = dedupe(exportRecord.queuedFiles);
        exportRecord.failedFiles = dedupe(exportRecord.failedFiles);
        await this.updateExportRecord(exportRecord, folder);
    }

    async addCollectionExportedRecord(
        folder: string,
        collection: Collection,
        collectionFolderPath: string
    ) {
        const exportRecord = await this.getExportRecord(folder);
        if (!exportRecord?.exportedCollectionPaths) {
            exportRecord.exportedCollectionPaths = {};
        }
        exportRecord.exportedCollectionPaths = {
            ...exportRecord.exportedCollectionPaths,
            [collection.id]: collectionFolderPath,
        };

        await this.updateExportRecord(exportRecord, folder);
    }

    async updateExportRecord(newData: ExportRecord, folder?: string) {
        const response = this.exportRecordUpdater.queueUpRequest(() =>
            this.updateExportRecordHelper(folder, newData)
        );
        await response.promise;
    }
    async updateExportRecordHelper(folder: string, newData: ExportRecord) {
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
        }
    }

    async getExportRecord(folder?: string): Promise<ExportRecord> {
        try {
            if (!folder) {
                folder = getData(LS_KEYS.EXPORT)?.folder;
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
        }
    }

    async createNewCollectionFolders(
        newCollections: Collection[],
        exportFolder: string,
        collectionIDPathMap: CollectionIDPathMap
    ) {
        for (const collection of newCollections) {
            const collectionFolderPath = getUniqueCollectionFolderPath(
                exportFolder,
                collection
            );
            await this.electronAPIs.checkExistsAndCreateCollectionDir(
                collectionFolderPath
            );
            await this.electronAPIs.checkExistsAndCreateCollectionDir(
                getMetadataFolderPath(collectionFolderPath)
            );
            await this.addCollectionExportedRecord(
                exportFolder,
                collection,
                collectionFolderPath
            );
            collectionIDPathMap.set(collection.id, collectionFolderPath);
        }
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
                collection
            );
            await this.electronAPIs.checkExistsAndRename(
                oldCollectionFolderPath,
                newCollectionFolderPath
            );

            await this.addCollectionExportedRecord(
                exportFolder,
                collection,
                newCollectionFolderPath
            );
            collectionIDPathMap.set(collection.id, newCollectionFolderPath);
        }
    }

    async downloadAndSave(file: EnteFile, collectionPath: string) {
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
            this.saveMediaFile(collectionPath, fileSaveName, fileStream);
            await this.saveMetadataFile(collectionPath, fileSaveName, file);
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
        this.saveMediaFile(collectionPath, imageSaveName, imageStream);
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
        allFiles: EnteFile[]
    ) {
        const exportRecord = await this.getExportRecord(exportDir);
        const currentVersion = exportRecord?.version ?? 0;
        if (currentVersion === 0) {
            const collectionIDPathMap = new Map<number, string>();

            await this.migrateCollectionFolders(
                collections,
                exportDir,
                collectionIDPathMap
            );
            await this.migrateFiles(
                getExportedFiles(allFiles, exportRecord),
                collectionIDPathMap
            );

            await this.updateExportRecord({
                version: LATEST_EXPORT_VERSION,
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
                collection
            );
            const newCollectionFolderPath = getUniqueCollectionFolderPath(
                exportDir,
                collection
            );
            collectionIDPathMap.set(collection.id, newCollectionFolderPath);
            if (this.electronAPIs.exists(oldCollectionFolderPath)) {
                await this.electronAPIs.checkExistsAndRename(
                    oldCollectionFolderPath,
                    newCollectionFolderPath
                );
                await this.addCollectionExportedRecord(
                    exportDir,
                    collection,
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
}
export default new ExportService();
