/**
 * @file Interface with the Node.js layer of our desktop app to provide the
 * watch folders functionality.
 */

import { ensureElectron } from "@/next/electron";
import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import type { FolderWatch } from "@/next/types/ipc";
import { UPLOAD_RESULT, UPLOAD_STRATEGY } from "constants/upload";
import debounce from "debounce";
import uploadManager from "services/upload/uploadManager";
import { Collection } from "types/collection";
import { EncryptedEnteFile } from "types/file";
import { ElectronFile, FileWithCollection } from "types/upload";
import { WatchMappingSyncedFile } from "types/watchFolder";
import { groupFilesBasedOnCollectionID } from "utils/file";
import { isSystemFile } from "utils/upload";
import { removeFromCollection } from "./collectionService";
import { getLocalFiles } from "./fileService";

/**
 * A file system watch event encapsulates a change that has occurred on disk
 * that needs us to take some action within Ente to synchronize with the user's
 * Ente collections.
 *
 * Events get added in two ways:
 *
 * - When the app starts, it reads the current state of files on disk and
 *   compares that with its last known state to determine what all events it
 *   missed. This is easier than it sounds as we have only two events: add and
 *   remove.
 *
 * - When the app is running, it gets live notifications from our file system
 *   watcher (from the Node.js layer) about changes that have happened on disk,
 *   which the app then enqueues onto the event queue if they pertain to the
 *   files we're interested in.
 */
interface WatchEvent {
    /** The action to take */
    action: "upload" | "trash";
    /** The path of the root folder corresponding to the {@link FolderWatch}. */
    folderPath: string;
    /** The name of the Ente collection the file belongs to. */
    collectionName?: string;
    /** The absolute path to the file under consideration. */
    filePath: string;
}

class WatchFolderService {
    private eventQueue: WatchEvent[] = [];
    private currentEvent: WatchEvent;
    private currentlySyncedMapping: FolderWatch;
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
            await this.syncWithDisk();
        } catch (e) {
            log.error("error while initializing watch service", e);
        }
    }

    /**
     * Return true if we are currently processing an event for the given
     * {@link watch}
     */
    isSyncingWatch(watch: FolderWatch) {
        return this.currentEvent?.folderPath === watch.folderPath;
    }

    private async syncWithDisk() {
        try {
            const electron = ensureElectron();
            const mappings = await electron.getWatchMappings();
            if (!mappings) return;

            this.eventQueue = [];
            const { events, deletedFolderPaths } = await deduceEvents(mappings);
            log.info(`Folder watch deduced ${events.length} events`);
            this.eventQueue = this.eventQueue.concat(events);

            for (const path of deletedFolderPaths)
                electron.removeWatchMapping(path);

            this.debouncedRunNextEvent();
        } catch (e) {
            log.error("Ignoring error while syncing watched folders", e);
        }
    }

    private pushEvent(event: WatchEvent) {
        this.eventQueue.push(event);
        log.info("Folder watch event", event);
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
            this.syncWithDisk();
        } catch (e) {
            log.error("error while adding watch mapping", e);
        }
    }

    /**
     * Remove the folder watch corresponding to the given root
     * {@link folderPath}.
     */
    async removeWatchForFolderPath(folderPath: string) {
        await ensureElectron().removeWatchMapping(folderPath);
    }

    async getWatchMappings(): Promise<FolderWatch[]> {
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

            const syncedFiles: FolderWatch["syncedFiles"] = [];
            const ignoredFiles: FolderWatch["ignoredFiles"] = [];

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
        syncedFiles: FolderWatch["syncedFiles"],
        ignoredFiles: FolderWatch["ignoredFiles"],
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

    private async trashByIDs(toTrashFiles: FolderWatch["syncedFiles"]) {
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
                collectionName: collectionNameForPath(filePath, mapping),
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
            return await ensureElectron().fs.isDir(folderPath);
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
        this.syncWithDisk();
    }
}

const watchFolderService = new WatchFolderService();

export default watchFolderService;

async function diskFileAddedCallback(file: ElectronFile) {
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
        path: file.path,
    };
    watchFolderService.pushEvent(event);
}

async function diskFileRemovedCallback(filePath: string) {
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
        path: filePath,
    };
    watchFolderService.pushEvent(event);
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
    mapping: FolderWatch,
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

function isSyncedOrIgnoredFile(file: ElectronFile, mapping: FolderWatch) {
    return (
        mapping.ignoredFiles.includes(file.path) ||
        mapping.syncedFiles.find((f) => f.path === file.path)
    );
}

/**
 * Determine which events we need to process to synchronize the watched on-disk
 * folders to their corresponding collections.
 *
 * Also return a list of previously created folder watches for which there is no
 * longer any no corresponding directory on disk.
 */
const deduceEvents = async (
    watches: FolderWatch[],
): Promise<{
    events: WatchEvent[];
    deletedFolderPaths: string[];
}> => {
    const electron = ensureElectron();

    const activeWatches = [];
    const deletedFolderPaths: string[] = [];

    for (const watch of watches) {
        const valid = await electron.fs.isDir(watch.folderPath);
        if (!valid) deletedFolderPaths.push(watch.folderPath);
        else activeWatches.push(watch);
    }

    const events: WatchEvent[] = [];

    for (const watch of activeWatches) {
        const folderPath = watch.folderPath;

        const paths = (await electron.watch.findFiles(folderPath))
            // Filter out hidden files (files whose names begins with a dot)
            .filter((path) => !nameAndExtension(path)[0].startsWith("."));

        // Files that are on disk but not yet synced.
        const pathsToUpload = paths.filter(
            (path) => !isSyncedOrIgnoredPath(path, watch),
        );

        for (const path of pathsToUpload)
            events.push({
                action: "upload",
                folderPath,
                collectionName: collectionNameForPath(path, watch),
                filePath: path,
            });

        // Synced files that are no longer on disk
        const pathsToRemove = watch.syncedFiles.filter(
            (file) => !paths.includes(file.path),
        );

        for (const path of pathsToRemove)
            events.push({
                action: "trash",
                folderPath,
                collectionName: collectionNameForPath(path, watch),
                filePath: path,
            });
    }

    return { events, deletedFolderPaths };
};

const isSyncedOrIgnoredPath = (path: string, watch: FolderWatch) =>
    watch.ignoredFiles.includes(path) ||
    watch.syncedFiles.find((f) => f.path === path);

const collectionNameForPath = (filePath: string, watch: FolderWatch) =>
    watch.uploadStrategy === UPLOAD_STRATEGY.COLLECTION_PER_FOLDER
        ? parentDirectoryName(filePath)
        : watch.rootFolderName;

const parentDirectoryName = (filePath: string) => {
    const components = filePath.split("/");
    const parentName = components[components.length - 2];
    if (!parentName)
        throw new Error(
            `Unexpected file path without a parent folder: ${filePath}`,
        );
    return parentName;
};
