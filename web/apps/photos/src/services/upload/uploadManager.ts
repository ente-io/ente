import { getFileNameSize } from "@/next/file";
import log from "@/next/log";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { getDedicatedCryptoWorker } from "@ente/shared/crypto";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { CustomError } from "@ente/shared/error";
import { Events, eventBus } from "@ente/shared/events";
import { Remote } from "comlink";
import { UPLOAD_RESULT, UPLOAD_STAGES } from "constants/upload";
import isElectron from "is-electron";
import ImportService from "services/importService";
import {
    getLocalPublicFiles,
    getPublicCollectionUID,
} from "services/publicCollectionService";
import { getDisableCFUploadProxyFlag } from "services/userService";
import watchFolderService from "services/watchFolder/watchFolderService";
import { Collection } from "types/collection";
import { EncryptedEnteFile, EnteFile } from "types/file";
import { SetFiles } from "types/gallery";
import {
    FileWithCollection,
    ParsedMetadataJSON,
    ParsedMetadataJSONMap,
    PublicUploadProps,
} from "types/upload";
import { ProgressUpdater } from "types/upload/ui";
import { decryptFile, getUserOwnedFiles, sortFiles } from "utils/file";
import {
    areFileWithCollectionsSame,
    segregateMetadataAndMediaFiles,
} from "utils/upload";
import { getLocalFiles } from "../fileService";
import {
    getMetadataJSONMapKeyForJSON,
    parseMetadataJSON,
} from "./metadataService";
import { default as UIService, default as uiService } from "./uiService";
import uploadCancelService from "./uploadCancelService";
import UploadService from "./uploadService";
import uploader from "./uploader";

const MAX_CONCURRENT_UPLOADS = 4;

class UploadManager {
    private cryptoWorkers = new Array<
        ComlinkWorker<typeof DedicatedCryptoWorker>
    >(MAX_CONCURRENT_UPLOADS);
    private parsedMetadataJSONMap: ParsedMetadataJSONMap;
    private filesToBeUploaded: FileWithCollection[];
    private remainingFiles: FileWithCollection[] = [];
    private failedFiles: FileWithCollection[];
    private existingFiles: EnteFile[];
    private setFiles: SetFiles;
    private collections: Map<number, Collection>;
    private uploadInProgress: boolean;
    private publicUploadProps: PublicUploadProps;
    private uploaderName: string;

    public async init(
        progressUpdater: ProgressUpdater,
        setFiles: SetFiles,
        publicCollectProps: PublicUploadProps,
        isCFUploadProxyDisabled: boolean,
    ) {
        UIService.init(progressUpdater);
        const remoteIsCFUploadProxyDisabled =
            await getDisableCFUploadProxyFlag();
        if (remoteIsCFUploadProxyDisabled) {
            isCFUploadProxyDisabled = remoteIsCFUploadProxyDisabled;
        }
        UploadService.init(publicCollectProps, isCFUploadProxyDisabled);
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
        UIService.reset();
        uploadCancelService.reset();
        UIService.setUploadStage(UPLOAD_STAGES.START);
    }

    showUploadProgressDialog() {
        UIService.setUploadProgressView(true);
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
            uiService.setFilenames(
                new Map<number, string>(
                    filesWithCollectionToUploadIn.map((mediaFile) => [
                        mediaFile.localID,
                        UploadService.getAssetName(mediaFile),
                    ]),
                ),
            );
            const { metadataJSONFiles, mediaFiles } =
                segregateMetadataAndMediaFiles(filesWithCollectionToUploadIn);
            log.info(`has ${metadataJSONFiles.length} metadata json files`);
            log.info(`has ${mediaFiles.length} media files`);
            if (metadataJSONFiles.length) {
                UIService.setUploadStage(
                    UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES,
                );
                await this.parseMetadataJSONFiles(metadataJSONFiles);

                UploadService.setParsedMetadataJSONMap(
                    this.parsedMetadataJSONMap,
                );
            }
            if (mediaFiles.length) {
                log.info(`clusterLivePhotoFiles started`);
                const analysedMediaFiles =
                    await UploadService.clusterLivePhotoFiles(mediaFiles);
                log.info(`clusterLivePhotoFiles ended`);
                log.info(
                    `got live photos: ${
                        mediaFiles.length !== analysedMediaFiles.length
                    }`,
                );
                uiService.setFilenames(
                    new Map<number, string>(
                        analysedMediaFiles.map((mediaFile) => [
                            mediaFile.localID,
                            UploadService.getAssetName(mediaFile),
                        ]),
                    ),
                );

                UIService.setHasLivePhoto(
                    mediaFiles.length !== analysedMediaFiles.length,
                );

                await this.uploadMediaFiles(analysedMediaFiles);
            }
        } catch (e) {
            if (e.message === CustomError.UPLOAD_CANCELLED) {
                if (isElectron()) {
                    this.remainingFiles = [];
                    await ImportService.cancelRemainingUploads();
                }
            } else {
                log.error("uploading failed with error", e);
                throw e;
            }
        } finally {
            UIService.setUploadStage(UPLOAD_STAGES.FINISH);
            for (let i = 0; i < MAX_CONCURRENT_UPLOADS; i++) {
                this.cryptoWorkers[i]?.terminate();
            }
            this.uploadInProgress = false;
        }
        try {
            if (!UIService.hasFilesInResultList()) {
                return true;
            } else {
                return false;
            }
        } catch (e) {
            log.error(" failed to return shouldCloseProgressBar", e);
            return false;
        }
    }

    private async parseMetadataJSONFiles(metadataFiles: FileWithCollection[]) {
        try {
            log.info(`parseMetadataJSONFiles function executed `);

            UIService.reset(metadataFiles.length);

            for (const { file, collectionID } of metadataFiles) {
                try {
                    if (uploadCancelService.isUploadCancelationRequested()) {
                        throw Error(CustomError.UPLOAD_CANCELLED);
                    }
                    log.info(
                        `parsing metadata json file ${getFileNameSize(file)}`,
                    );

                    const parsedMetadataJSON = await parseMetadataJSON(file);
                    if (parsedMetadataJSON) {
                        this.parsedMetadataJSONMap.set(
                            getMetadataJSONMapKeyForJSON(
                                collectionID,
                                file.name,
                            ),
                            parsedMetadataJSON && { ...parsedMetadataJSON },
                        );
                        UIService.increaseFileUploaded();
                    }
                    log.info(
                        `successfully parsed metadata json file ${getFileNameSize(
                            file,
                        )}`,
                    );
                } catch (e) {
                    if (e.message === CustomError.UPLOAD_CANCELLED) {
                        throw e;
                    } else {
                        // and don't break for subsequent files just log and move on
                        log.error("parsing failed for a file", e);
                        log.info(
                            `failed to parse metadata json file ${getFileNameSize(
                                file,
                            )} error: ${e.message}`,
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

    private async uploadMediaFiles(mediaFiles: FileWithCollection[]) {
        log.info(`uploadMediaFiles called`);
        this.filesToBeUploaded = [...this.filesToBeUploaded, ...mediaFiles];

        if (isElectron()) {
            this.remainingFiles = [...this.remainingFiles, ...mediaFiles];
        }

        UIService.reset(mediaFiles.length);

        await UploadService.setFileCount(mediaFiles.length);

        UIService.setUploadStage(UPLOAD_STAGES.UPLOADING);

        const uploadProcesses = [];
        for (
            let i = 0;
            i < MAX_CONCURRENT_UPLOADS && this.filesToBeUploaded.length > 0;
            i++
        ) {
            this.cryptoWorkers[i] = getDedicatedCryptoWorker();
            const worker = await this.cryptoWorkers[i].remote;
            uploadProcesses.push(this.uploadNextFileInQueue(worker));
        }
        await Promise.all(uploadProcesses);
    }

    private async uploadNextFileInQueue(worker: Remote<DedicatedCryptoWorker>) {
        while (this.filesToBeUploaded.length > 0) {
            if (uploadCancelService.isUploadCancelationRequested()) {
                throw Error(CustomError.UPLOAD_CANCELLED);
            }
            let fileWithCollection = this.filesToBeUploaded.pop();
            const { collectionID } = fileWithCollection;
            const collection = this.collections.get(collectionID);
            fileWithCollection = { ...fileWithCollection, collection };
            const { fileUploadResult, uploadedFile } = await uploader(
                worker,
                this.existingFiles,
                fileWithCollection,
                this.uploaderName,
            );

            const finalUploadResult = await this.postUploadTask(
                fileUploadResult,
                uploadedFile,
                fileWithCollection,
            );

            UIService.moveFileToResultList(
                fileWithCollection.localID,
                finalUploadResult,
            );
            UIService.increaseFileUploaded();
            UploadService.reducePendingUploadCount();
        }
    }

    async postUploadTask(
        fileUploadResult: UPLOAD_RESULT,
        uploadedFile: EncryptedEnteFile | EnteFile | null,
        fileWithCollection: FileWithCollection,
    ) {
        try {
            let decryptedFile: EnteFile;
            log.info(
                `post upload action -> fileUploadResult: ${fileUploadResult} uploadedFile present ${!!uploadedFile}`,
            );
            await this.updateElectronRemainingFiles(fileWithCollection);
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
        fileWithCollection: FileWithCollection,
        uploadedFile: EncryptedEnteFile,
    ) {
        if (isElectron()) {
            await watchFolderService.onFileUpload(
                fileUploadResult,
                fileWithCollection,
                uploadedFile,
            );
        }
    }

    public cancelRunningUpload() {
        log.info("user cancelled running upload");
        UIService.setUploadStage(UPLOAD_STAGES.CANCELLING);
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

    private async updateElectronRemainingFiles(
        fileWithCollection: FileWithCollection,
    ) {
        if (isElectron()) {
            this.remainingFiles = this.remainingFiles.filter(
                (file) => !areFileWithCollectionsSame(file, fileWithCollection),
            );
            await ImportService.updatePendingUploads(this.remainingFiles);
        }
    }

    public shouldAllowNewUpload = () => {
        return !this.uploadInProgress || watchFolderService.isUploadRunning();
    };
}

export default new UploadManager();
