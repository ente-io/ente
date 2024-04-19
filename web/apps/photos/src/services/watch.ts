/**
 * @file Interface with the Node.js layer of our desktop app to provide the
 * watch folders functionality.
 */

import { ensureElectron } from "@/next/electron";
import { basename, dirname } from "@/next/file";
import log from "@/next/log";
import type {
    CollectionMapping,
    FolderWatch,
    FolderWatchSyncedFile,
} from "@/next/types/ipc";
import { UPLOAD_RESULT } from "constants/upload";
import debounce from "debounce";
import uploadManager from "services/upload/uploadManager";
import { Collection } from "types/collection";
import { EncryptedEnteFile } from "types/file";
import { ElectronFile, FileWithCollection } from "types/upload";
import { groupFilesBasedOnCollectionID } from "utils/file";
import { isHiddenFile, isSystemFile } from "utils/upload";
import { removeFromCollection } from "./collectionService";
import { getLocalFiles } from "./fileService";

/**
 * Watch for file system folders and automatically update the corresponding Ente
 * collections.
 *
 * This class relies on APIs exposed over the Electron IPC layer, and thus only
 * works when we're running inside our desktop app.
 */
class FolderWatcher {
    /** `true` if we are currently uploading */
    private uploadRunning = false;
    /** `true` if we are temporarily paused to let a user upload go through */
    private isPaused = false;
    /** Pending file system events that we need to process */
    private eventQueue: WatchEvent[] = [];
    private currentEvent: WatchEvent;
    // TODO(MR): dedup if possible
    private isEventRunning: boolean = false;
    /**
     * If the file system directory corresponding to the (root) folder path of a
     * folder watch is deleted on disk, we note down that in this queue so that
     * we can ignore any file system events that come for it next.
     *
     * TODO (MR): is this really even coming into play? the mappings are
     * pre-checked first.
     */
    private deletedFolderPaths: string[] = [];
    private currentlySyncedMapping: FolderWatch;
    private filePathToUploadedFileIDMap = new Map<string, EncryptedEnteFile>();
    private unUploadableFilePaths = new Set<string>();
    private setElectronFiles: (files: ElectronFile[]) => void;
    private setCollectionName: (collectionName: string) => void;
    private syncWithRemote: () => void;
    private debouncedRunNextEvent: () => void;

    constructor() {
        this.debouncedRunNextEvent = debounce(() => this.runNextEvent(), 1000);
    }

    /**
     * Initialize the watcher.
     *
     * This is only called when we're running in the context of our desktop app.
     */
    async init(
        setElectronFiles: (files: ElectronFile[]) => void,
        setCollectionName: (collectionName: string) => void,
        syncWithRemote: () => void,
    ) {
        this.setElectronFiles = setElectronFiles;
        this.setCollectionName = setCollectionName;
        this.syncWithRemote = syncWithRemote;
        this.registerListeners();
        await this.syncWithDisk();
    }

    /** `true` if we are currently using the uploader */
    isUploadRunning() {
        return this.uploadRunning;
    }

    /** `true` if syncing has been temporarily paused */
    isSyncPaused() {
        return this.isPaused;
    }

    /**
     * Temporarily pause syncing and cancel any running uploads.
     *
     * This frees up the uploader for handling user initated uploads.
     */
    pauseRunningSync() {
        this.isPaused = true;
        uploadManager.cancelRunningUpload();
    }

    /**
     * Resume from a temporary pause, resyncing from disk.
     *
     * Sibling of {@link pauseRunningSync}.
     */
    resumePausedSync() {
        this.isPaused = false;
        this.syncWithDisk();
    }

    /** Return the list of folders we are watching for changes. */
    async getWatches(): Promise<FolderWatch[]> {
        return await ensureElectron().watch.get();
    }

    /**
     * Return true if we are currently syncing files that belong to the given
     * {@link folderPath}.
     */
    isSyncingFolder(folderPath: string) {
        return (
            this.isEventRunning && this.currentEvent?.folderPath == folderPath
        );
    }

    /**
     * Add a new folder watch for the given root {@link folderPath}
     *
     * @param mapping The {@link CollectionMapping} to use to decide which
     * collection do files belonging to nested directories go to.
     *
     * @returns The updated list of watches.
     */
    async addWatch(folderPath: string, mapping: CollectionMapping) {
        const watches = await ensureElectron().watch.add(folderPath, mapping);
        this.syncWithDisk();
        return watches;
    }

    /**
     * Remove the folder watch for the given root {@link folderPath}.
     *
     * @returns The updated list of watches.
     */
    async removeWatch(folderPath: string) {
        return await ensureElectron().watch.remove(folderPath);
    }

    private async syncWithDisk() {
        try {
            const watches = await this.getWatches();
            if (!watches) return;

            this.eventQueue = [];
            const events = await deduceEvents(watches);
            log.info(`Folder watch deduced ${events.length} events`);
            this.eventQueue = this.eventQueue.concat(events);

            this.debouncedRunNextEvent();
        } catch (e) {
            log.error("Ignoring error while syncing watched folders", e);
        }
    }

    pushEvent(event: WatchEvent) {
        this.eventQueue.push(event);
        log.info("Folder watch event", event);
        this.debouncedRunNextEvent();
    }

    private registerListeners() {
        const watch = ensureElectron().watch;

        // [Note: File renames during folder watch]
        //
        // Renames come as two file system events - an `onAddFile` + an
        // `onRemoveFile` - in an arbitrary order.

        watch.onAddFile((path: string, watch: FolderWatch) => {
            this.pushEvent({
                action: "upload",
                collectionName: collectionNameForPath(path, watch),
                folderPath: watch.folderPath,
                filePath: path,
            });
        });

        watch.onRemoveFile((path: string, watch: FolderWatch) => {
            this.pushEvent({
                action: "trash",
                collectionName: collectionNameForPath(path, watch),
                folderPath: watch.folderPath,
                filePath: path,
            });
        });

        watch.onRemoveDir((path: string, watch: FolderWatch) => {
            if (path == watch.folderPath) {
                log.info(
                    `Received file system delete event for a watched folder at ${path}`,
                );
                this.deletedFolderPaths.push(path);
            }
        });
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
                `mapping for event rootFolder: ${mapping.rootFolderName} folderPath: ${mapping.folderPath} colelctionMapping: ${mapping.collectionMapping} syncedFilesCount: ${mapping.syncedFiles.length} ignoredFilesCount ${mapping.ignoredFiles.length}`,
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

            this.isEventRunning = true;
            if (event.type === "upload") {
                this.processUploadEvent();
            } else {
                await this.processTrashEvent();
                this.isEventRunning = false;
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
        this.isEventRunning = false;
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
            if (this.pruneFileEventsFromDeletedFolderPaths()) {
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
            const toTrashFilesMap = new Map<number, FolderWatchSyncedFile>();
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

    private pruneFileEventsFromDeletedFolderPaths() {
        const deletedFolderPath = this.deletedFolderPaths.shift();
        if (!deletedFolderPath) return false;

        this.eventQueue = this.eventQueue.filter(
            (event) => !event.filePath.startsWith(deletedFolderPath),
        );
        return true;
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

    /**
     * Batch the next run of events with the same action, collection and folder
     * path into a single clubbed event that contains the list of all effected
     * file paths from the individual events.
     */
    private dequeueClubbedEvent(): ClubbedWatchEvent | undefined {
        const event = this.eventQueue.shift();
        if (!event) return undefined;

        const filePaths = [event.filePath];
        while (
            this.eventQueue.length > 0 &&
            event.action === this.eventQueue[0].action &&
            event.folderPath === this.eventQueue[0].folderPath &&
            event.collectionName === this.eventQueue[0].collectionName
        ) {
            filePaths.push(this.eventQueue[0].filePath);
            this.eventQueue.shift();
        }
        return { ...event, filePaths };
    }
}

/** The singleton instance of the {@link FolderWatcher}. */
const watcher = new FolderWatcher();

export default watcher;

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

/**
 * A composite of multiple {@link WatchEvent}s that only differ in their
 * {@link filePath}.
 *
 * When processing events, we combine a run of events with the same
 * {@link action}, {@link folderPath} and {@link collectionName}. This allows us
 * to process all the affected {@link filePaths} in one shot.
 */
type ClubbedWatchEvent = Omit<WatchEvent, "filePath"> & {
    filePaths: string[];
};

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
 */
const deduceEvents = async (watches: FolderWatch[]): Promise<WatchEvent[]> => {
    const electron = ensureElectron();

    const events: WatchEvent[] = [];

    for (const watch of watches) {
        const folderPath = watch.folderPath;

        const paths = (await electron.watch.findFiles(folderPath))
            // Filter out hidden files (files whose names begins with a dot)
            .filter((path) => !isHiddenFile(path));

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

        // Previously synced files that are no longer on disk.
        const pathsToRemove = watch.syncedFiles
            .map((f) => f.path)
            .filter((path) => !paths.includes(path));

        for (const path of pathsToRemove)
            events.push({
                action: "trash",
                folderPath,
                collectionName: collectionNameForPath(path, watch),
                filePath: path,
            });
    }

    return events;
};

const isSyncedOrIgnoredPath = (path: string, watch: FolderWatch) =>
    watch.ignoredFiles.includes(path) ||
    watch.syncedFiles.find((f) => f.path === path);

const collectionNameForPath = (filePath: string, watch: FolderWatch) =>
    watch.collectionMapping == "root"
        ? dirname(watch.folderPath)
        : parentDirectoryName(filePath);

const parentDirectoryName = (path: string) => basename(dirname(path));
