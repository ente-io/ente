import { FILE_TYPE } from "@/media/file-type";
import { potentialFileTypeFromExtension } from "@/media/live-photo";
import { ensureElectron } from "@/next/electron";
import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import { ElectronFile } from "@/next/types/file";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
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
import {
    FileWithCollection,
    PublicUploadProps,
    type FileWithCollection2,
    type LivePhotoAssets2,
} from "types/upload";
import {
    FinishedUploads,
    InProgressUpload,
    InProgressUploads,
    ProgressUpdater,
    SegregatedFinishedUploads,
} from "types/upload/ui";
import { decryptFile, getUserOwnedFiles, sortFiles } from "utils/file";
import { segregateMetadataAndMediaFiles } from "utils/upload";
import { getLocalFiles } from "../fileService";
import {
    getMetadataJSONMapKeyForJSON,
    tryParseTakeoutMetadataJSON,
    type ParsedMetadataJSON,
} from "./takeout";
import UploadService, {
    assetName,
    getAssetName,
    getFileName,
    uploader,
} from "./uploadService";

/** The number of uploads to process in parallel. */
const maxConcurrentUploads = 4;

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
            segregatedFinishedUploadsToList(this.finishedUploads),
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

    setFilenames(filenames: Map<number, string>) {
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
        const finishedUploadsList = segregatedFinishedUploadsToList(
            this.finishedUploads,
        );
        for (const x of finishedUploadsList.values()) {
            if (x.length > 0) {
                return true;
            }
        }
        return false;
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
        setFinishedUploads(
            segregatedFinishedUploadsToList(this.finishedUploads),
        );
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

function segregatedFinishedUploadsToList(finishedUploads: FinishedUploads) {
    const segregatedFinishedUploads = new Map() as SegregatedFinishedUploads;
    for (const [localID, result] of finishedUploads) {
        if (!segregatedFinishedUploads.has(result)) {
            segregatedFinishedUploads.set(result, []);
        }
        segregatedFinishedUploads.get(result).push(localID);
    }
    return segregatedFinishedUploads;
}

class UploadManager {
    private cryptoWorkers = new Array<
        ComlinkWorker<typeof DedicatedCryptoWorker>
    >(maxConcurrentUploads);
    private parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>;
    private filesToBeUploaded: FileWithCollection2[];
    private remainingFiles: FileWithCollection2[] = [];
    private failedFiles: FileWithCollection2[];
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

    prepareForNewUpload() {
        this.resetState();
        this.uiService.reset();
        uploadCancelService.reset();
        this.uiService.setUploadStage(UPLOAD_STAGES.START);
    }

    showUploadProgressDialog() {
        this.uiService.setUploadProgressView(true);
    }

    async updateExistingFilesAndCollections(collections: Collection[]) {
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

    public async queueFilesForUpload(
        filesWithCollectionToUploadIn: FileWithCollection[],
        collections: Collection[],
        uploaderName?: string,
    ) {
        try {
            if (this.uploadInProgress) {
                throw Error("can't run multiple uploads at once");
            }
            this.uploadInProgress = true;
            await this.updateExistingFilesAndCollections(collections);
            this.uploaderName = uploaderName;
            log.info(
                `received ${filesWithCollectionToUploadIn.length} files to upload`,
            );
            this.uiService.setFilenames(
                new Map<number, string>(
                    filesWithCollectionToUploadIn.map((mediaFile) => [
                        mediaFile.localID,
                        getAssetName(mediaFile),
                    ]),
                ),
            );
            const { metadataJSONFiles, mediaFiles } =
                segregateMetadataAndMediaFiles(filesWithCollectionToUploadIn);
            log.info(`has ${metadataJSONFiles.length} metadata json files`);
            log.info(`has ${mediaFiles.length} media files`);
            if (metadataJSONFiles.length) {
                this.uiService.setUploadStage(
                    UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES,
                );
                /* TODO(MR): ElectronFile changes */
                await this.parseMetadataJSONFiles(
                    metadataJSONFiles as FileWithCollection2[],
                );
            }

            if (mediaFiles.length) {
                /* TODO(MR): ElectronFile changes */
                const clusteredMediaFiles = clusterLivePhotos(
                    mediaFiles as ClusterableFile[],
                );

                if (uploadCancelService.isUploadCancelationRequested()) {
                    throw Error(CustomError.UPLOAD_CANCELLED);
                }

                this.uiService.setFilenames(
                    new Map<number, string>(
                        clusteredMediaFiles.map((mediaFile) => [
                            mediaFile.localID,
                            /* TODO(MR): ElectronFile changes */
                            assetName(mediaFile as FileWithCollection2),
                        ]),
                    ),
                );

                this.uiService.setHasLivePhoto(
                    mediaFiles.length !== clusteredMediaFiles.length,
                );

                /* TODO(MR): ElectronFile changes */
                await this.uploadMediaFiles(
                    clusteredMediaFiles as FileWithCollection2[],
                );
            }
        } catch (e) {
            if (e.message === CustomError.UPLOAD_CANCELLED) {
                if (isElectron()) {
                    this.remainingFiles = [];
                    await cancelRemainingUploads();
                }
            } else {
                log.error("uploading failed with error", e);
                throw e;
            }
        } finally {
            this.uiService.setUploadStage(UPLOAD_STAGES.FINISH);
            for (let i = 0; i < maxConcurrentUploads; i++) {
                this.cryptoWorkers[i]?.terminate();
            }
            this.uploadInProgress = false;
        }
        try {
            if (!this.uiService.hasFilesInResultList()) {
                return true;
            } else {
                return false;
            }
        } catch (e) {
            log.error(" failed to return shouldCloseProgressBar", e);
            return false;
        }
    }

    private abortIfCancelled = () => {
        if (uploadCancelService.isUploadCancelationRequested()) {
            throw Error(CustomError.UPLOAD_CANCELLED);
        }
    };

    private async parseMetadataJSONFiles(metadataFiles: FileWithCollection2[]) {
        try {
            log.info(`parseMetadataJSONFiles function executed `);

            this.uiService.reset(metadataFiles.length);

            for (const { file, collectionID } of metadataFiles) {
                this.abortIfCancelled();
                const name = getFileName(file);
                try {
                    log.info(`parsing metadata json file ${name}`);

                    const metadataJSON =
                        await tryParseTakeoutMetadataJSON(file);
                    if (metadataJSON) {
                        this.parsedMetadataJSONMap.set(
                            getMetadataJSONMapKeyForJSON(collectionID, name),
                            metadataJSON && { ...metadataJSON },
                        );
                        this.uiService.increaseFileUploaded();
                    }
                    log.info(`successfully parsed metadata json file ${name}`);
                } catch (e) {
                    if (e.message === CustomError.UPLOAD_CANCELLED) {
                        throw e;
                    } else {
                        // and don't break for subsequent files just log and move on
                        log.error("parsing failed for a file", e);
                        log.info(
                            `failed to parse metadata json file ${name} error: ${e.message}`,
                        );
                    }
                }
            }
        } catch (e) {
            if (e.message !== CustomError.UPLOAD_CANCELLED) {
                log.error("error seeding MetadataMap", e);
            }
            throw e;
        }
    }

    private async uploadMediaFiles(mediaFiles: FileWithCollection2[]) {
        log.info(`uploadMediaFiles called`);
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
            if (uploadCancelService.isUploadCancelationRequested()) {
                throw Error(CustomError.UPLOAD_CANCELLED);
            }
            let fileWithCollection = this.filesToBeUploaded.pop();
            const { collectionID } = fileWithCollection;
            const collection = this.collections.get(collectionID);
            fileWithCollection = { ...fileWithCollection, collection };

            uiService.setFileProgress(fileWithCollection.localID, 0);
            await wait(0);

            const { fileUploadResult, uploadedFile } = await uploader(
                worker,
                this.existingFiles,
                fileWithCollection,
                this.parsedMetadataJSONMap,
                this.uploaderName,
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
                fileUploadResult,
                uploadedFile,
                fileWithCollection,
            );

            this.uiService.moveFileToResultList(
                fileWithCollection.localID,
                finalUploadResult,
            );
            this.uiService.increaseFileUploaded();
            UploadService.reducePendingUploadCount();
        }
    }

    async postUploadTask(
        fileUploadResult: UPLOAD_RESULT,
        uploadedFile: EncryptedEnteFile | EnteFile | null,
        fileWithCollection: FileWithCollection2,
    ) {
        try {
            let decryptedFile: EnteFile;
            log.info(
                `post upload action -> fileUploadResult: ${fileUploadResult} uploadedFile present ${!!uploadedFile}`,
            );
            await this.removeFromPendingUploads(fileWithCollection);
            switch (fileUploadResult) {
                case UPLOAD_RESULT.FAILED:
                case UPLOAD_RESULT.BLOCKED:
                    this.failedFiles.push(fileWithCollection);
                    break;
                case UPLOAD_RESULT.ALREADY_UPLOADED:
                    decryptedFile = uploadedFile as EnteFile;
                    break;
                case UPLOAD_RESULT.ADDED_SYMLINK:
                    decryptedFile = uploadedFile as EnteFile;
                    fileUploadResult = UPLOAD_RESULT.UPLOADED;
                    break;
                case UPLOAD_RESULT.UPLOADED:
                case UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL:
                    decryptedFile = await decryptFile(
                        uploadedFile as EncryptedEnteFile,
                        fileWithCollection.collection.key,
                    );
                    break;
                case UPLOAD_RESULT.UNSUPPORTED:
                case UPLOAD_RESULT.TOO_LARGE:
                    // no-op
                    break;
                default:
                    throw Error("Invalid Upload Result" + fileUploadResult);
            }
            if (
                [
                    UPLOAD_RESULT.ADDED_SYMLINK,
                    UPLOAD_RESULT.UPLOADED,
                    UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL,
                ].includes(fileUploadResult)
            ) {
                try {
                    eventBus.emit(Events.FILE_UPLOADED, {
                        enteFile: decryptedFile,
                        localFile:
                            fileWithCollection.file ??
                            fileWithCollection.livePhotoAssets.image,
                    });
                } catch (e) {
                    log.error("Error in fileUploaded handlers", e);
                }
                this.updateExistingFiles(decryptedFile);
            }
            await this.watchFolderCallback(
                fileUploadResult,
                fileWithCollection,
                uploadedFile as EncryptedEnteFile,
            );
            return fileUploadResult;
        } catch (e) {
            log.error("failed to do post file upload action", e);
            return UPLOAD_RESULT.FAILED;
        }
    }

    private async watchFolderCallback(
        fileUploadResult: UPLOAD_RESULT,
        fileWithCollection: FileWithCollection2,
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
        log.info("user cancelled running upload");
        this.uiService.setUploadStage(UPLOAD_STAGES.CANCELLING);
        uploadCancelService.requestUploadCancelation();
    }

    getFailedFilesWithCollections() {
        return {
            files: this.failedFiles,
            collections: [...this.collections.values()],
        };
    }

    getUploaderName() {
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

    private async removeFromPendingUploads(file: FileWithCollection2) {
        if (isElectron()) {
            this.remainingFiles = this.remainingFiles.filter(
                (f) => f.localID != file.localID,
            );
            await updatePendingUploads(this.remainingFiles);
        }
    }

    public shouldAllowNewUpload = () => {
        return !this.uploadInProgress || watcher.isUploadRunning();
    };
}

export default new UploadManager();

export const setToUploadCollection = async (collections: Collection[]) => {
    let collectionName: string = null;
    /* collection being one suggest one of two things
                1. Either the user has upload to a single existing collection
                2. Created a new single collection to upload to
                    may have had multiple folder, but chose to upload
                    to one album
                hence saving the collection name when upload collection count is 1
                helps the info of user choosing this options
                and on next upload we can directly start uploading to this collection
            */
    if (collections.length === 1) {
        collectionName = collections[0].name;
    }
    await ensureElectron().setPendingUploadCollection(collectionName);
};

const updatePendingUploads = async (files: FileWithCollection2[]) => {
    const paths = files
        .map((file) =>
            file.isLivePhoto
                ? [file.livePhotoAssets.image, file.livePhotoAssets.video]
                : [file.file],
        )
        .flat()
        .map((f) => getFilePathElectron(f));
    await ensureElectron().setPendingUploadFiles("files", paths);
};

/**
 * NOTE: a stop gap measure, only meant to be called by code that is running in
 * the context of a desktop app initiated upload
 */
export const getFilePathElectron = (file: File | ElectronFile | string) =>
    typeof file == "string" ? file : (file as ElectronFile).path;

const cancelRemainingUploads = async () => {
    const electron = ensureElectron();
    await electron.setPendingUploadCollection(undefined);
    await electron.setPendingUploadFiles("zips", []);
    await electron.setPendingUploadFiles("files", []);
};

/**
 * The data needed by {@link clusterLivePhotos} to do its thing.
 *
 * As files progress through stages, they get more and more bits tacked on to
 * them. These types document the journey.
 */
type ClusterableFile = {
    localID: number;
    collectionID: number;
    // fileOrPath: File | ElectronFile | string;
    file?: File | ElectronFile | string;
};

type ClusteredFile = ClusterableFile & {
    isLivePhoto: boolean;
    livePhotoAssets?: LivePhotoAssets2;
};

/**
 * Go through the given files, combining any sibling image + video assets into a
 * single live photo when appropriate.
 */
const clusterLivePhotos = (mediaFiles: ClusterableFile[]) => {
    const result: ClusteredFile[] = [];
    mediaFiles
        .sort((f, g) =>
            nameAndExtension(getFileName(f.file))[0].localeCompare(
                nameAndExtension(getFileName(g.file))[0],
            ),
        )
        .sort((f, g) => f.collectionID - g.collectionID);
    let index = 0;
    while (index < mediaFiles.length - 1) {
        const f = mediaFiles[index];
        const g = mediaFiles[index + 1];
        const fFileName = getFileName(f.file);
        const gFileName = getFileName(g.file);
        const fFileType = potentialFileTypeFromExtension(fFileName);
        const gFileType = potentialFileTypeFromExtension(gFileName);
        const fa: PotentialLivePhotoAsset = {
            fileName: fFileName,
            fileType: fFileType,
            collectionID: f.collectionID,
            /* TODO(MR): ElectronFile changes */
            size: (f as FileWithCollection).file.size,
        };
        const ga: PotentialLivePhotoAsset = {
            fileName: gFileName,
            fileType: gFileType,
            collectionID: g.collectionID,
            /* TODO(MR): ElectronFile changes */
            size: (g as FileWithCollection).file.size,
        };
        if (areLivePhotoAssets(fa, ga)) {
            result.push({
                localID: f.localID,
                collectionID: f.collectionID,
                isLivePhoto: true,
                livePhotoAssets: {
                    /* TODO(MR): ElectronFile changes */
                    image: (fFileType == FILE_TYPE.IMAGE ? f.file : g.file) as
                        | string
                        | File,
                    video: (fFileType == FILE_TYPE.IMAGE ? g.file : f.file) as
                        | string
                        | File,
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
    if (index === mediaFiles.length - 1) {
        result.push({
            ...mediaFiles[index],
            isLivePhoto: false,
        });
    }
    return result;
};

interface PotentialLivePhotoAsset {
    fileName: string;
    fileType: FILE_TYPE;
    collectionID: number;
    size: number;
}

const areLivePhotoAssets = (
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
    if (f.size > maxAssetSize || g.size > maxAssetSize) {
        log.info(
            `Not classifying assets with too large sizes ${[f.size, g.size]} as a live photo`,
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
