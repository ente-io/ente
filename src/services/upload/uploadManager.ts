import { getLocalFiles, setLocalFiles } from '../fileService';
import { getLocalCollections } from '../collectionService';
import { SetFiles } from 'types/gallery';
import { getDedicatedCryptoWorker } from 'utils/crypto';
import {
    sortFilesIntoCollections,
    sortFiles,
    removeUnnecessaryFileProps,
} from 'utils/file';
import { logError } from 'utils/sentry';
import { getMetadataMapKey, parseMetadataJSON } from './metadataService';
import { segregateFiles } from 'utils/upload';
import uploader from './uploader';
import UIService from './uiService';
import UploadService from './uploadService';
import { CustomError } from 'utils/error';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import {
    FileWithCollection,
    MetadataAndFileTypeInfo,
    MetadataAndFileTypeInfoMap,
    ParsedMetadataJSON,
    ParsedMetadataJSONMap,
    ProgressUpdater,
} from 'types/upload';
import {
    UPLOAD_STAGES,
    FileUploadResults,
    FIVE_GB_IN_BYTES,
} from 'constants/upload';
import { ComlinkWorker } from 'utils/comlink';
import { getFileType } from './readFileService';
import { FILE_TYPE } from 'constants/file';
import uploadService from './uploadService';

const MAX_CONCURRENT_UPLOADS = 4;
const FILE_UPLOAD_COMPLETED = 100;

class UploadManager {
    private cryptoWorkers = new Array<ComlinkWorker>(MAX_CONCURRENT_UPLOADS);
    private parsedMetadataJSONMap: ParsedMetadataJSONMap;
    private metadataAndFileTypeInfoMap: MetadataAndFileTypeInfoMap;
    private filesToBeUploaded: FileWithCollection[];
    private failedFiles: FileWithCollection[];
    private existingFilesCollectionWise: Map<number, EnteFile[]>;
    private existingFiles: EnteFile[];
    private setFiles: SetFiles;
    private collections: Map<number, Collection>;
    public initUploader(progressUpdater: ProgressUpdater, setFiles: SetFiles) {
        UIService.init(progressUpdater);
        this.setFiles = setFiles;
    }

    private async init(newCollections?: Collection[]) {
        this.filesToBeUploaded = [];
        this.failedFiles = [];
        this.parsedMetadataJSONMap = new Map<string, ParsedMetadataJSON>();
        this.metadataAndFileTypeInfoMap = new Map<
            string,
            MetadataAndFileTypeInfo
        >();
        this.existingFiles = await getLocalFiles();
        this.existingFilesCollectionWise = sortFilesIntoCollections(
            this.existingFiles
        );
        const collections = await getLocalCollections();
        if (newCollections) {
            collections.push(...newCollections);
        }
        this.collections = new Map(
            collections.map((collection) => [collection.id, collection])
        );
    }

    public async queueFilesForUpload(
        fileWithCollectionToBeUploaded: FileWithCollection[],
        newCreatedCollections?: Collection[]
    ) {
        try {
            await this.init(newCreatedCollections);
            const { metadataJSONFiles, mediaFiles } = segregateFiles(
                fileWithCollectionToBeUploaded
            );
            if (metadataJSONFiles.length) {
                UIService.setUploadStage(
                    UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES
                );
                await this.parseMetadataJSONFiles(metadataJSONFiles);
                uploadService.setParsedMetadataJSONMap(
                    this.parsedMetadataJSONMap
                );
            }
            if (mediaFiles.length) {
                UIService.setUploadStage(UPLOAD_STAGES.START);
                await this.extractMetadataFromFiles(mediaFiles);
                uploadService.setMetadataAndFileTypeInfoMap(
                    this.metadataAndFileTypeInfoMap
                );
                await this.uploadMediaFiles(mediaFiles);
            }
            UIService.setUploadStage(UPLOAD_STAGES.FINISH);
            UIService.setPercentComplete(FILE_UPLOAD_COMPLETED);
        } catch (e) {
            logError(e, 'uploading failed with error');
            throw e;
        } finally {
            for (let i = 0; i < MAX_CONCURRENT_UPLOADS; i++) {
                this.cryptoWorkers[i]?.worker.terminate();
            }
        }
    }

    private async parseMetadataJSONFiles(metadataFiles: FileWithCollection[]) {
        try {
            UIService.reset(metadataFiles.length);
            const reader = new FileReader();
            for (const { file, collectionID } of metadataFiles) {
                const parsedMetadataJSONWithTitle = await parseMetadataJSON(
                    reader,
                    file
                );
                if (parsedMetadataJSONWithTitle) {
                    const { title, parsedMetadataJSON } =
                        parsedMetadataJSONWithTitle;
                    this.parsedMetadataJSONMap.set(
                        getMetadataMapKey(collectionID, title),
                        { ...parsedMetadataJSON }
                    );
                    UIService.increaseFileUploaded();
                }
            }
        } catch (e) {
            logError(e, 'error seeding MetadataMap');
            // silently ignore the error
        }
    }

    private async extractMetadataFromFiles(mediaFiles: FileWithCollection[]) {
        try {
            UIService.reset(mediaFiles.length);
            const reader = new FileReader();
            for (const { file, collectionID } of mediaFiles) {
                const { fileTypeInfo, metadata } = await (async () => {
                    if (file.size >= FIVE_GB_IN_BYTES) {
                        return { fileTypeInfo: null, metadata: null };
                    }
                    const fileTypeInfo = await getFileType(reader, file);
                    if (fileTypeInfo.fileType === FILE_TYPE.OTHERS) {
                        return { fileTypeInfo, metadata: null };
                    }
                    const metadata =
                        (await uploadService.extractMetadata(
                            file,
                            collectionID,
                            fileTypeInfo
                        )) || null;
                    return { fileTypeInfo, metadata };
                })();

                this.metadataAndFileTypeInfoMap.set(
                    getMetadataMapKey(collectionID, file.name),
                    {
                        fileTypeInfo: { ...fileTypeInfo },
                        metadata: { ...metadata },
                    }
                );
                UIService.increaseFileUploaded();
            }
        } catch (e) {
            logError(e, 'error extracting metadata');
            // silently ignore the error
        }
    }

    private async uploadMediaFiles(mediaFiles: FileWithCollection[]) {
        this.filesToBeUploaded.push(...mediaFiles);
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
                    await new this.cryptoWorkers[i].comlink(),
                    new FileReader()
                )
            );
        }
        await Promise.all(uploadProcesses);
    }

    private async uploadNextFileInQueue(worker: any, reader: FileReader) {
        while (this.filesToBeUploaded.length > 0) {
            const fileWithCollection = this.filesToBeUploaded.pop();
            const { file: rawFile, collectionID } = fileWithCollection;
            const existingFilesInCollection =
                this.existingFilesCollectionWise.get(collectionID) ?? [];
            const collection = this.collections.get(collectionID);
            const { fileUploadResult, file } = await uploader(
                worker,
                reader,
                existingFilesInCollection,
                { file: rawFile, collection }
            );

            if (fileUploadResult === FileUploadResults.UPLOADED) {
                this.existingFiles.push(file);
                this.existingFiles = sortFiles(this.existingFiles);
                await setLocalFiles(
                    removeUnnecessaryFileProps(this.existingFiles)
                );
                this.setFiles(this.existingFiles);
                if (!this.existingFilesCollectionWise.has(file.collectionID)) {
                    this.existingFilesCollectionWise.set(file.collectionID, []);
                }
                this.existingFilesCollectionWise
                    .get(file.collectionID)
                    .push(file);
            }
            if (
                fileUploadResult === FileUploadResults.BLOCKED ||
                fileUploadResult === FileUploadResults.FAILED
            ) {
                this.failedFiles.push(fileWithCollection);
            }

            UIService.moveFileToResultList(
                fileWithCollection.file.name,
                fileUploadResult
            );
            UploadService.reducePendingUploadCount();
        }
    }

    async retryFailedFiles() {
        await this.queueFilesForUpload(this.failedFiles);
    }
}

export default new UploadManager();
