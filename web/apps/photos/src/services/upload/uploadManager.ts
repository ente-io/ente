import { FILE_TYPE } from "@/media/file-type";
import { potentialFileTypeFromExtension } from "@/media/live-photo";
import { ensureElectron } from "@/next/electron";
import { lowercaseExtension, nameAndExtension } from "@/next/file";
import log from "@/next/log";
import { ElectronFile, type FileAndPath } from "@/next/types/file";
import type { Electron, ZipEntry } from "@/next/types/ipc";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { ensure } from "@/utils/ensure";
import { getDedicatedCryptoWorker } from "@ente/shared/crypto";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { CustomError } from "@ente/shared/error";
import { Events, eventBus } from "@ente/shared/events";
import { wait } from "@ente/shared/utils";
import { Canceler } from "axios";
import { Remote } from "comlink";
import {
    RANDOM_PERCENTAGE_PROGRESS_FOR_PUT,
    UPLOAD_RESULT,
    UPLOAD_STAGES,
} from "constants/upload";
import isElectron from "is-electron";
import {
    getLocalPublicFiles,
    getPublicCollectionUID,
} from "services/publicCollectionService";
import { getDisableCFUploadProxyFlag } from "services/userService";
import watcher from "services/watch";
import { Collection } from "types/collection";
import { EncryptedEnteFile, EnteFile } from "types/file";
import { SetFiles } from "types/gallery";
import { decryptFile, getUserOwnedFiles, sortFiles } from "utils/file";
import { getLocalFiles } from "../fileService";
import {
    getMetadataJSONMapKeyForJSON,
    tryParseTakeoutMetadataJSON,
    type ParsedMetadataJSON,
} from "./takeout";
import UploadService, {
    uploadItemFileName,
    uploadItemSize,
    uploader,
} from "./uploadService";

export type FileID = number;

export type PercentageUploaded = number;
/* localID => fileName */
export type UploadFileNames = Map<FileID, string>;

export interface UploadCounter {
    finished: number;
    total: number;
}

export interface InProgressUpload {
    localFileID: FileID;
    progress: PercentageUploaded;
}

export interface FinishedUpload {
    localFileID: FileID;
    result: UPLOAD_RESULT;
}

export type InProgressUploads = Map<FileID, PercentageUploaded>;

export type FinishedUploads = Map<FileID, UPLOAD_RESULT>;

export type SegregatedFinishedUploads = Map<UPLOAD_RESULT, FileID[]>;

export interface ProgressUpdater {
    setPercentComplete: React.Dispatch<React.SetStateAction<number>>;
    setUploadCounter: React.Dispatch<React.SetStateAction<UploadCounter>>;
    setUploadStage: React.Dispatch<React.SetStateAction<UPLOAD_STAGES>>;
    setInProgressUploads: React.Dispatch<
        React.SetStateAction<InProgressUpload[]>
    >;
    setFinishedUploads: React.Dispatch<
        React.SetStateAction<SegregatedFinishedUploads>
    >;
    setUploadFilenames: React.Dispatch<React.SetStateAction<UploadFileNames>>;
    setHasLivePhotos: React.Dispatch<React.SetStateAction<boolean>>;
    setUploadProgressView: React.Dispatch<React.SetStateAction<boolean>>;
}

/** The number of uploads to process in parallel. */
const maxConcurrentUploads = 4;

/**
 * An item to upload is one of the following:
 *
 * 1. A file drag-and-dropped or selected by the user when we are running in the
 *    web browser. These is the {@link File} case.
 *
 * 2. A file drag-and-dropped or selected by the user when we are running in the
 *    context of our desktop app. In such cases, we also have the absolute path
 *    of the file in the user's local filesystem. this is the
 *    {@link FileAndPath} case.
 *
 * 3. A file path programmatically requested by the desktop app. For example, we
 *    might be resuming a previously interrupted upload after an app restart
 *    (thus we no longer have access to the {@link File} from case 2). Or we
 *    could be uploading a file this is in one of the folders the user has asked
 *    us to watch for changes. This is the {@link string} case.
 *
 * 4. A file within a zip file. This too is only possible when we are running in
 *    the context of our desktop app. The user might have drag-and-dropped or
 *    selected the zip file, or it might be a zip file that they'd previously
 *    selected but we now are resuming an interrupted upload. Either ways, what
 *    we have is a path to zip file, and the name of an entry within that zip
 *    file. This is the {@link ZipEntry} case.
 */
export type UploadItem = File | FileAndPath | string | ZipEntry;

export interface UploadItemWithCollection {
    localID: number;
    collectionID: number;
    isLivePhoto?: boolean;
    uploadItem?: UploadItem;
    livePhotoAssets?: LivePhotoAssets;
}

export interface LivePhotoAssets {
    image: UploadItem;
    video: UploadItem;
}

export interface PublicUploadProps {
    token: string;
    passwordToken: string;
    accessedThroughSharedURL: boolean;
}

interface UploadCancelStatus {
    value: boolean;
}

class UploadCancelService {
    private shouldUploadBeCancelled: UploadCancelStatus = {
        value: false,
    };

    reset() {
        this.shouldUploadBeCancelled.value = false;
    }

    requestUploadCancelation() {
        this.shouldUploadBeCancelled.value = true;
    }

    isUploadCancelationRequested(): boolean {
        return this.shouldUploadBeCancelled.value;
    }
}

const uploadCancelService = new UploadCancelService();

class UIService {
    private progressUpdater: ProgressUpdater;

    // UPLOAD LEVEL STATES
    private uploadStage: UPLOAD_STAGES = UPLOAD_STAGES.START;
    private filenames: Map<number, string> = new Map();
    private hasLivePhoto: boolean = false;
    private uploadProgressView: boolean = false;

    // STAGE LEVEL STATES
    private perFileProgress: number;
    private filesUploadedCount: number;
    private totalFilesCount: number;
    private inProgressUploads: InProgressUploads = new Map();
    private finishedUploads: FinishedUploads = new Map();

    init(progressUpdater: ProgressUpdater) {
        this.progressUpdater = progressUpdater;
        this.progressUpdater.setUploadStage(this.uploadStage);
        this.progressUpdater.setUploadFilenames(this.filenames);
        this.progressUpdater.setHasLivePhotos(this.hasLivePhoto);
        this.progressUpdater.setUploadProgressView(this.uploadProgressView);
        this.progressUpdater.setUploadCounter({
            finished: this.filesUploadedCount,
            total: this.totalFilesCount,
        });
        this.progressUpdater.setInProgressUploads(
            convertInProgressUploadsToList(this.inProgressUploads),
        );
        this.progressUpdater.setFinishedUploads(
            groupByResult(this.finishedUploads),
        );
    }

    reset(count = 0) {
        this.setTotalFileCount(count);
        this.filesUploadedCount = 0;
        this.inProgressUploads = new Map<number, number>();
        this.finishedUploads = new Map<number, UPLOAD_RESULT>();
        this.updateProgressBarUI();
    }

    setTotalFileCount(count: number) {
        this.totalFilesCount = count;
        if (count > 0) {
            this.perFileProgress = 100 / this.totalFilesCount;
        } else {
            this.perFileProgress = 0;
        }
    }

    setFileProgress(key: number, progress: number) {
        this.inProgressUploads.set(key, progress);
        this.updateProgressBarUI();
    }

    setUploadStage(stage: UPLOAD_STAGES) {
        this.uploadStage = stage;
        this.progressUpdater.setUploadStage(stage);
    }

    setFiles(files: { localID: number; fileName: string }[]) {
        const filenames = new Map(files.map((f) => [f.localID, f.fileName]));
        this.filenames = filenames;
        this.progressUpdater.setUploadFilenames(filenames);
    }

    setHasLivePhoto(hasLivePhoto: boolean) {
        this.hasLivePhoto = hasLivePhoto;
        this.progressUpdater.setHasLivePhotos(hasLivePhoto);
    }

    setUploadProgressView(uploadProgressView: boolean) {
        this.uploadProgressView = uploadProgressView;
        this.progressUpdater.setUploadProgressView(uploadProgressView);
    }

    increaseFileUploaded() {
        this.filesUploadedCount++;
        this.updateProgressBarUI();
    }

    moveFileToResultList(key: number, uploadResult: UPLOAD_RESULT) {
        this.finishedUploads.set(key, uploadResult);
        this.inProgressUploads.delete(key);
        this.updateProgressBarUI();
    }

    hasFilesInResultList() {
        return this.finishedUploads.size > 0;
    }

    private updateProgressBarUI() {
        const {
            setPercentComplete,
            setUploadCounter,
            setInProgressUploads,
            setFinishedUploads,
        } = this.progressUpdater;
        setUploadCounter({
            finished: this.filesUploadedCount,
            total: this.totalFilesCount,
        });
        let percentComplete =
            this.perFileProgress *
            (this.finishedUploads.size || this.filesUploadedCount);
        if (this.inProgressUploads) {
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            for (const [_, progress] of this.inProgressUploads) {
                // filter  negative indicator values during percentComplete calculation
                if (progress < 0) {
                    continue;
                }
                percentComplete += (this.perFileProgress * progress) / 100;
            }
        }

        setPercentComplete(percentComplete);
        setInProgressUploads(
            convertInProgressUploadsToList(this.inProgressUploads),
        );
        setFinishedUploads(groupByResult(this.finishedUploads));
    }

    trackUploadProgress(
        fileLocalID: number,
        percentPerPart = RANDOM_PERCENTAGE_PROGRESS_FOR_PUT(),
        index = 0,
    ) {
        const cancel: { exec: Canceler } = { exec: () => {} };
        const cancelTimedOutRequest = () =>
            cancel.exec(CustomError.REQUEST_TIMEOUT);

        const cancelCancelledUploadRequest = () =>
            cancel.exec(CustomError.UPLOAD_CANCELLED);

        let timeout = null;
        const resetTimeout = () => {
            if (timeout) {
                clearTimeout(timeout);
            }
            timeout = setTimeout(cancelTimedOutRequest, 30 * 1000 /* 30 sec */);
        };
        return {
            cancel,
            onUploadProgress: (event) => {
                this.inProgressUploads.set(
                    fileLocalID,
                    Math.min(
                        Math.round(
                            percentPerPart * index +
                                (percentPerPart * event.loaded) / event.total,
                        ),
                        98,
                    ),
                );
                this.updateProgressBarUI();
                if (event.loaded === event.total) {
                    clearTimeout(timeout);
                } else {
                    resetTimeout();
                }
                if (uploadCancelService.isUploadCancelationRequested()) {
                    cancelCancelledUploadRequest();
                }
            },
        };
    }
}

function convertInProgressUploadsToList(inProgressUploads) {
    return [...inProgressUploads.entries()].map(
        ([localFileID, progress]) =>
            ({
                localFileID,
                progress,
            }) as InProgressUpload,
    );
}

const groupByResult = (finishedUploads: FinishedUploads) => {
    const groups: SegregatedFinishedUploads = new Map();
    for (const [localID, result] of finishedUploads) {
        if (!groups.has(result)) groups.set(result, []);
        groups.get(result).push(localID);
    }
    return groups;
};

class UploadManager {
    private cryptoWorkers = new Array<
        ComlinkWorker<typeof DedicatedCryptoWorker>
    >(maxConcurrentUploads);
    private parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>;
    private filesToBeUploaded: ClusteredUploadItem[];
    private remainingFiles: ClusteredUploadItem[] = [];
    private failedFiles: ClusteredUploadItem[];
    private existingFiles: EnteFile[];
    private setFiles: SetFiles;
    private collections: Map<number, Collection>;
    private uploadInProgress: boolean;
    private publicUploadProps: PublicUploadProps;
    private uploaderName: string;
    private uiService: UIService;
    private isCFUploadProxyDisabled: boolean = false;

    constructor() {
        this.uiService = new UIService();
    }

    public async init(
        progressUpdater: ProgressUpdater,
        setFiles: SetFiles,
        publicCollectProps: PublicUploadProps,
        isCFUploadProxyDisabled: boolean,
    ) {
        this.uiService.init(progressUpdater);
        const remoteIsCFUploadProxyDisabled =
            await getDisableCFUploadProxyFlag();
        if (remoteIsCFUploadProxyDisabled) {
            isCFUploadProxyDisabled = remoteIsCFUploadProxyDisabled;
        }
        this.isCFUploadProxyDisabled = isCFUploadProxyDisabled;
        UploadService.init(publicCollectProps);
        this.setFiles = setFiles;
        this.publicUploadProps = publicCollectProps;
    }

    public isUploadRunning() {
        return this.uploadInProgress;
    }

    private resetState() {
        this.filesToBeUploaded = [];
        this.remainingFiles = [];
        this.failedFiles = [];
        this.parsedMetadataJSONMap = new Map<string, ParsedMetadataJSON>();

        this.uploaderName = null;
    }

    public prepareForNewUpload() {
        this.resetState();
        this.uiService.reset();
        uploadCancelService.reset();
        this.uiService.setUploadStage(UPLOAD_STAGES.START);
    }

    showUploadProgressDialog() {
        this.uiService.setUploadProgressView(true);
    }

    /**
     * Upload files
     *
     * This method waits for all the files to get uploaded (successfully or
     * unsucessfully) before returning.
     *
     * It is an error to call this method when there is already an in-progress
     * upload.
     *
     * @param itemsWithCollection The items to upload, each paired with the id
     * of the collection that they should be uploaded into.
     *
     * @returns `true` if at least one file was processed
     */
    public async uploadItems(
        itemsWithCollection: UploadItemWithCollection[],
        collections: Collection[],
        uploaderName?: string,
    ) {
        if (this.uploadInProgress)
            throw new Error("Cannot run multiple uploads at once");

        log.info(`Uploading ${itemsWithCollection.length} files`);
        this.uploadInProgress = true;
        this.uploaderName = uploaderName;

        try {
            await this.updateExistingFilesAndCollections(collections);

            const namedFiles = itemsWithCollection.map(
                makeUploadItemWithCollectionIDAndName,
            );

            this.uiService.setFiles(namedFiles);

            const [metadataFiles, mediaFiles] =
                splitMetadataAndMediaFiles(namedFiles);

            if (metadataFiles.length) {
                this.uiService.setUploadStage(
                    UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES,
                );

                await this.parseMetadataJSONFiles(metadataFiles);
            }

            if (mediaFiles.length) {
                const clusteredMediaFiles = await clusterLivePhotos(mediaFiles);

                this.abortIfCancelled();

                // Live photos might've been clustered together, reset the list
                // of files to reflect that.
                this.uiService.setFiles(clusteredMediaFiles);

                this.uiService.setHasLivePhoto(
                    mediaFiles.length != clusteredMediaFiles.length,
                );

                await this.uploadMediaFiles(clusteredMediaFiles);
            }
        } catch (e) {
            if (e.message === CustomError.UPLOAD_CANCELLED) {
                if (isElectron()) {
                    this.remainingFiles = [];
                    await cancelRemainingUploads();
                }
            } else {
                log.error("Uploading failed", e);
                throw e;
            }
        } finally {
            this.uiService.setUploadStage(UPLOAD_STAGES.FINISH);
            for (let i = 0; i < maxConcurrentUploads; i++) {
                this.cryptoWorkers[i]?.terminate();
            }
            this.uploadInProgress = false;
        }

        return this.uiService.hasFilesInResultList();
    }

    private abortIfCancelled = () => {
        if (uploadCancelService.isUploadCancelationRequested()) {
            throw Error(CustomError.UPLOAD_CANCELLED);
        }
    };

    private async updateExistingFilesAndCollections(collections: Collection[]) {
        if (this.publicUploadProps.accessedThroughSharedURL) {
            this.existingFiles = await getLocalPublicFiles(
                getPublicCollectionUID(this.publicUploadProps.token),
            );
        } else {
            this.existingFiles = getUserOwnedFiles(await getLocalFiles());
        }
        this.collections = new Map(
            collections.map((collection) => [collection.id, collection]),
        );
    }

    private async parseMetadataJSONFiles(
        files: UploadItemWithCollectionIDAndName[],
    ) {
        this.uiService.reset(files.length);

        for (const {
            uploadItem: fileOrPath,
            fileName,
            collectionID,
        } of files) {
            this.abortIfCancelled();

            log.info(`Parsing metadata JSON ${fileName}`);
            const metadataJSON = await tryParseTakeoutMetadataJSON(fileOrPath);
            if (metadataJSON) {
                this.parsedMetadataJSONMap.set(
                    getMetadataJSONMapKeyForJSON(collectionID, fileName),
                    metadataJSON,
                );
                this.uiService.increaseFileUploaded();
            }
        }
    }

    private async uploadMediaFiles(mediaFiles: ClusteredUploadItem[]) {
        this.filesToBeUploaded = [...this.filesToBeUploaded, ...mediaFiles];

        if (isElectron()) {
            this.remainingFiles = [...this.remainingFiles, ...mediaFiles];
        }

        this.uiService.reset(mediaFiles.length);

        await UploadService.setFileCount(mediaFiles.length);

        this.uiService.setUploadStage(UPLOAD_STAGES.UPLOADING);

        const uploadProcesses = [];
        for (
            let i = 0;
            i < maxConcurrentUploads && this.filesToBeUploaded.length > 0;
            i++
        ) {
            this.cryptoWorkers[i] = getDedicatedCryptoWorker();
            const worker = await this.cryptoWorkers[i].remote;
            uploadProcesses.push(this.uploadNextFileInQueue(worker));
        }
        await Promise.all(uploadProcesses);
    }

    private async uploadNextFileInQueue(worker: Remote<DedicatedCryptoWorker>) {
        const uiService = this.uiService;

        while (this.filesToBeUploaded.length > 0) {
            this.abortIfCancelled();

            const clusteredFile = this.filesToBeUploaded.pop();
            const { localID, collectionID } = clusteredFile;
            const collection = this.collections.get(collectionID);
            const uploadableFile = { ...clusteredFile, collection };

            uiService.setFileProgress(localID, 0);
            await wait(0);

            const { uploadResult, uploadedFile } = await uploader(
                uploadableFile,
                this.uploaderName,
                this.existingFiles,
                this.parsedMetadataJSONMap,
                worker,
                this.isCFUploadProxyDisabled,
                () => {
                    this.abortIfCancelled();
                },
                (
                    fileLocalID: number,
                    percentPerPart?: number,
                    index?: number,
                ) =>
                    uiService.trackUploadProgress(
                        fileLocalID,
                        percentPerPart,
                        index,
                    ),
            );

            const finalUploadResult = await this.postUploadTask(
                uploadableFile,
                uploadResult,
                uploadedFile,
            );

            this.uiService.moveFileToResultList(localID, finalUploadResult);
            this.uiService.increaseFileUploaded();
            UploadService.reducePendingUploadCount();
        }
    }

    private async postUploadTask(
        uploadableFile: UploadableUploadItem,
        uploadResult: UPLOAD_RESULT,
        uploadedFile: EncryptedEnteFile | EnteFile | undefined,
    ) {
        log.info(
            `Uploaded ${uploadableFile.fileName} with result ${uploadResult}`,
        );
        try {
            let decryptedFile: EnteFile;
            await this.removeFromPendingUploads(uploadableFile);
            switch (uploadResult) {
                case UPLOAD_RESULT.FAILED:
                case UPLOAD_RESULT.BLOCKED:
                    this.failedFiles.push(uploadableFile);
                    break;
                case UPLOAD_RESULT.ALREADY_UPLOADED:
                    decryptedFile = uploadedFile as EnteFile;
                    break;
                case UPLOAD_RESULT.ADDED_SYMLINK:
                    decryptedFile = uploadedFile as EnteFile;
                    uploadResult = UPLOAD_RESULT.UPLOADED;
                    break;
                case UPLOAD_RESULT.UPLOADED:
                case UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL:
                    decryptedFile = await decryptFile(
                        uploadedFile as EncryptedEnteFile,
                        uploadableFile.collection.key,
                    );
                    break;
                case UPLOAD_RESULT.UNSUPPORTED:
                case UPLOAD_RESULT.TOO_LARGE:
                    // no-op
                    break;
                default:
                    throw new Error(`Invalid Upload Result ${uploadResult}`);
            }
            if (
                [
                    UPLOAD_RESULT.ADDED_SYMLINK,
                    UPLOAD_RESULT.UPLOADED,
                    UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL,
                ].includes(uploadResult)
            ) {
                try {
                    eventBus.emit(Events.FILE_UPLOADED, {
                        enteFile: decryptedFile,
                        localFile:
                            uploadableFile.uploadItem ??
                            uploadableFile.livePhotoAssets.image,
                    });
                } catch (e) {
                    log.warn("Ignoring error in fileUploaded handlers", e);
                }
                this.updateExistingFiles(decryptedFile);
            }
            await this.watchFolderCallback(
                uploadResult,
                uploadableFile,
                uploadedFile as EncryptedEnteFile,
            );
            return uploadResult;
        } catch (e) {
            log.error("failed to do post file upload action", e);
            return UPLOAD_RESULT.FAILED;
        }
    }

    private async watchFolderCallback(
        fileUploadResult: UPLOAD_RESULT,
        fileWithCollection: ClusteredUploadItem,
        uploadedFile: EncryptedEnteFile,
    ) {
        if (isElectron()) {
            if (watcher.isUploadRunning()) {
                await watcher.onFileUpload(
                    fileUploadResult,
                    fileWithCollection,
                    uploadedFile,
                );
            }
        }
    }

    public cancelRunningUpload() {
        log.info("User cancelled running upload");
        this.uiService.setUploadStage(UPLOAD_STAGES.CANCELLING);
        uploadCancelService.requestUploadCancelation();
    }

    public getFailedItemsWithCollections() {
        return {
            items: this.failedFiles,
            collections: [...this.collections.values()],
        };
    }

    public getUploaderName() {
        return this.uploaderName;
    }

    private updateExistingFiles(decryptedFile: EnteFile) {
        if (!decryptedFile) {
            throw Error("decrypted file can't be undefined");
        }
        this.existingFiles.push(decryptedFile);
        this.updateUIFiles(decryptedFile);
    }

    private updateUIFiles(decryptedFile: EnteFile) {
        this.setFiles((files) => sortFiles([...files, decryptedFile]));
    }

    private async removeFromPendingUploads(
        clusteredUploadItem: ClusteredUploadItem,
    ) {
        const electron = globalThis.electron;
        if (electron) {
            this.remainingFiles = this.remainingFiles.filter(
                (f) => f.localID != clusteredUploadItem.localID,
            );
            await markUploaded(electron, clusteredUploadItem);
        }
    }

    public shouldAllowNewUpload = () => {
        return !this.uploadInProgress || watcher.isUploadRunning();
    };
}

export default new UploadManager();

/**
 * The data operated on by the intermediate stages of the upload.
 *
 * [Note: Intermediate file types during upload]
 *
 * As files progress through stages, they get more and more bits tacked on to
 * them. These types document the journey.
 *
 * - The input is {@link UploadItemWithCollection}. This can either be a new
 *   {@link UploadItemWithCollection}, in which case it'll only have a
 *   {@link localID}, {@link collectionID} and a {@link uploadItem}. Or it could
 *   be a retry, in which case it'll not have a {@link uploadItem} but instead
 *   will have data from a previous stage (concretely, it'll just be a
 *   relabelled {@link ClusteredUploadItem}), like a snake eating its tail.
 *
 * - Immediately we convert it to {@link UploadItemWithCollectionIDAndName}.
 *   This is to mostly systematize what we have, and also attach a
 *   {@link fileName}.
 *
 * - These then get converted to "assets", whereby both parts of a live photo
 *   are combined. This is a {@link ClusteredUploadItem}.
 *
 * - On to the {@link ClusteredUploadItem} we attach the corresponding
 *   {@link collection}, giving us {@link UploadableUploadItem}. This is what
 *   gets queued and then passed to the {@link uploader}.
 */
type UploadItemWithCollectionIDAndName = {
    /** A unique ID for the duration of the upload */
    localID: number;
    /** The ID of the collection to which this file should be uploaded. */
    collectionID: number;
    /**
     * The name of the file.
     *
     * In case of live photos, this'll be the name of the image part.
     */
    fileName: string;
    /** `true` if this is a live photo. */
    isLivePhoto?: boolean;
    /* Valid for non-live photos */
    uploadItem?: UploadItem;
    /* Valid for live photos */
    livePhotoAssets?: LivePhotoAssets;
};

const makeUploadItemWithCollectionIDAndName = (
    f: UploadItemWithCollection,
): UploadItemWithCollectionIDAndName => ({
    localID: ensure(f.localID),
    collectionID: ensure(f.collectionID),
    fileName: ensure(
        f.isLivePhoto
            ? uploadItemFileName(f.livePhotoAssets.image)
            : uploadItemFileName(f.uploadItem),
    ),
    isLivePhoto: f.isLivePhoto,
    uploadItem: f.uploadItem,
    livePhotoAssets: f.livePhotoAssets,
});

/**
 * An upload item with both parts of a live photo clubbed together.
 *
 * See: [Note: Intermediate file types during upload].
 */
type ClusteredUploadItem = {
    localID: number;
    collectionID: number;
    fileName: string;
    isLivePhoto: boolean;
    uploadItem?: UploadItem;
    livePhotoAssets?: LivePhotoAssets;
};

/**
 * The file that we hand off to the uploader. Essentially
 * {@link ClusteredUploadItem} with the {@link collection} attached to it.
 *
 * See: [Note: Intermediate file types during upload].
 */
export type UploadableUploadItem = ClusteredUploadItem & {
    collection: Collection;
};

const splitMetadataAndMediaFiles = (
    items: UploadItemWithCollectionIDAndName[],
): [
    metadata: UploadItemWithCollectionIDAndName[],
    media: UploadItemWithCollectionIDAndName[],
] =>
    items.reduce(
        ([metadata, media], f) => {
            if (lowercaseExtension(f.fileName) == "json") metadata.push(f);
            else media.push(f);
            return [metadata, media];
        },
        [[], []],
    );

const markUploaded = async (electron: Electron, item: ClusteredUploadItem) => {
    // TODO: This can be done better
    if (item.isLivePhoto) {
        const [p0, p1] = [
            item.livePhotoAssets.image,
            item.livePhotoAssets.video,
        ];
        if (Array.isArray(p0) && Array.isArray(p1)) {
            electron.markUploadedZipEntries([p0, p1]);
        } else if (typeof p0 == "string" && typeof p1 == "string") {
            electron.markUploadedFiles([p0, p1]);
        } else if (
            p0 &&
            typeof p0 == "object" &&
            "path" in p0 &&
            p1 &&
            typeof p1 == "object" &&
            "path" in p1
        ) {
            electron.markUploadedFiles([p0.path, p1.path]);
        } else {
            throw new Error(
                "Attempting to mark upload completion of unexpected desktop upload items",
            );
        }
    } else {
        const p = ensure(item.uploadItem);
        if (Array.isArray(p)) {
            electron.markUploadedZipEntries([p]);
        } else if (typeof p == "string") {
            electron.markUploadedFiles([p]);
        } else if (p && typeof p == "object" && "path" in p) {
            electron.markUploadedFiles([p]);
        } else {
            throw new Error(
                "Attempting to mark upload completion of unexpected desktop upload items",
            );
        }
    }
};

/**
 * NOTE: a stop gap measure, only meant to be called by code that is running in
 * the context of a desktop app initiated upload
 */
export const getFilePathElectron = (file: File | ElectronFile | string) =>
    typeof file == "string" ? file : (file as ElectronFile).path;

const cancelRemainingUploads = () => ensureElectron().clearPendingUploads();

/**
 * Go through the given files, combining any sibling image + video assets into a
 * single live photo when appropriate.
 */
const clusterLivePhotos = async (
    files: UploadItemWithCollectionIDAndName[],
) => {
    const result: ClusteredUploadItem[] = [];
    files
        .sort((f, g) =>
            nameAndExtension(f.fileName)[0].localeCompare(
                nameAndExtension(g.fileName)[0],
            ),
        )
        .sort((f, g) => f.collectionID - g.collectionID);
    let index = 0;
    while (index < files.length - 1) {
        const f = files[index];
        const g = files[index + 1];
        const fFileType = potentialFileTypeFromExtension(f.fileName);
        const gFileType = potentialFileTypeFromExtension(g.fileName);
        const fa: PotentialLivePhotoAsset = {
            fileName: f.fileName,
            fileType: fFileType,
            collectionID: f.collectionID,
            fileOrPath: f.uploadItem,
        };
        const ga: PotentialLivePhotoAsset = {
            fileName: g.fileName,
            fileType: gFileType,
            collectionID: g.collectionID,
            fileOrPath: g.uploadItem,
        };
        if (await areLivePhotoAssets(fa, ga)) {
            const [image, video] =
                fFileType == FILE_TYPE.IMAGE ? [f, g] : [g, f];
            result.push({
                localID: f.localID,
                collectionID: f.collectionID,
                fileName: image.fileName,
                isLivePhoto: true,
                livePhotoAssets: {
                    image: image.uploadItem,
                    video: video.uploadItem,
                },
            });
            index += 2;
        } else {
            result.push({
                ...f,
                isLivePhoto: false,
            });
            index += 1;
        }
    }
    if (index === files.length - 1) {
        result.push({
            ...files[index],
            isLivePhoto: false,
        });
    }
    return result;
};

interface PotentialLivePhotoAsset {
    fileName: string;
    fileType: FILE_TYPE;
    collectionID: number;
    fileOrPath: File | string;
}

const areLivePhotoAssets = async (
    f: PotentialLivePhotoAsset,
    g: PotentialLivePhotoAsset,
) => {
    if (f.collectionID != g.collectionID) return false;

    const [fName, fExt] = nameAndExtension(f.fileName);
    const [gName, gExt] = nameAndExtension(g.fileName);

    let fPrunedName: string;
    let gPrunedName: string;
    if (f.fileType == FILE_TYPE.IMAGE && g.fileType == FILE_TYPE.VIDEO) {
        fPrunedName = removePotentialLivePhotoSuffix(
            fName,
            // A Google Live Photo image file can have video extension appended
            // as suffix, so we pass that to removePotentialLivePhotoSuffix to
            // remove it.
            //
            // Example: IMG_20210630_0001.mp4.jpg (Google Live Photo image file)
            gExt ? `.${gExt}` : undefined,
        );
        gPrunedName = removePotentialLivePhotoSuffix(gName);
    } else if (f.fileType == FILE_TYPE.VIDEO && g.fileType == FILE_TYPE.IMAGE) {
        fPrunedName = removePotentialLivePhotoSuffix(fName);
        gPrunedName = removePotentialLivePhotoSuffix(
            gName,
            fExt ? `.${fExt}` : undefined,
        );
    } else {
        return false;
    }

    if (fPrunedName != gPrunedName) return false;

    // Also check that the size of an individual Live Photo asset is less than
    // an (arbitrary) limit. This should be true in practice as the videos for a
    // live photo are a few seconds long. Further on, the zipping library that
    // we use doesn't support stream as a input.

    const maxAssetSize = 20 * 1024 * 1024; /* 20MB */
    const fSize = await uploadItemSize(f.fileOrPath);
    const gSize = await uploadItemSize(g.fileOrPath);
    if (fSize > maxAssetSize || gSize > maxAssetSize) {
        log.info(
            `Not classifying assets with too large sizes ${[fSize, gSize]} as a live photo`,
        );
        return false;
    }

    return true;
};

const removePotentialLivePhotoSuffix = (name: string, suffix?: string) => {
    const suffix_3 = "_3";

    // The icloud-photos-downloader library appends _HVEC to the end of the
    // filename in case of live photos.
    //
    // https://github.com/icloud-photos-downloader/icloud_photos_downloader
    const suffix_hvec = "_HVEC";

    let foundSuffix: string | undefined;
    if (name.endsWith(suffix_3)) {
        foundSuffix = suffix_3;
    } else if (
        name.endsWith(suffix_hvec) ||
        name.endsWith(suffix_hvec.toLowerCase())
    ) {
        foundSuffix = suffix_hvec;
    } else if (suffix) {
        if (name.endsWith(suffix) || name.endsWith(suffix.toLowerCase())) {
            foundSuffix = suffix;
        }
    }

    return foundSuffix ? name.slice(0, foundSuffix.length * -1) : name;
};
