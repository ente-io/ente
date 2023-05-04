import { runningInBrowser } from 'utils/common';
import {
    getUnExportedFiles,
    getGoogleLikeMetadataFile,
    getExportRecordFileUID,
    getUniqueCollectionExportName,
    getUniqueFileExportName,
    getFileMetadataExportPath,
    getFileExportPath,
    getRenamedExportedCollections,
    getDeletedExportedFiles,
    convertCollectionIDExportNameObjectToMap,
    convertFileIDExportNameObjectToMap,
    getDeletedExportedCollections,
    getTrashedFileExportPath,
    getMetadataFileExportPath,
    getCollectionExportedFiles,
    getCollectionExportPath,
    getMetadataFolderExportPath,
    getLivePhotoExportName,
    isLivePhotoExportName,
    parseLivePhotoExportName,
    getCollectionIDFromFileUID,
} from 'utils/export';
import { retryAsyncFunction } from 'utils/network';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { getLocalCollections } from '../collectionService';
import downloadManager from '../downloadManager';
import { getLocalFiles } from '../fileService';
import { EnteFile } from 'types/file';

import { decodeLivePhoto } from '../livePhotoService';
import {
    generateStreamFromArrayBuffer,
    getFileExtension,
    getPersonalFiles,
} from 'utils/file';

import { updateFileCreationDateInEXIF } from '../upload/exifService';
import QueueProcessor from '../queueProcessor';
import { Collection } from 'types/collection';
import {
    ExportProgress,
    ExportRecord,
    ExportSettings,
    ExportUIUpdaters,
    FileExportStats,
} from 'types/export';
import { User } from 'types/user';
import { FILE_TYPE, TYPE_JPEG, TYPE_JPG } from 'constants/file';
import { ExportStage } from 'constants/export';
import { ElectronAPIs } from 'types/electron';
import { CustomError } from 'utils/error';
import { addLocalLog, addLogLine } from 'utils/logging';
import { eventBus, Events } from '../events';
import {
    getCollectionNameMap,
    getNonEmptyPersonalCollections,
} from 'utils/collection';
import { migrateExportJSON } from './migration';

const EXPORT_RECORD_FILE_NAME = 'export_status.json';

export const ENTE_EXPORT_DIRECTORY = 'ente Photos';

class ExportService {
    private electronAPIs: ElectronAPIs;
    private exportInProgress: boolean = false;
    private reRunNeeded = false;
    private exportRecordUpdater = new QueueProcessor<ExportRecord>(1);
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
    private migrationInProgress: Promise<void>;

    constructor() {
        if (runningInBrowser()) {
            this.electronAPIs = window['ElectronAPIs'];
            this.allElectronAPIsExist = !!this.electronAPIs?.exists;
            this.fileReader = new FileReader();
        }
    }

    getExportSettings(): ExportSettings {
        const exportSettings = getData(LS_KEYS.EXPORT);
        return exportSettings;
    }

    updateExportSettings(newData: Partial<ExportSettings>) {
        const exportSettings = this.getExportSettings();
        const newSettings = { ...exportSettings, ...newData };
        setData(LS_KEYS.EXPORT, newSettings);
    }

    async init(uiUpdater: ExportUIUpdaters) {
        this.setUIUpdaters(uiUpdater);
        this.migrationInProgress = migrateExportJSON();
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
            this.continuousExportEventHandler = () => {
                this.scheduleExport();
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

    getFileExportStats = async (): Promise<FileExportStats> => {
        try {
            const exportRecord = await this.getExportRecord();
            const user: User = getData(LS_KEYS.USER);
            const files = await getLocalFiles();
            const collections = await getLocalCollections();
            const userPersonalFiles = getPersonalFiles(files, user);
            const userNonEmptyPersonalCollections =
                getNonEmptyPersonalCollections(
                    collections,
                    userPersonalFiles,
                    user
                );
            const unExportedFiles = getUnExportedFiles(
                userPersonalFiles,
                exportRecord
            );
            const deletedExportedFiles = getDeletedExportedFiles(
                userPersonalFiles,
                exportRecord
            );
            const renamedCollections = getRenamedExportedCollections(
                userNonEmptyPersonalCollections,
                exportRecord
            );
            const deletedCollections = getDeletedExportedCollections(
                userNonEmptyPersonalCollections,
                exportRecord
            );
            return {
                totalCount: userPersonalFiles.length,
                pendingCount:
                    unExportedFiles.length +
                    deletedExportedFiles.length +
                    renamedCollections.length +
                    deletedCollections.length,
            };
        } catch (e) {
            logError(e, 'getUpdateFileLists failed');
            throw e;
        }
    };

    async preExport() {
        this.stopExport = false;
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
            this.exportInProgress = true;
            if (this.migrationInProgress) {
                addLogLine('migration in progress, waiting for it to complete');
                await this.migrationInProgress;
                this.migrationInProgress = null;
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
                    setTimeout(() => this.scheduleExport(), 0);
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
            const exportSettings = this.getExportSettings();
            if (!exportSettings?.folder) {
                throw new Error(CustomError.NO_EXPORT_FOLDER_SELECTED);
            }
            const user: User = getData(LS_KEYS.USER);
            const files = await getLocalFiles();
            const collections = await getLocalCollections();
            const personalFiles = getPersonalFiles(files, user);
            const nonEmptyPersonalCollections = getNonEmptyPersonalCollections(
                collections,
                personalFiles,
                user
            );
            const exportRecord = await this.getExportRecord(
                exportSettings.folder
            );

            const collectionIDExportNameMap =
                convertCollectionIDExportNameObjectToMap(
                    exportRecord.collectionExportNames
                );
            const collectionIDNameMap = getCollectionNameMap(
                nonEmptyPersonalCollections
            );

            const renamedCollections = getRenamedExportedCollections(
                nonEmptyPersonalCollections,
                exportRecord
            );

            const removedFileUIDs = getDeletedExportedFiles(
                personalFiles,
                exportRecord
            );
            const filesToExport = getUnExportedFiles(
                personalFiles,
                exportRecord
            );
            const deletedExportedCollections = getDeletedExportedCollections(
                nonEmptyPersonalCollections,
                exportRecord
            );

            if (
                removedFileUIDs.length > 0 ||
                filesToExport.length > 0 ||
                renamedCollections.length > 0 ||
                deletedExportedCollections.length > 0
            ) {
                let success = 0;
                let failed = 0;
                this.uiUpdater.updateExportProgress({
                    success: success,
                    failed: failed,
                    total: removedFileUIDs.length + filesToExport.length,
                });
                const incrementSuccess = () => {
                    this.updateExportProgress({
                        success: ++success,
                        failed: failed,
                        total: removedFileUIDs.length + filesToExport.length,
                    });
                };
                const incrementFailed = () => {
                    this.updateExportProgress({
                        success: success,
                        failed: ++failed,
                        total: removedFileUIDs.length + filesToExport.length,
                    });
                };
                if (
                    renamedCollections?.length > 0 &&
                    this.checkAllElectronAPIsExists()
                ) {
                    addLogLine(
                        `renaming ${renamedCollections.length} collections`
                    );
                    this.collectionRenamer(
                        exportSettings.folder,
                        collectionIDExportNameMap,
                        renamedCollections,
                        incrementSuccess,
                        incrementFailed
                    );
                }

                if (removedFileUIDs?.length > 0) {
                    addLogLine(`trashing ${removedFileUIDs.length} files`);
                    await this.fileTrasher(
                        exportSettings.folder,
                        collectionIDExportNameMap,
                        removedFileUIDs,
                        incrementSuccess,
                        incrementFailed
                    );
                }
                if (filesToExport?.length > 0) {
                    addLogLine(`exporting ${filesToExport.length} files`);
                    await this.fileExporter(
                        filesToExport,
                        collectionIDNameMap,
                        collectionIDExportNameMap,
                        exportSettings.folder,
                        incrementSuccess,
                        incrementFailed
                    );
                }
                if (deletedExportedCollections?.length > 0) {
                    addLogLine(
                        `removing ${deletedExportedCollections.length} collections`
                    );
                    await this.collectionRemover(
                        deletedExportedCollections,
                        exportSettings.folder,
                        incrementSuccess,
                        incrementFailed
                    );
                }
            }
        } catch (e) {
            logError(e, 'runExport failed');
        }
    }

    async collectionRenamer(
        exportFolder: string,
        collectionIDExportNameMap: Map<number, string>,
        renamedCollections: Collection[],
        incrementSuccess: () => void,
        incrementFailed: () => void
    ) {
        try {
            for (const collection of renamedCollections) {
                try {
                    addLocalLog(
                        () =>
                            `renaming collection ${collection.name} with id ${collection.id}`
                    );
                    const oldCollectionExportName =
                        collectionIDExportNameMap.get(collection.id);
                    const oldCollectionExportPath = getCollectionExportPath(
                        exportFolder,
                        oldCollectionExportName
                    );

                    const newCollectionExportName =
                        getUniqueCollectionExportName(
                            exportFolder,
                            collection.name
                        );
                    const newCollectionExportPath = getCollectionExportPath(
                        exportFolder,
                        newCollectionExportName
                    );

                    await this.electronAPIs.checkExistsAndRename(
                        oldCollectionExportPath,
                        newCollectionExportPath
                    );

                    await this.addCollectionExportedRecord(
                        exportFolder,
                        collection.id,
                        newCollectionExportName
                    );
                    collectionIDExportNameMap.set(
                        collection.id,
                        newCollectionExportName
                    );
                    incrementSuccess();
                } catch (e) {
                    incrementFailed();
                    logError(e, 'collectionRenamer failed a collection');
                    if (
                        e.message ===
                        CustomError.ADD_FILE_EXPORTED_RECORD_FAILED
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            logError(e, 'collectionRenamer failed');
            throw e;
        }
    }

    async collectionRemover(
        deletedExportedCollectionIDs: number[],
        exportFolder: string,
        incrementSuccess: () => void,
        incrementFailed: () => void
    ) {
        try {
            const exportRecord = await this.getExportRecord(exportFolder);
            const collectionIDPathMap =
                convertCollectionIDExportNameObjectToMap(
                    exportRecord.collectionExportNames
                );
            for (const collectionID of deletedExportedCollectionIDs) {
                try {
                    addLocalLog(
                        () =>
                            `removing collection with id ${collectionID} from export folder`
                    );
                    const collectionExportName =
                        collectionIDPathMap.get(collectionID);
                    // verify that the all exported files from the collection has been removed
                    const collectionExportedFiles = getCollectionExportedFiles(
                        exportRecord,
                        collectionID
                    );
                    if (collectionExportedFiles.length > 0) {
                        throw new Error(
                            "collection is not empty, can't remove"
                        );
                    }
                    // delete the collection folder
                    await this.electronAPIs.deleteFolder(
                        getCollectionExportPath(
                            exportFolder,
                            collectionExportName
                        )
                    );
                    await this.removeCollectionExportedRecord(
                        exportFolder,
                        collectionID
                    );
                    incrementSuccess();
                } catch (e) {
                    incrementFailed();
                    logError(e, 'collectionRemover failed a collection');
                    if (
                        e.message ===
                        CustomError.ADD_FILE_EXPORTED_RECORD_FAILED
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            logError(e, 'collectionRemover failed');
            throw e;
        }
    }

    async fileExporter(
        files: EnteFile[],
        collectionIDNameMap: Map<number, string>,
        collectionIDFolderNameMap: Map<number, string>,
        exportDir: string,
        incrementSuccess: () => void,
        incrementFailed: () => void
    ): Promise<void> {
        try {
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
                    let collectionExportName = collectionIDFolderNameMap.get(
                        file.collectionID
                    );
                    if (!collectionExportName) {
                        collectionExportName =
                            await this.createNewCollectionExport(
                                exportDir,
                                file.collectionID,
                                collectionIDNameMap
                            );
                        await this.addCollectionExportedRecord(
                            exportDir,
                            file.collectionID,
                            collectionExportName
                        );
                        collectionIDFolderNameMap.set(
                            file.collectionID,
                            collectionExportName
                        );
                    } else {
                        const collectionExportPath = getCollectionExportPath(
                            exportDir,
                            collectionExportName
                        );
                        await this.electronAPIs.checkExistsAndCreateDir(
                            collectionExportPath
                        );
                    }
                    const collectionExportPath = getCollectionExportPath(
                        exportDir,
                        collectionExportName
                    );
                    const fileExportName = await this.downloadAndSave(
                        collectionExportPath,
                        file
                    );
                    await this.addFileExportedRecord(
                        exportDir,
                        file,
                        fileExportName
                    );
                    incrementSuccess();
                } catch (e) {
                    incrementFailed();
                    logError(e, 'export failed for a file');
                    if (
                        e.message ===
                        CustomError.ADD_FILE_EXPORTED_RECORD_FAILED
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            logError(e, 'fileExporter failed');
            throw e;
        }
    }

    async fileTrasher(
        exportDir: string,
        collectionIDExportNameMap: Map<number, string>,
        removedFileUIDs: string[],
        incrementSuccess: () => void,
        incrementFailed: () => void
    ): Promise<void> {
        try {
            const exportRecord = await this.getExportRecord(exportDir);
            const fileIDExportNameMap = convertFileIDExportNameObjectToMap(
                exportRecord.fileExportNames
            );
            for (const fileUID of removedFileUIDs) {
                addLocalLog(() => `trashing file with id ${fileUID}`);
                if (this.stopExport) {
                    break;
                }
                try {
                    const fileExportName = fileIDExportNameMap.get(fileUID);
                    const collectionID = getCollectionIDFromFileUID(fileUID);
                    const collectionExportPath = getCollectionExportPath(
                        exportDir,
                        collectionIDExportNameMap.get(collectionID)
                    );
                    // check if filepath is for live photo
                    // livePhoto has the path in format: `JSON.stringify({image,video})`
                    if (isLivePhotoExportName(fileExportName)) {
                        const {
                            image: imageExportName,
                            video: videoExportName,
                        } = parseLivePhotoExportName(fileExportName);
                        const imageExportPath = getFileExportPath(
                            collectionExportPath,
                            imageExportName
                        );
                        addLocalLog(
                            () =>
                                `moving image file ${imageExportPath} to trash folder`
                        );
                        await this.electronAPIs.moveFile(
                            imageExportPath,
                            getTrashedFileExportPath(exportDir, imageExportPath)
                        );

                        const imageMetadataFileExportPath =
                            getMetadataFileExportPath(imageExportPath);

                        await this.electronAPIs.moveFile(
                            imageMetadataFileExportPath,
                            getTrashedFileExportPath(
                                exportDir,
                                imageMetadataFileExportPath
                            )
                        );

                        const videoExportPath = getFileExportPath(
                            collectionExportPath,
                            videoExportName
                        );
                        addLocalLog(
                            () =>
                                `moving video file ${videoExportPath} to trash folder`
                        );
                        await this.electronAPIs.moveFile(
                            videoExportPath,
                            getTrashedFileExportPath(exportDir, videoExportPath)
                        );
                        const videoMetadataFileExportPath =
                            getMetadataFileExportPath(videoExportPath);
                        await this.electronAPIs.moveFile(
                            videoMetadataFileExportPath,
                            getTrashedFileExportPath(
                                exportDir,
                                videoMetadataFileExportPath
                            )
                        );
                    } else {
                        const fileExportPath = getFileExportPath(
                            collectionExportPath,
                            fileExportName
                        );
                        const trashedFilePath = getTrashedFileExportPath(
                            exportDir,
                            fileExportPath
                        );
                        addLocalLog(
                            () =>
                                `moving file ${fileExportPath} to ${trashedFilePath} trash folder`
                        );
                        await this.electronAPIs.moveFile(
                            fileExportPath,
                            trashedFilePath
                        );
                        const metadataFileExportPath =
                            getMetadataFileExportPath(fileExportPath);
                        await this.electronAPIs.moveFile(
                            metadataFileExportPath,
                            getTrashedFileExportPath(
                                exportDir,
                                metadataFileExportPath
                            )
                        );
                    }
                    await this.removeFileExportedRecord(exportDir, fileUID);
                    incrementSuccess();
                } catch (e) {
                    incrementFailed();
                    logError(e, 'trashing failed for a file');
                    if (
                        e.message ===
                        CustomError.ADD_FILE_EXPORTED_RECORD_FAILED
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            logError(e, 'fileTrasher failed');
            throw e;
        }
    }

    async addFileExportedRecord(
        folder: string,
        file: EnteFile,
        fileExportName: string
    ) {
        try {
            const fileUID = getExportRecordFileUID(file);
            const exportRecord = await this.getExportRecord(folder);
            if (!exportRecord.fileExportNames) {
                exportRecord.fileExportNames = {};
            }
            exportRecord.fileExportNames = {
                ...exportRecord.fileExportNames,
                [fileUID]: fileExportName,
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
        collectionExportName: string
    ) {
        try {
            const exportRecord = await this.getExportRecord(folder);
            if (!exportRecord?.collectionExportNames) {
                exportRecord.collectionExportNames = {};
            }
            exportRecord.collectionExportNames = {
                ...exportRecord.collectionExportNames,
                [collectionID]: collectionExportName,
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

            exportRecord.collectionExportNames = Object.fromEntries(
                Object.entries(exportRecord.collectionExportNames).filter(
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
            exportRecord.fileExportNames = Object.fromEntries(
                Object.entries(exportRecord.fileExportNames).filter(
                    ([key]) => key !== fileUID
                )
            );
            await this.updateExportRecord(exportRecord, folder);
        } catch (e) {
            logError(e, 'removeFileExportedRecord failed');
            throw Error(CustomError.ADD_FILE_EXPORTED_RECORD_FAILED);
        }
    }

    updateExportRecord(newData: Partial<ExportRecord>, folder?: string) {
        const response = this.exportRecordUpdater.queueUpRequest(() =>
            this.updateExportRecordHelper(folder, newData)
        );
        return response.promise;
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
            const newRecord: ExportRecord = { ...exportRecord, ...newData };
            await this.electronAPIs.setExportRecord(
                `${folder}/${EXPORT_RECORD_FILE_NAME}`,
                JSON.stringify(newRecord, null, 2)
            );
            return newRecord;
        } catch (e) {
            logError(e, 'error updating Export Record');
            throw e;
        }
    }

    async getExportRecord(folder?: string): Promise<ExportRecord> {
        let recordFile: string;
        try {
            if (!folder) {
                const exportSettings = this.getExportSettings();
                folder = exportSettings?.folder;
            }
            if (!folder) {
                return null;
            }
            const exportFolderExists = this.exists(folder);
            if (!exportFolderExists) {
                return null;
            }
            recordFile = await this.electronAPIs.getExportRecord(
                `${folder}/${EXPORT_RECORD_FILE_NAME}`
            );
            return JSON.parse(recordFile);
        } catch (e) {
            logError(e, 'export Record JSON parsing failed ', { recordFile });
            throw e;
        }
    }

    async createNewCollectionExport(
        exportFolder: string,
        collectionID: number,
        collectionIDNameMap: Map<number, string>
    ) {
        const collectionName = collectionIDNameMap.get(collectionID);
        const collectionExportName = getUniqueCollectionExportName(
            exportFolder,
            collectionName
        );
        const collectionExportPath = getCollectionExportPath(
            exportFolder,
            collectionExportName
        );
        await this.electronAPIs.checkExistsAndCreateDir(collectionExportPath);
        await this.electronAPIs.checkExistsAndCreateDir(
            getMetadataFolderExportPath(collectionExportPath)
        );

        return collectionExportName;
    }
    async renameCollectionExports(
        renamedCollections: Collection[],
        exportFolder: string,
        collectionIDPathMap: Map<number, string>
    ) {
        for (const collection of renamedCollections) {
            const oldCollectionExportPath = collectionIDPathMap.get(
                collection.id
            );

            const newCollectionExportPath = getUniqueCollectionExportName(
                exportFolder,
                collection.name
            );
            await this.electronAPIs.checkExistsAndRename(
                oldCollectionExportPath,
                newCollectionExportPath
            );

            await this.addCollectionExportedRecord(
                exportFolder,
                collection.id,
                newCollectionExportPath
            );
            collectionIDPathMap.set(collection.id, newCollectionExportPath);
        }
    }

    async downloadAndSave(
        collectionExportPath: string,
        file: EnteFile
    ): Promise<string> {
        try {
            const fileExportName = getUniqueFileExportName(
                collectionExportPath,
                file.metadata.title
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
                return await this.exportLivePhoto(
                    collectionExportPath,
                    fileStream,
                    file
                );
            } else {
                await this.saveMediaFile(
                    collectionExportPath,
                    fileExportName,
                    fileStream
                );
                await this.saveMetadataFile(
                    collectionExportPath,
                    fileExportName,
                    file
                );
                return fileExportName;
            }
        } catch (e) {
            logError(e, 'download and save failed');
            throw e;
        }
    }

    private async exportLivePhoto(
        collectionExportPath: string,
        fileStream: ReadableStream<any>,
        file: EnteFile
    ) {
        const fileBlob = await new Response(fileStream).blob();
        const livePhoto = await decodeLivePhoto(file, fileBlob);
        const imageStream = generateStreamFromArrayBuffer(livePhoto.image);
        const imageExportName = getUniqueFileExportName(
            collectionExportPath,
            livePhoto.imageNameTitle
        );
        await this.saveMediaFile(
            collectionExportPath,
            imageExportName,
            imageStream
        );
        await this.saveMetadataFile(
            collectionExportPath,
            imageExportName,
            file
        );

        const videoStream = generateStreamFromArrayBuffer(livePhoto.video);
        const videoExportName = getUniqueFileExportName(
            collectionExportPath,
            livePhoto.videoNameTitle
        );
        await this.saveMediaFile(
            collectionExportPath,
            videoExportName,
            videoStream
        );
        await this.saveMetadataFile(
            collectionExportPath,
            videoExportName,
            file
        );

        return getLivePhotoExportName(imageExportName, videoExportName);
    }

    private async saveMediaFile(
        collectionExportPath: string,
        fileExportName: string,
        fileStream: ReadableStream<any>
    ) {
        await this.electronAPIs.saveStreamToDisk(
            getFileExportPath(collectionExportPath, fileExportName),
            fileStream
        );
    }
    private async saveMetadataFile(
        collectionExportPath: string,
        fileExportName: string,
        file: EnteFile
    ) {
        await this.electronAPIs.saveFileToDisk(
            getFileMetadataExportPath(collectionExportPath, fileExportName),
            getGoogleLikeMetadataFile(fileExportName, file)
        );
    }

    isExportInProgress = () => {
        return this.exportInProgress;
    };

    exists = (path: string) => {
        return this.electronAPIs.exists(path);
    };
    checkExistsAndRename = (oldPath: string, newPath: string) => {
        return this.electronAPIs.checkExistsAndRename(oldPath, newPath);
    };

    checkExistsAndCreateDir = (path: string) => {
        return this.electronAPIs.checkExistsAndCreateDir(path);
    };

    checkAllElectronAPIsExists = () => this.allElectronAPIsExist;
}
export default new ExportService();
