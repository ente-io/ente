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
import { isHiddenFile } from "utils/upload";
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
    /** Pending file system events that we need to process. */
    private eventQueue: WatchEvent[] = [];
    /** The folder watch whose event we're currently processing */
    private activeWatch: FolderWatch | undefined;
    /**
     * If the file system directory corresponding to the (root) folder path of a
     * folder watch is deleted on disk, we note down that in this queue so that
     * we can ignore any file system events that come for it next.
     *
     * TODO: is this really needed? the mappings are pre-checked first.
     */
    private deletedFolderPaths: string[] = [];
    /** `true` if we are using the uploader. */
    private uploadRunning = false;
    /** `true` if we are temporarily paused to let a user upload go through. */
    private isPaused = false;
    private filePathToUploadedFileIDMap = new Map<string, EncryptedEnteFile>();
    private unUploadableFilePaths = new Set<string>();

    /**
     * A function to call when we want to enqueue a new upload of the given list
     * of file paths to the given Ente collection.
     *
     * This is passed as a param to {@link init}.
     */
    private upload: (collectionName: string, filePaths: string[]) => void;
    /**
     * A function to call when we want to sync with the backend.
     *
     * This is passed as a param to {@link init}.
     */
    private syncWithRemote: () => void;

    /** A helper function that debounces invocations of {@link runNextEvent}. */
    private debouncedRunNextEvent: () => void;

    constructor() {
        this.debouncedRunNextEvent = debounce(() => this.runNextEvent(), 1000);
    }

    /**
     * Initialize the watcher and start processing file system events.
     *
     * This is only called when we're running in the context of our desktop app.
     *
     * The caller provides us with the hooks we can use to actually upload the
     * files, and to sync with remote (say after deletion).
     */
    init(
        upload: (collectionName: string, filePaths: string[]) => void,
        syncWithRemote: () => void,
    ) {
        this.upload = upload;
        this.syncWithRemote = syncWithRemote;
        this.registerListeners();
        this.syncWithDisk();
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
        return this.activeWatch?.folderPath == folderPath;
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
        if (this.eventQueue.length == 0 || this.activeWatch || this.isPaused)
            return;

        const skip = (reason: string) => {
            log.info(`Ignoring event since ${reason}`);
            this.debouncedRunNextEvent();
        };

        const event = this.dequeueClubbedEvent();
        log.info(
            `Processing ${event.action} event for folder watch ${event.folderPath} (collectionName ${event.collectionName}, ${event.filePaths.length} files)`,
        );

        const watch = (await this.getWatches()).find(
            (watch) => watch.folderPath == event.folderPath,
        );
        if (!watch) {
            // Possibly stale
            skip(`no folder watch for found for ${event.folderPath}`);
            return;
        }

        if (event.action === "upload") {
            const paths = pathsToUpload(event.filePaths, watch);
            if (paths.length == 0) {
                skip("none of the files need uploading");
                return;
            }

            // Here we pass control to the uploader. When the upload is done,
            // the uploader will notify us by calling allFileUploadsDone.

            this.activeWatch = watch;
            this.uploadRunning = true;

            const collectionName = event.collectionName;
            log.info(
                `Folder watch requested upload of ${paths.length} files to collection ${collectionName}`,
            );

            this.upload(collectionName, paths);
        } else {
            if (this.pruneFileEventsFromDeletedFolderPaths()) {
                skip("event was from a deleted folder path");
                return;
            }

            const paths = pathsToRemove(event.filePaths, watch);

            this.activeWatch = watch;

            await this.trashByIDs(paths);

            const prunedSyncedFiles = watch.syncedFiles.filter(
                ({ path }) => !event.filePaths.includes(path),
            );

            await ensureElectron().watch.updateSyncedFiles(
                prunedSyncedFiles,
                watch.folderPath,
            );

            this.activeWatch = undefined;

            this.debouncedRunNextEvent();
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

    /**
     * Callback invoked by the uploader whenever a file is uploaded.
     */
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

    /**
     * Callback invoked by the uploader whenever a set of file uploads finishes.
     */
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
    collectionName: string;
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

/**
 * Determine which events we need to process to synchronize the watched on-disk
 * folders to their corresponding collections.
 */
const deduceEvents = async (watches: FolderWatch[]): Promise<WatchEvent[]> => {
    const electron = ensureElectron();
    const events: WatchEvent[] = [];

    for (const watch of watches) {
        const folderPath = watch.folderPath;

        const filePaths = await electron.watch.findFiles(folderPath);

        // Files that are on disk but not yet synced.
        for (const filePath of pathsToUpload(filePaths, watch))
            events.push({
                action: "upload",
                folderPath,
                collectionName: collectionNameForPath(filePath, watch),
                filePath,
            });

        // Previously synced files that are no longer on disk.
        for (const filePath of pathsToRemove(filePaths, watch))
            events.push({
                action: "trash",
                folderPath,
                collectionName: collectionNameForPath(filePath, watch),
                filePath,
            });
    }

    return events;
};

/**
 * Filter out hidden files and previously synced or ignored paths from
 * {@link paths} to get the list of paths that need to be uploaded to the Ente
 * collection.
 */
const pathsToUpload = (paths: string[], watch: FolderWatch) =>
    paths
        // Filter out hidden files (files whose names begins with a dot)
        .filter((path) => !isHiddenFile(path))
        // Files that are on disk but not yet synced or ignored.
        .filter((path) => !isSyncedOrIgnoredPath(path, watch));

/**
 * Return the paths to previously synced files that are no longer on disk and so
 * must be removed from the Ente collection.
 */
const pathsToRemove = (paths: string[], watch: FolderWatch) =>
    watch.syncedFiles
        .map((f) => f.path)
        .filter((path) => !paths.includes(path));

const isSyncedOrIgnoredPath = (path: string, watch: FolderWatch) =>
    watch.ignoredFiles.includes(path) ||
    watch.syncedFiles.find((f) => f.path === path);

const collectionNameForPath = (path: string, watch: FolderWatch) =>
    watch.collectionMapping == "root"
        ? dirname(watch.folderPath)
        : parentDirectoryName(path);

const parentDirectoryName = (path: string) => basename(dirname(path));
