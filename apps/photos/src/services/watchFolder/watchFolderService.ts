import { Collection } from 'types/collection';
import { EncryptedEnteFile } from 'types/file';
import { ElectronFile, FileWithCollection } from 'types/upload';
import { removeFromCollection } from '../collectionService';
import { getLocalFiles } from '../fileService';
import { logError } from '@ente/shared/sentry';
import {
    EventQueueItem,
    WatchMapping,
    WatchMappingSyncedFile,
} from 'types/watchFolder';
import debounce from 'debounce';
import {
    diskFileAddedCallback,
    diskFileRemovedCallback,
    diskFolderRemovedCallback,
} from './watchFolderEventHandlers';
import { getParentFolderName } from './utils';
import { UPLOAD_RESULT, UPLOAD_STRATEGY } from 'constants/upload';
import uploadManager from 'services/upload/uploadManager';
import { addLocalLog, addLogLine } from '@ente/shared/logging';
import { getValidFilesToUpload } from 'utils/watch';
import { groupFilesBasedOnCollectionID } from 'utils/file';
import ElectronAPIs from '@ente/shared/electron';

class watchFolderService {
    private eventQueue: EventQueueItem[] = [];
    private currentEvent: EventQueueItem;
    private currentlySyncedMapping: WatchMapping;
    private trashingDirQueue: string[] = [];
    private isEventRunning: boolean = false;
    private uploadRunning: boolean = false;
    private filePathToUploadedFileIDMap = new Map<string, EncryptedEnteFile>();
    private unUploadableFilePaths = new Set<string>();
    private isPaused = false;
    private setElectronFiles: (files: ElectronFile[]) => void;
    private setCollectionName: (collectionName: string) => void;
    private syncWithRemote: () => void;
    private setWatchFolderServiceIsRunning: (isRunning: boolean) => void;
    private debouncedRunNextEvent: () => void;

    constructor() {
        this.debouncedRunNextEvent = debounce(() => this.runNextEvent(), 1000);
    }

    isUploadRunning() {
        return this.uploadRunning;
    }

    isSyncPaused() {
        return this.isPaused;
    }

    async init(
        setElectronFiles: (files: ElectronFile[]) => void,
        setCollectionName: (collectionName: string) => void,
        syncWithRemote: () => void,
        setWatchFolderServiceIsRunning: (isRunning: boolean) => void
    ) {
        try {
            this.setElectronFiles = setElectronFiles;
            this.setCollectionName = setCollectionName;
            this.syncWithRemote = syncWithRemote;
            this.setWatchFolderServiceIsRunning =
                setWatchFolderServiceIsRunning;
            this.setupWatcherFunctions();
            await this.getAndSyncDiffOfFiles();
        } catch (e) {
            logError(e, 'error while initializing watch service');
        }
    }

    async getAndSyncDiffOfFiles() {
        try {
            let mappings = this.getWatchMappings();

            if (!mappings?.length) {
                return;
            }

            mappings = await this.filterOutDeletedMappings(mappings);

            this.eventQueue = [];

            for (const mapping of mappings) {
                const filesOnDisk: ElectronFile[] =
                    await ElectronAPIs.getDirFiles(mapping.folderPath);

                this.uploadDiffOfFiles(mapping, filesOnDisk);
                this.trashDiffOfFiles(mapping, filesOnDisk);
            }
        } catch (e) {
            logError(e, 'error while getting and syncing diff of files');
        }
    }

    isMappingSyncInProgress(mapping: WatchMapping) {
        return this.currentEvent?.folderPath === mapping.folderPath;
    }

    private uploadDiffOfFiles(
        mapping: WatchMapping,
        filesOnDisk: ElectronFile[]
    ) {
        const filesToUpload = getValidFilesToUpload(filesOnDisk, mapping);

        if (filesToUpload.length > 0) {
            for (const file of filesToUpload) {
                const event: EventQueueItem = {
                    type: 'upload',
                    collectionName: this.getCollectionNameForMapping(
                        mapping,
                        file.path
                    ),
                    folderPath: mapping.folderPath,
                    files: [file],
                };
                this.pushEvent(event);
            }
        }
    }

    private trashDiffOfFiles(
        mapping: WatchMapping,
        filesOnDisk: ElectronFile[]
    ) {
        const filesToRemove = mapping.syncedFiles.filter((file) => {
            return !filesOnDisk.find(
                (electronFile) => electronFile.path === file.path
            );
        });

        if (filesToRemove.length > 0) {
            for (const file of filesToRemove) {
                const event: EventQueueItem = {
                    type: 'trash',
                    collectionName: this.getCollectionNameForMapping(
                        mapping,
                        file.path
                    ),
                    folderPath: mapping.folderPath,
                    paths: [file.path],
                };
                this.pushEvent(event);
            }
        }
    }

    private async filterOutDeletedMappings(
        mappings: WatchMapping[]
    ): Promise<WatchMapping[]> {
        const notDeletedMappings = [];
        for (const mapping of mappings) {
            const mappingExists = await ElectronAPIs.isFolder(
                mapping.folderPath
            );
            if (!mappingExists) {
                ElectronAPIs.removeWatchMapping(mapping.folderPath);
            } else {
                notDeletedMappings.push(mapping);
            }
        }
        return notDeletedMappings;
    }

    pushEvent(event: EventQueueItem) {
        this.eventQueue.push(event);
        this.debouncedRunNextEvent();
    }

    async pushTrashedDir(path: string) {
        this.trashingDirQueue.push(path);
    }

    private setupWatcherFunctions() {
        ElectronAPIs.registerWatcherFunctions(
            diskFileAddedCallback,
            diskFileRemovedCallback,
            diskFolderRemovedCallback
        );
    }

    async addWatchMapping(
        rootFolderName: string,
        folderPath: string,
        uploadStrategy: UPLOAD_STRATEGY
    ) {
        try {
            await ElectronAPIs.addWatchMapping(
                rootFolderName,
                folderPath,
                uploadStrategy
            );
            this.getAndSyncDiffOfFiles();
        } catch (e) {
            logError(e, 'error while adding watch mapping');
        }
    }

    async removeWatchMapping(folderPath: string) {
        try {
            await ElectronAPIs.removeWatchMapping(folderPath);
        } catch (e) {
            logError(e, 'error while removing watch mapping');
        }
    }

    getWatchMappings(): WatchMapping[] {
        try {
            return ElectronAPIs.getWatchMappings() ?? [];
        } catch (e) {
            logError(e, 'error while getting watch mappings');
            return [];
        }
        return [];
    }

    private setIsEventRunning(isEventRunning: boolean) {
        this.isEventRunning = isEventRunning;
        this.setWatchFolderServiceIsRunning(isEventRunning);
    }

    private async runNextEvent() {
        try {
            if (
                this.eventQueue.length === 0 ||
                this.isEventRunning ||
                this.isPaused
            ) {
                return;
            }

            const event = this.clubSameCollectionEvents();
            addLogLine(
                `running event type:${event.type} collectionName:${event.collectionName} folderPath:${event.folderPath} , fileCount:${event.files?.length} pathsCount: ${event.paths?.length}`
            );
            const mappings = this.getWatchMappings();
            const mapping = mappings.find(
                (mapping) => mapping.folderPath === event.folderPath
            );
            if (!mapping) {
                throw Error('no Mapping found for event');
            }
            addLogLine(
                `mapping for event rootFolder: ${mapping.rootFolderName} folderPath: ${mapping.folderPath} uploadStrategy: ${mapping.uploadStrategy} syncedFilesCount: ${mapping.syncedFiles.length} ignoredFilesCount ${mapping.ignoredFiles.length}`
            );
            if (event.type === 'upload') {
                event.files = getValidFilesToUpload(event.files, mapping);
                addLogLine(`valid files count: ${event.files?.length}`);
                if (event.files.length === 0) {
                    return;
                }
            }
            this.currentEvent = event;
            this.currentlySyncedMapping = mapping;

            this.setIsEventRunning(true);
            if (event.type === 'upload') {
                this.processUploadEvent();
            } else {
                await this.processTrashEvent();
                this.setIsEventRunning(false);
                setTimeout(() => this.runNextEvent(), 0);
            }
        } catch (e) {
            logError(e, 'runNextEvent failed');
        }
    }

    private async processUploadEvent() {
        try {
            this.uploadRunning = true;

            this.setCollectionName(this.currentEvent.collectionName);
            this.setElectronFiles(this.currentEvent.files);
        } catch (e) {
            logError(e, 'error while running next upload');
        }
    }

    async onFileUpload(
        fileUploadResult: UPLOAD_RESULT,
        fileWithCollection: FileWithCollection,
        file: EncryptedEnteFile
    ) {
        addLocalLog(() => `onFileUpload called`);
        if (!this.isUploadRunning()) {
            return;
        }
        if (
            [
                UPLOAD_RESULT.ADDED_SYMLINK,
                UPLOAD_RESULT.UPLOADED,
                UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL,
                UPLOAD_RESULT.ALREADY_UPLOADED,
            ].includes(fileUploadResult)
        ) {
            if (fileWithCollection.isLivePhoto) {
                this.filePathToUploadedFileIDMap.set(
                    (fileWithCollection.livePhotoAssets.image as ElectronFile)
                        .path,
                    file
                );
                this.filePathToUploadedFileIDMap.set(
                    (fileWithCollection.livePhotoAssets.video as ElectronFile)
                        .path,
                    file
                );
            } else {
                this.filePathToUploadedFileIDMap.set(
                    (fileWithCollection.file as ElectronFile).path,
                    file
                );
            }
        } else if (
            [UPLOAD_RESULT.UNSUPPORTED, UPLOAD_RESULT.TOO_LARGE].includes(
                fileUploadResult
            )
        ) {
            if (fileWithCollection.isLivePhoto) {
                this.unUploadableFilePaths.add(
                    (fileWithCollection.livePhotoAssets.image as ElectronFile)
                        .path
                );
                this.unUploadableFilePaths.add(
                    (fileWithCollection.livePhotoAssets.video as ElectronFile)
                        .path
                );
            } else {
                this.unUploadableFilePaths.add(
                    (fileWithCollection.file as ElectronFile).path
                );
            }
        }
    }

    async allFileUploadsDone(
        filesWithCollection: FileWithCollection[],
        collections: Collection[]
    ) {
        try {
            addLocalLog(
                () =>
                    `allFileUploadsDone,${JSON.stringify(
                        filesWithCollection
                    )} ${JSON.stringify(collections)}`
            );
            const collection = collections.find(
                (collection) =>
                    collection.id === filesWithCollection[0].collectionID
            );
            addLocalLog(() => `got collection ${!!collection}`);
            addLocalLog(
                () =>
                    `${this.isEventRunning} ${this.currentEvent.collectionName} ${collection?.name}`
            );
            if (
                !this.isEventRunning ||
                this.currentEvent.collectionName !== collection?.name
            ) {
                return;
            }

            const syncedFiles: WatchMapping['syncedFiles'] = [];
            const ignoredFiles: WatchMapping['ignoredFiles'] = [];

            for (const fileWithCollection of filesWithCollection) {
                this.handleUploadedFile(
                    fileWithCollection,
                    syncedFiles,
                    ignoredFiles
                );
            }

            addLocalLog(() => `syncedFiles ${JSON.stringify(syncedFiles)}`);
            addLocalLog(() => `ignoredFiles ${JSON.stringify(ignoredFiles)}`);

            if (syncedFiles.length > 0) {
                this.currentlySyncedMapping.syncedFiles = [
                    ...this.currentlySyncedMapping.syncedFiles,
                    ...syncedFiles,
                ];
                ElectronAPIs.updateWatchMappingSyncedFiles(
                    this.currentlySyncedMapping.folderPath,
                    this.currentlySyncedMapping.syncedFiles
                );
            }
            if (ignoredFiles.length > 0) {
                this.currentlySyncedMapping.ignoredFiles = [
                    ...this.currentlySyncedMapping.ignoredFiles,
                    ...ignoredFiles,
                ];
                ElectronAPIs.updateWatchMappingIgnoredFiles(
                    this.currentlySyncedMapping.folderPath,
                    this.currentlySyncedMapping.ignoredFiles
                );
            }

            this.runPostUploadsAction();
        } catch (e) {
            logError(e, 'error while running all file uploads done');
        }
    }

    private runPostUploadsAction() {
        this.setIsEventRunning(false);
        this.uploadRunning = false;
        this.runNextEvent();
    }

    private handleUploadedFile(
        fileWithCollection: FileWithCollection,
        syncedFiles: WatchMapping['syncedFiles'],
        ignoredFiles: WatchMapping['ignoredFiles']
    ) {
        if (fileWithCollection.isLivePhoto) {
            const imagePath = (
                fileWithCollection.livePhotoAssets.image as ElectronFile
            ).path;
            const videoPath = (
                fileWithCollection.livePhotoAssets.video as ElectronFile
            ).path;

            if (
                this.filePathToUploadedFileIDMap.has(imagePath) &&
                this.filePathToUploadedFileIDMap.has(videoPath)
            ) {
                const imageFile = {
                    path: imagePath,
                    uploadedFileID:
                        this.filePathToUploadedFileIDMap.get(imagePath).id,
                    collectionID:
                        this.filePathToUploadedFileIDMap.get(imagePath)
                            .collectionID,
                };
                const videoFile = {
                    path: videoPath,
                    uploadedFileID:
                        this.filePathToUploadedFileIDMap.get(videoPath).id,
                    collectionID:
                        this.filePathToUploadedFileIDMap.get(videoPath)
                            .collectionID,
                };
                syncedFiles.push(imageFile);
                syncedFiles.push(videoFile);
                addLocalLog(
                    () =>
                        `added image ${JSON.stringify(
                            imageFile
                        )} and video file ${JSON.stringify(
                            videoFile
                        )} to uploadedFiles`
                );
            } else if (
                this.unUploadableFilePaths.has(imagePath) &&
                this.unUploadableFilePaths.has(videoPath)
            ) {
                ignoredFiles.push(imagePath);
                ignoredFiles.push(videoPath);
                addLocalLog(
                    () =>
                        `added image ${imagePath} and video file ${videoPath} to rejectedFiles`
                );
            }
            this.filePathToUploadedFileIDMap.delete(imagePath);
            this.filePathToUploadedFileIDMap.delete(videoPath);
        } else {
            const filePath = (fileWithCollection.file as ElectronFile).path;

            if (this.filePathToUploadedFileIDMap.has(filePath)) {
                const file = {
                    path: filePath,
                    uploadedFileID:
                        this.filePathToUploadedFileIDMap.get(filePath).id,
                    collectionID:
                        this.filePathToUploadedFileIDMap.get(filePath)
                            .collectionID,
                };
                syncedFiles.push(file);
                addLocalLog(() => `added file ${JSON.stringify(file)} `);
            } else if (this.unUploadableFilePaths.has(filePath)) {
                ignoredFiles.push(filePath);
                addLocalLog(() => `added file ${filePath} to rejectedFiles`);
            }
            this.filePathToUploadedFileIDMap.delete(filePath);
        }
    }

    private async processTrashEvent() {
        try {
            if (this.checkAndIgnoreIfFileEventsFromTrashedDir()) {
                return;
            }

            const { paths } = this.currentEvent;
            const filePathsToRemove = new Set(paths);

            const files = this.currentlySyncedMapping.syncedFiles.filter(
                (file) => filePathsToRemove.has(file.path)
            );

            await this.trashByIDs(files);

            this.currentlySyncedMapping.syncedFiles =
                this.currentlySyncedMapping.syncedFiles.filter(
                    (file) => !filePathsToRemove.has(file.path)
                );
            ElectronAPIs.updateWatchMappingSyncedFiles(
                this.currentlySyncedMapping.folderPath,
                this.currentlySyncedMapping.syncedFiles
            );
        } catch (e) {
            logError(e, 'error while running next trash');
        }
    }

    private async trashByIDs(toTrashFiles: WatchMapping['syncedFiles']) {
        try {
            const files = await getLocalFiles();
            const toTrashFilesMap = new Map<number, WatchMappingSyncedFile>();
            for (const file of toTrashFiles) {
                toTrashFilesMap.set(file.uploadedFileID, file);
            }
            const filesToTrash = files.filter((file) => {
                if (toTrashFilesMap.has(file.id)) {
                    const fileToTrash = toTrashFilesMap.get(file.id);
                    if (fileToTrash.collectionID === file.collectionID) {
                        return true;
                    }
                }
            });
            const groupFilesByCollectionId =
                groupFilesBasedOnCollectionID(filesToTrash);

            for (const [
                collectionID,
                filesToTrash,
            ] of groupFilesByCollectionId.entries()) {
                await removeFromCollection(collectionID, filesToTrash);
            }
            this.syncWithRemote();
        } catch (e) {
            logError(e, 'error while trashing by IDs');
        }
    }

    private checkAndIgnoreIfFileEventsFromTrashedDir() {
        if (this.trashingDirQueue.length !== 0) {
            this.ignoreFileEventsFromTrashedDir(this.trashingDirQueue[0]);
            this.trashingDirQueue.shift();
            return true;
        }
        return false;
    }

    private ignoreFileEventsFromTrashedDir(trashingDir: string) {
        this.eventQueue = this.eventQueue.filter((event) =>
            event.paths.every((path) => !path.startsWith(trashingDir))
        );
    }

    async getCollectionNameAndFolderPath(filePath: string) {
        try {
            const mappings = this.getWatchMappings();

            const mapping = mappings.find(
                (mapping) =>
                    filePath.length > mapping.folderPath.length &&
                    filePath.startsWith(mapping.folderPath) &&
                    filePath[mapping.folderPath.length] === '/'
            );

            if (!mapping) {
                throw Error(`no mapping found`);
            }

            return {
                collectionName: this.getCollectionNameForMapping(
                    mapping,
                    filePath
                ),
                folderPath: mapping.folderPath,
            };
        } catch (e) {
            logError(e, 'error while getting collection name');
        }
    }

    private getCollectionNameForMapping(
        mapping: WatchMapping,
        filePath: string
    ) {
        return mapping.uploadStrategy === UPLOAD_STRATEGY.COLLECTION_PER_FOLDER
            ? getParentFolderName(filePath)
            : mapping.rootFolderName;
    }

    async selectFolder(): Promise<string> {
        try {
            const folderPath = await ElectronAPIs.selectDirectory();
            return folderPath;
        } catch (e) {
            logError(e, 'error while selecting folder');
        }
    }

    // Batches all the files to be uploaded (or trashed) from the
    // event queue of same collection as the next event
    private clubSameCollectionEvents(): EventQueueItem {
        const event = this.eventQueue.shift();
        while (
            this.eventQueue.length > 0 &&
            event.collectionName === this.eventQueue[0].collectionName &&
            event.type === this.eventQueue[0].type
        ) {
            if (event.type === 'trash') {
                event.paths = [...event.paths, ...this.eventQueue[0].paths];
            } else {
                event.files = [...event.files, ...this.eventQueue[0].files];
            }
            this.eventQueue.shift();
        }
        return event;
    }

    async isFolder(folderPath: string) {
        try {
            const isFolder = await ElectronAPIs.isFolder(folderPath);
            return isFolder;
        } catch (e) {
            logError(e, 'error while checking if folder exists');
        }
    }

    pauseRunningSync() {
        this.isPaused = true;
        uploadManager.cancelRunningUpload();
    }

    resumePausedSync() {
        this.isPaused = false;
        this.getAndSyncDiffOfFiles();
    }
}

export default new watchFolderService();
