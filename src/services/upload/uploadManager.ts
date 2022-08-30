import {
    getLocalFiles,
    setLocalFiles,
    updateFileMagicMetadata,
} from '../fileService';
import { SetFiles } from 'types/gallery';
import { getDedicatedCryptoWorker } from 'utils/crypto';
import {
    groupFilesBasedOnCollectionID,
    sortFiles,
    preservePhotoswipeProps,
    decryptFile,
    appendNewFilePath,
} from 'utils/file';
import { logError } from 'utils/sentry';
import { getMetadataJSONMapKey, parseMetadataJSON } from './metadataService';
import {
    areFileWithCollectionsSame,
    segregateMetadataAndMediaFiles,
} from 'utils/upload';
import uploader from './uploader';
import UIService from './uiService';
import UploadService from './uploadService';
import { CustomError } from 'utils/error';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import {
    ElectronFile,
    FileWithCollection,
    Metadata,
    MetadataAndFileTypeInfo,
    MetadataAndFileTypeInfoMap,
    ParsedMetadataJSON,
    ParsedMetadataJSONMap,
} from 'types/upload';
import {
    UPLOAD_RESULT,
    MAX_FILE_SIZE_SUPPORTED,
    UPLOAD_STAGES,
} from 'constants/upload';
import { ComlinkWorker } from 'utils/comlink';
import { FILE_TYPE } from 'constants/file';
import uiService from './uiService';
import { addLogLine, getFileNameSize } from 'utils/logging';
import isElectron from 'is-electron';
import ImportService from 'services/importService';
import watchFolderService from 'services/watchFolder/watchFolderService';
import { ProgressUpdater } from 'types/upload/ui';
import uploadCancelService from './uploadCancelService';

const MAX_CONCURRENT_UPLOADS = 4;
const FILE_UPLOAD_COMPLETED = 100;

class UploadManager {
    private cryptoWorkers = new Array<ComlinkWorker>(MAX_CONCURRENT_UPLOADS);
    private parsedMetadataJSONMap: ParsedMetadataJSONMap;
    private metadataAndFileTypeInfoMap: MetadataAndFileTypeInfoMap;
    private filesToBeUploaded: FileWithCollection[];
    private remainingFiles: FileWithCollection[] = [];
    private failedFiles: FileWithCollection[];
    private existingFilesCollectionWise: Map<number, EnteFile[]>;
    private existingFiles: EnteFile[];
    private setFiles: SetFiles;
    private collections: Map<number, Collection>;

    async init(progressUpdater: ProgressUpdater, setFiles: SetFiles) {
        this.existingFiles = await getLocalFiles();
        this.existingFilesCollectionWise = groupFilesBasedOnCollectionID(
            this.existingFiles
        );
        UIService.init(progressUpdater);
        this.setFiles = setFiles;
    }

    private resetState() {
        this.filesToBeUploaded = [];
        this.remainingFiles = [];
        this.failedFiles = [];
        this.parsedMetadataJSONMap = new Map<string, ParsedMetadataJSON>();
        this.metadataAndFileTypeInfoMap = new Map<
            number,
            MetadataAndFileTypeInfo
        >();
    }

    private async prepareForNewUpload(collections: Collection[]) {
        this.resetState();
        UIService.reset();
        uploadCancelService.reset();
        this.collections = new Map(
            collections.map((collection) => [collection.id, collection])
        );
    }

    public async queueFilesForUpload(
        filesWithCollectionToUploadIn: FileWithCollection[],
        collections: Collection[]
    ) {
        try {
            await this.prepareForNewUpload(collections);
            addLogLine(
                `received ${filesWithCollectionToUploadIn.length} files to upload`
            );
            const { metadataJSONFiles, mediaFiles } =
                segregateMetadataAndMediaFiles(filesWithCollectionToUploadIn);
            addLogLine(`has ${metadataJSONFiles.length} metadata json files`);
            addLogLine(`has ${mediaFiles.length} media files`);
            if (metadataJSONFiles.length) {
                UIService.setUploadStage(
                    UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES
                );
                await this.parseMetadataJSONFiles(metadataJSONFiles);

                UploadService.setParsedMetadataJSONMap(
                    this.parsedMetadataJSONMap
                );
            }
            if (mediaFiles.length) {
                UIService.setUploadStage(UPLOAD_STAGES.EXTRACTING_METADATA);
                await this.extractMetadataFromFiles(mediaFiles);

                UploadService.setMetadataAndFileTypeInfoMap(
                    this.metadataAndFileTypeInfoMap
                );

                UIService.setUploadStage(UPLOAD_STAGES.START);
                addLogLine(`clusterLivePhotoFiles called`);

                // filter out files whose metadata detection failed or those that have been skipped because the files are too large,
                // as they will be rejected during upload and are not valid upload files which we need to clustering
                const rejectedFileLocalIDs = new Set(
                    [...this.metadataAndFileTypeInfoMap.entries()].map(
                        ([localID, metadataAndFileTypeInfo]) => {
                            if (
                                !metadataAndFileTypeInfo.metadata ||
                                !metadataAndFileTypeInfo.fileTypeInfo
                            ) {
                                return localID;
                            }
                        }
                    )
                );
                const rejectedFiles = [];
                const filesWithMetadata = [];
                mediaFiles.forEach((m) => {
                    if (rejectedFileLocalIDs.has(m.localID)) {
                        rejectedFiles.push(m);
                    } else {
                        filesWithMetadata.push(m);
                    }
                });

                const analysedMediaFiles =
                    UploadService.clusterLivePhotoFiles(filesWithMetadata);

                const allFiles = [...rejectedFiles, ...analysedMediaFiles];

                uiService.setFilenames(
                    new Map<number, string>(
                        allFiles.map((mediaFile) => [
                            mediaFile.localID,
                            UploadService.getAssetName(mediaFile),
                        ])
                    )
                );

                UIService.setHasLivePhoto(
                    mediaFiles.length !== allFiles.length
                );
                addLogLine(
                    `got live photos: ${mediaFiles.length !== allFiles.length}`
                );

                await this.uploadMediaFiles(allFiles);
            }
        } catch (e) {
            if (e.message === CustomError.UPLOAD_CANCELLED) {
                if (isElectron()) {
                    ImportService.cancelRemainingUploads();
                }
            } else {
                logError(e, 'uploading failed with error');
                addLogLine(
                    `uploading failed with error -> ${e.message}
                ${(e as Error).stack}`
                );
                throw e;
            }
        } finally {
            UIService.setUploadStage(UPLOAD_STAGES.FINISH);
            UIService.setPercentComplete(FILE_UPLOAD_COMPLETED);
            for (let i = 0; i < MAX_CONCURRENT_UPLOADS; i++) {
                this.cryptoWorkers[i]?.worker.terminate();
            }
        }
    }

    private async parseMetadataJSONFiles(metadataFiles: FileWithCollection[]) {
        try {
            addLogLine(`parseMetadataJSONFiles function executed `);

            UIService.reset(metadataFiles.length);

            for (const { file, collectionID } of metadataFiles) {
                try {
                    if (uploadCancelService.isUploadCancelationRequested()) {
                        throw Error(CustomError.UPLOAD_CANCELLED);
                    }

                    addLogLine(
                        `parsing metadata json file ${getFileNameSize(file)}`
                    );

                    const parsedMetadataJSONWithTitle = await parseMetadataJSON(
                        file
                    );
                    if (parsedMetadataJSONWithTitle) {
                        const { title, parsedMetadataJSON } =
                            parsedMetadataJSONWithTitle;
                        this.parsedMetadataJSONMap.set(
                            getMetadataJSONMapKey(collectionID, title),
                            parsedMetadataJSON && { ...parsedMetadataJSON }
                        );
                        UIService.increaseFileUploaded();
                    }
                    addLogLine(
                        `successfully parsed metadata json file ${getFileNameSize(
                            file
                        )}`
                    );
                } catch (e) {
                    if (e.message === CustomError.UPLOAD_CANCELLED) {
                        throw e;
                    } else {
                        logError(e, 'parsing failed for a file');
                        // and don't break for subsequent files
                    }
                    addLogLine(
                        `failed to parse metadata json file ${getFileNameSize(
                            file
                        )} error: ${e.message}`
                    );
                }
            }
        } catch (e) {
            if (e.message !== CustomError.UPLOAD_CANCELLED) {
                logError(e, 'error seeding MetadataMap');
            }
            throw e;
            // silently ignore the error
        }
    }

    private async extractMetadataFromFiles(mediaFiles: FileWithCollection[]) {
        try {
            addLogLine(`extractMetadataFromFiles executed`);
            UIService.reset(mediaFiles.length);
            for (const { file, localID, collectionID } of mediaFiles) {
                if (uploadCancelService.isUploadCancelationRequested()) {
                    throw Error(CustomError.UPLOAD_CANCELLED);
                }
                let fileTypeInfo = null;
                let metadata = null;
                let filePath = null;
                try {
                    addLogLine(
                        `metadata extraction started ${getFileNameSize(file)} `
                    );
                    const result = await this.extractFileTypeAndMetadata(
                        file,
                        collectionID
                    );
                    fileTypeInfo = result.fileTypeInfo;
                    metadata = result.metadata;
                    filePath = result.filePath;
                    addLogLine(
                        `metadata extraction successful${getFileNameSize(
                            file
                        )} `
                    );
                } catch (e) {
                    if (e.message === CustomError.UPLOAD_CANCELLED) {
                        throw e;
                    } else {
                        logError(e, 'extractFileTypeAndMetadata failed');
                        // and don't break for subsequent files
                    }
                    addLogLine(
                        `metadata extraction failed ${getFileNameSize(
                            file
                        )} error: ${e.message}`
                    );
                }
                this.metadataAndFileTypeInfoMap.set(localID, {
                    fileTypeInfo: fileTypeInfo && { ...fileTypeInfo },
                    metadata: metadata && { ...metadata },
                    filePath: filePath,
                });
                UIService.increaseFileUploaded();
            }
        } catch (e) {
            if (e.message !== CustomError.UPLOAD_CANCELLED) {
                logError(e, 'error extracting metadata');
            }
            throw e;
        }
    }

    private async extractFileTypeAndMetadata(
        file: File | ElectronFile,
        collectionID: number
    ) {
        if (file.size >= MAX_FILE_SIZE_SUPPORTED) {
            addLogLine(
                `${getFileNameSize(file)} rejected  because of large size`
            );

            return { fileTypeInfo: null, metadata: null };
        }
        const fileTypeInfo = await UploadService.getFileType(file);
        if (fileTypeInfo.fileType === FILE_TYPE.OTHERS) {
            addLogLine(
                `${getFileNameSize(
                    file
                )} rejected  because of unknown file format`
            );
            return { fileTypeInfo, metadata: null };
        }
        addLogLine(` extracting ${getFileNameSize(file)} metadata`);
        let metadata: Metadata;
        try {
            metadata = await UploadService.extractFileMetadata(
                file,
                collectionID,
                fileTypeInfo
            );
            const filePath = (file as any).path as string;
            return { fileTypeInfo, metadata, filePath };
        } catch (e) {
            logError(e, 'failed to extract file metadata');
            return { fileTypeInfo, metadata: null, filePath: null };
        }
    }

    private async uploadMediaFiles(mediaFiles: FileWithCollection[]) {
        addLogLine(`uploadMediaFiles called`);
        this.filesToBeUploaded.push(...mediaFiles);

        if (isElectron()) {
            this.remainingFiles.push(...mediaFiles);
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
            const cryptoWorker = getDedicatedCryptoWorker();
            if (!cryptoWorker) {
                throw Error(CustomError.FAILED_TO_LOAD_WEB_WORKER);
            }
            this.cryptoWorkers[i] = cryptoWorker;
            uploadProcesses.push(
                this.uploadNextFileInQueue(
                    await new this.cryptoWorkers[i].comlink()
                )
            );
        }
        await Promise.all(uploadProcesses);
    }

    private async uploadNextFileInQueue(worker: any) {
        while (this.filesToBeUploaded.length > 0) {
            if (uploadCancelService.isUploadCancelationRequested()) {
                throw Error(CustomError.UPLOAD_CANCELLED);
            }
            let fileWithCollection = this.filesToBeUploaded.pop();
            const { collectionID } = fileWithCollection;
            const existingFilesInCollection =
                this.existingFilesCollectionWise.get(collectionID) ?? [];
            const collection = this.collections.get(collectionID);
            fileWithCollection = { ...fileWithCollection, collection };
            const { fileUploadResult, uploadedFile } = await uploader(
                worker,
                existingFilesInCollection,
                this.existingFiles,
                fileWithCollection
            );

            const finalUploadResult = await this.postUploadTask(
                fileUploadResult,
                uploadedFile,
                fileWithCollection
            );

            UIService.moveFileToResultList(
                fileWithCollection.localID,
                finalUploadResult
            );
            UploadService.reducePendingUploadCount();
        }
    }

    async postUploadTask(
        fileUploadResult: UPLOAD_RESULT,
        uploadedFile: EnteFile,
        fileWithCollection: FileWithCollection
    ) {
        try {
            let decryptedFile: EnteFile;
            addLogLine(`uploadedFile ${JSON.stringify(uploadedFile)}`);
            this.updateElectronRemainingFiles(fileWithCollection);
            switch (fileUploadResult) {
                case UPLOAD_RESULT.FAILED:
                case UPLOAD_RESULT.BLOCKED:
                    this.failedFiles.push(fileWithCollection);
                    break;
                case UPLOAD_RESULT.ALREADY_UPLOADED:
                    if (isElectron()) {
                        await watchFolderService.onFileUpload(
                            fileWithCollection,
                            uploadedFile
                        );
                    }
                    await this.updateFilePaths(
                        uploadedFile,
                        fileWithCollection
                    );
                    break;
                case UPLOAD_RESULT.ADDED_SYMLINK:
                    decryptedFile = uploadedFile;
                    break;
                case UPLOAD_RESULT.UPLOADED:
                case UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL:
                    decryptedFile = await decryptFile(
                        uploadedFile,
                        fileWithCollection.collection.key
                    );
                    break;
                case UPLOAD_RESULT.CANCELLED:
                    // no-op
                    break;
                default:
                    throw Error('Invalid Upload Result');
            }
            if (decryptedFile) {
                await this.updateExistingFiles(decryptedFile);
                this.updateExistingCollections(decryptedFile);
                await this.watchFolderCallback(
                    fileWithCollection,
                    uploadedFile
                );
                await this.updateFilePaths(decryptedFile, fileWithCollection);
            }
            return fileUploadResult;
        } catch (e) {
            logError(e, 'failed to do post file upload action');
            addLogLine(
                `failed to do post file upload action -> ${e.message}
                ${(e as Error).stack}`
            );
            return UPLOAD_RESULT.FAILED;
        }
    }

    private async watchFolderCallback(
        fileWithCollection: FileWithCollection,
        uploadedFile: EnteFile
    ) {
        if (isElectron()) {
            await watchFolderService.onFileUpload(
                fileWithCollection,
                uploadedFile
            );
        }
    }

    public cancelRunningUpload() {
        UIService.setUploadStage(UPLOAD_STAGES.PAUSING);
        uploadCancelService.requestUploadCancelation();
    }

    private updateExistingCollections(decryptedFile: EnteFile) {
        if (!this.existingFilesCollectionWise.has(decryptedFile.collectionID)) {
            this.existingFilesCollectionWise.set(
                decryptedFile.collectionID,
                []
            );
        }
        this.existingFilesCollectionWise
            .get(decryptedFile.collectionID)
            .push(decryptedFile);
    }

    private async updateExistingFiles(decryptedFile: EnteFile) {
        this.existingFiles.push(decryptedFile);
        this.existingFiles = sortFiles(this.existingFiles);
        await setLocalFiles(this.existingFiles);
        this.setFiles(preservePhotoswipeProps(this.existingFiles));
    }

    private updateElectronRemainingFiles(
        fileWithCollection: FileWithCollection
    ) {
        if (isElectron()) {
            this.remainingFiles = this.remainingFiles.filter(
                (file) => !areFileWithCollectionsSame(file, fileWithCollection)
            );
            ImportService.updatePendingUploads(this.remainingFiles);
        }
    }

    private async updateFilePaths(
        decryptedFile: EnteFile,
        fileWithCollection: FileWithCollection
    ) {
        const filePath = UploadService.getFileMetadataAndFileTypeInfo(
            fileWithCollection.localID
        ).filePath;

        const updatedFile = await appendNewFilePath(decryptedFile, filePath);
        await updateFileMagicMetadata([updatedFile]);
    }

    async retryFailedFiles() {
        await this.queueFilesForUpload(this.failedFiles, [
            ...this.collections.values(),
        ]);
    }
}

export default new UploadManager();
