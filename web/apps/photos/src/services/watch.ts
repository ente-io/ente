/**
 * @file Interface with the Node.js layer of our desktop app to provide the
 * watch folders functionality.
 */

import { ensureElectron } from "@/next/electron";
import log from "@/next/log";
import type { FolderWatch } from "@/next/types/ipc";
import { UPLOAD_RESULT, UPLOAD_STRATEGY } from "constants/upload";
import debounce from "debounce";
import uploadManager from "services/upload/uploadManager";
import { Collection } from "types/collection";
import { EncryptedEnteFile } from "types/file";
import { ElectronFile, FileWithCollection } from "types/upload";
import {
    EventQueueItem,
    WatchMapping,
    WatchMappingSyncedFile,
} from "types/watchFolder";
import { groupFilesBasedOnCollectionID } from "utils/file";
import { isSystemFile } from "utils/upload";
import { removeFromCollection } from "./collectionService";
import { getLocalFiles } from "./fileService";

class WatchFolderService {
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
        setWatchFolderServiceIsRunning: (isRunning: boolean) => void,
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
            log.error("error while initializing watch service", e);
        }
    }

    async getAndSyncDiffOfFiles() {
        try {
            const electron = ensureElectron();
            const mappings = await electron.getWatchMappings();
            if (!mappings) return;

            this.eventQueue = [];
            const { events, nonExistentFolderPaths } =
                await syncWithDisk(mappings);
            this.eventQueue = [...this.eventQueue, ...events];
            this.debouncedRunNextEvent();

            for (const path of nonExistentFolderPaths)
                electron.removeWatchMapping(path);
        } catch (e) {
            log.error("Ignoring error while syncing watched folders", e);
        }
    }

    isMappingSyncInProgress(mapping: WatchMapping) {
        return this.currentEvent?.folderPath === mapping.folderPath;
    }

    pushEvent(event: EventQueueItem) {
        this.eventQueue.push(event);
        this.debouncedRunNextEvent();
    }

    async pushTrashedDir(path: string) {
        this.trashingDirQueue.push(path);
    }

    private setupWatcherFunctions() {
        ensureElectron().registerWatcherFunctions(
            diskFileAddedCallback,
            diskFileRemovedCallback,
            diskFolderRemovedCallback,
        );
    }

    async addWatchMapping(
        rootFolderName: string,
        folderPath: string,
        uploadStrategy: UPLOAD_STRATEGY,
    ) {
        try {
            await ensureElectron().addWatchMapping(
                rootFolderName,
                folderPath,
                uploadStrategy,
            );
            this.getAndSyncDiffOfFiles();
        } catch (e) {
            log.error("error while adding watch mapping", e);
        }
    }

    async mappingsAfterRemovingFolder(folderPath: string) {
        await ensureElectron().removeWatchMapping(folderPath);
        return await this.getWatchMappings();
    }

    async getWatchMappings(): Promise<WatchMapping[]> {
        try {
            return (await ensureElectron().getWatchMappings()) ?? [];
        } catch (e) {
            log.error("error while getting watch mappings", e);
            return [];
        }
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
            log.info(
                `running event type:${event.type} collectionName:${event.collectionName} folderPath:${event.folderPath} , fileCount:${event.files?.length} pathsCount: ${event.paths?.length}`,
            );
            const mappings = await this.getWatchMappings();
            const mapping = mappings.find(
                (mapping) => mapping.folderPath === event.folderPath,
            );
            if (!mapping) {
                throw Error("no Mapping found for event");
            }
            log.info(
                `mapping for event rootFolder: ${mapping.rootFolderName} folderPath: ${mapping.folderPath} uploadStrategy: ${mapping.uploadStrategy} syncedFilesCount: ${mapping.syncedFiles.length} ignoredFilesCount ${mapping.ignoredFiles.length}`,
            );
            if (event.type === "upload") {
                event.files = getValidFilesToUpload(event.files, mapping);
                log.info(`valid files count: ${event.files?.length}`);
                if (event.files.length === 0) {
                    return;
                }
            }
            this.currentEvent = event;
            this.currentlySyncedMapping = mapping;

            this.setIsEventRunning(true);
            if (event.type === "upload") {
                this.processUploadEvent();
            } else {
                await this.processTrashEvent();
                this.setIsEventRunning(false);
                setTimeout(() => this.runNextEvent(), 0);
            }
        } catch (e) {
            log.error("runNextEvent failed", e);
        }
    }

    private async processUploadEvent() {
        try {
            this.uploadRunning = true;

            this.setCollectionName(this.currentEvent.collectionName);
            this.setElectronFiles(this.currentEvent.files);
        } catch (e) {
            log.error("error while running next upload", e);
        }
    }

    async onFileUpload(
        fileUploadResult: UPLOAD_RESULT,
        fileWithCollection: FileWithCollection,
        file: EncryptedEnteFile,
    ) {
        log.debug(() => `onFileUpload called`);
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
                    file,
                );
                this.filePathToUploadedFileIDMap.set(
                    (fileWithCollection.livePhotoAssets.video as ElectronFile)
                        .path,
                    file,
                );
            } else {
                this.filePathToUploadedFileIDMap.set(
                    (fileWithCollection.file as ElectronFile).path,
                    file,
                );
            }
        } else if (
            [UPLOAD_RESULT.UNSUPPORTED, UPLOAD_RESULT.TOO_LARGE].includes(
                fileUploadResult,
            )
        ) {
            if (fileWithCollection.isLivePhoto) {
                this.unUploadableFilePaths.add(
                    (fileWithCollection.livePhotoAssets.image as ElectronFile)
                        .path,
                );
                this.unUploadableFilePaths.add(
                    (fileWithCollection.livePhotoAssets.video as ElectronFile)
                        .path,
                );
            } else {
                this.unUploadableFilePaths.add(
                    (fileWithCollection.file as ElectronFile).path,
                );
            }
        }
    }

    async allFileUploadsDone(
        filesWithCollection: FileWithCollection[],
        collections: Collection[],
    ) {
        try {
            log.debug(
                () =>
                    `allFileUploadsDone,${JSON.stringify(
                        filesWithCollection,
                    )} ${JSON.stringify(collections)}`,
            );
            const collection = collections.find(
                (collection) =>
                    collection.id === filesWithCollection[0].collectionID,
            );
            log.debug(() => `got collection ${!!collection}`);
            log.debug(
                () =>
                    `${this.isEventRunning} ${this.currentEvent.collectionName} ${collection?.name}`,
            );
            if (
                !this.isEventRunning ||
                this.currentEvent.collectionName !== collection?.name
            ) {
                return;
            }

            const syncedFiles: WatchMapping["syncedFiles"] = [];
            const ignoredFiles: WatchMapping["ignoredFiles"] = [];

            for (const fileWithCollection of filesWithCollection) {
                this.handleUploadedFile(
                    fileWithCollection,
                    syncedFiles,
                    ignoredFiles,
                );
            }

            log.debug(() => `syncedFiles ${JSON.stringify(syncedFiles)}`);
            log.debug(() => `ignoredFiles ${JSON.stringify(ignoredFiles)}`);

            if (syncedFiles.length > 0) {
                this.currentlySyncedMapping.syncedFiles = [
                    ...this.currentlySyncedMapping.syncedFiles,
                    ...syncedFiles,
                ];
                await ensureElectron().updateWatchMappingSyncedFiles(
                    this.currentlySyncedMapping.folderPath,
                    this.currentlySyncedMapping.syncedFiles,
                );
            }
            if (ignoredFiles.length > 0) {
                this.currentlySyncedMapping.ignoredFiles = [
                    ...this.currentlySyncedMapping.ignoredFiles,
                    ...ignoredFiles,
                ];
                await ensureElectron().updateWatchMappingIgnoredFiles(
                    this.currentlySyncedMapping.folderPath,
                    this.currentlySyncedMapping.ignoredFiles,
                );
            }

            this.runPostUploadsAction();
        } catch (e) {
            log.error("error while running all file uploads done", e);
        }
    }

    private runPostUploadsAction() {
        this.setIsEventRunning(false);
        this.uploadRunning = false;
        this.runNextEvent();
    }

    private handleUploadedFile(
        fileWithCollection: FileWithCollection,
        syncedFiles: WatchMapping["syncedFiles"],
        ignoredFiles: WatchMapping["ignoredFiles"],
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
                log.debug(
                    () =>
                        `added image ${JSON.stringify(
                            imageFile,
                        )} and video file ${JSON.stringify(
                            videoFile,
                        )} to uploadedFiles`,
                );
            } else if (
                this.unUploadableFilePaths.has(imagePath) &&
                this.unUploadableFilePaths.has(videoPath)
            ) {
                ignoredFiles.push(imagePath);
                ignoredFiles.push(videoPath);
                log.debug(
                    () =>
                        `added image ${imagePath} and video file ${videoPath} to rejectedFiles`,
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
                log.debug(() => `added file ${JSON.stringify(file)}`);
            } else if (this.unUploadableFilePaths.has(filePath)) {
                ignoredFiles.push(filePath);
                log.debug(() => `added file ${filePath} to rejectedFiles`);
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
                (file) => filePathsToRemove.has(file.path),
            );

            await this.trashByIDs(files);

            this.currentlySyncedMapping.syncedFiles =
                this.currentlySyncedMapping.syncedFiles.filter(
                    (file) => !filePathsToRemove.has(file.path),
                );
            await ensureElectron().updateWatchMappingSyncedFiles(
                this.currentlySyncedMapping.folderPath,
                this.currentlySyncedMapping.syncedFiles,
            );
        } catch (e) {
            log.error("error while running next trash", e);
        }
    }

    private async trashByIDs(toTrashFiles: WatchMapping["syncedFiles"]) {
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
            log.error("error while trashing by IDs", e);
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
            event.paths.every((path) => !path.startsWith(trashingDir)),
        );
    }

    async getCollectionNameAndFolderPath(filePath: string) {
        try {
            const mappings = await this.getWatchMappings();

            const mapping = mappings.find(
                (mapping) =>
                    filePath.length > mapping.folderPath.length &&
                    filePath.startsWith(mapping.folderPath) &&
                    filePath[mapping.folderPath.length] === "/",
            );

            if (!mapping) {
                throw Error(`no mapping found`);
            }

            return {
                collectionName: getCollectionNameForMapping(mapping, filePath),
                folderPath: mapping.folderPath,
            };
        } catch (e) {
            log.error("error while getting collection name", e);
        }
    }

    async selectFolder(): Promise<string> {
        try {
            const folderPath = await ensureElectron().selectDirectory();
            return folderPath;
        } catch (e) {
            log.error("error while selecting folder", e);
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
            if (event.type === "trash") {
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
            const isFolder = await ensureElectron().isFolder(folderPath);
            return isFolder;
        } catch (e) {
            log.error("error while checking if folder exists", e);
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

const watchFolderService = new WatchFolderService();

export default watchFolderService;

const getParentFolderName = (filePath: string) => {
    const folderPath = filePath.substring(0, filePath.lastIndexOf("/"));
    const folderName = folderPath.substring(folderPath.lastIndexOf("/") + 1);
    return folderName;
};

async function diskFileAddedCallback(file: ElectronFile) {
    try {
        const collectionNameAndFolderPath =
            await watchFolderService.getCollectionNameAndFolderPath(file.path);

        if (!collectionNameAndFolderPath) {
            return;
        }

        const { collectionName, folderPath } = collectionNameAndFolderPath;

        const event: EventQueueItem = {
            type: "upload",
            collectionName,
            folderPath,
            files: [file],
        };
        watchFolderService.pushEvent(event);
        log.info(
            `added (upload) to event queue, collectionName:${event.collectionName} folderPath:${event.folderPath}, filesCount: ${event.files.length}`,
        );
    } catch (e) {
        log.error("error while calling diskFileAddedCallback", e);
    }
}

async function diskFileRemovedCallback(filePath: string) {
    try {
        const collectionNameAndFolderPath =
            await watchFolderService.getCollectionNameAndFolderPath(filePath);

        if (!collectionNameAndFolderPath) {
            return;
        }

        const { collectionName, folderPath } = collectionNameAndFolderPath;

        const event: EventQueueItem = {
            type: "trash",
            collectionName,
            folderPath,
            paths: [filePath],
        };
        watchFolderService.pushEvent(event);
        log.info(
            `added (trash) to event queue collectionName:${event.collectionName} folderPath:${event.folderPath} , pathsCount: ${event.paths.length}`,
        );
    } catch (e) {
        log.error("error while calling diskFileRemovedCallback", e);
    }
}

async function diskFolderRemovedCallback(folderPath: string) {
    try {
        const mappings = await watchFolderService.getWatchMappings();
        const mapping = mappings.find(
            (mapping) => mapping.folderPath === folderPath,
        );
        if (!mapping) {
            log.info(`folder not found in mappings, ${folderPath}`);
            throw Error(`Watch mapping not found`);
        }
        watchFolderService.pushTrashedDir(folderPath);
        log.info(`added trashedDir, ${folderPath}`);
    } catch (e) {
        log.error("error while calling diskFolderRemovedCallback", e);
    }
}

export function getValidFilesToUpload(
    files: ElectronFile[],
    mapping: WatchMapping,
) {
    const uniqueFilePaths = new Set<string>();
    return files.filter((file) => {
        if (!isSystemFile(file) && !isSyncedOrIgnoredFile(file, mapping)) {
            if (!uniqueFilePaths.has(file.path)) {
                uniqueFilePaths.add(file.path);
                return true;
            }
        }
        return false;
    });
}

function isSyncedOrIgnoredFile(file: ElectronFile, mapping: WatchMapping) {
    return (
        mapping.ignoredFiles.includes(file.path) ||
        mapping.syncedFiles.find((f) => f.path === file.path)
    );
}

/**
 * Determine which events we need to process to synchronize the watched albums
 * with the corresponding on disk folders.
 *
 * Also return a list of previously created folder watches for this there is no
 * longer any no corresponding folder on disk.
 */
const syncWithDisk = async (
    mappings: FolderWatch[],
): Promise<{
    events: EventQueueItem[];
    nonExistentFolderPaths: string[];
}> => {
    const activeMappings = [];
    const nonExistentFolderPaths: string[] = [];

    for (const mapping of mappings) {
        const active = await electron.isFolder(mapping.folderPath);
        if (!active) nonExistentFolderPaths.push(mapping.folderPath);
        else activeMappings.push(mapping);
    }

    const events: EventQueueItem[] = [];

    for (const mapping of activeMappings) {
        const files = await electron.getDirFiles(mapping.folderPath);

        const filesToUpload = getValidFilesToUpload(files, mapping);

        for (const file of filesToUpload)
            events.push({
                type: "upload",
                collectionName: getCollectionNameForMapping(mapping, file.path),
                folderPath: mapping.folderPath,
                files: [file],
            });

        const filesToRemove = mapping.syncedFiles.filter((file) => {
            return !files.find((f) => f.path === file.path);
        });

        for (const file of filesToRemove)
            events.push({
                type: "trash",
                collectionName: getCollectionNameForMapping(mapping, file.path),
                folderPath: mapping.folderPath,
                paths: [file.path],
            });
    }

    return { events, nonExistentFolderPaths };
};

const getCollectionNameForMapping = (
    mapping: WatchMapping,
    filePath: string,
) => {
    return mapping.uploadStrategy === UPLOAD_STRATEGY.COLLECTION_PER_FOLDER
        ? getParentFolderName(filePath)
        : mapping.rootFolderName;
};
