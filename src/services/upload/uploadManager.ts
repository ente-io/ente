import { File, getLocalFiles } from '../fileService';
import { Collection, getLocalCollections } from '../collectionService';
import { SetFiles } from 'pages/gallery';
import { ComlinkWorker, getDedicatedCryptoWorker } from 'utils/crypto';
import {
    sortFilesIntoCollections,
    sortFiles,
    removeUnnecessaryFileProps,
} from 'utils/file';
import { logError } from 'utils/sentry';
import localForage from 'utils/storage/localForage';
import {
    getMetadataMapKey,
    ParsedMetaDataJSON,
    parseMetadataJSON,
} from './metadataService';
import { segregateFiles } from 'utils/upload';
import { ProgressUpdater } from 'components/pages/gallery/Upload';
import uploader from './uploader';
import UIService from './uiService';
import UploadService from './uploadService';

const MAX_CONCURRENT_UPLOADS = 4;
const FILE_UPLOAD_COMPLETED = 100;

export enum FileUploadResults {
    FAILED = -1,
    SKIPPED = -2,
    UNSUPPORTED = -3,
    BLOCKED = -4,
    UPLOADED = 100,
}

export interface FileWithCollection {
    file: globalThis.File;
    collectionID: number;
}

export enum UPLOAD_STAGES {
    START,
    READING_GOOGLE_METADATA_FILES,
    UPLOADING,
    FINISH,
}

export type MetadataMap = Map<string, ParsedMetaDataJSON>;

class UploadManager {
    private cryptoWorkers = new Array<ComlinkWorker>(MAX_CONCURRENT_UPLOADS);
    private metadataMap: MetadataMap;
    private filesToBeUploaded: FileWithCollection[];
    private failedFiles: FileWithCollection[];
    private existingFilesCollectionWise: Map<number, File[]>;
    private existingFiles: File[];
    private setFiles: SetFiles;
    private collections: Map<number, Collection>;
    public initUploader(progressUpdater: ProgressUpdater, setFiles: SetFiles) {
        UIService.init(progressUpdater);
        this.setFiles = setFiles;
    }

    private async init(newCollections?: Collection[]) {
        this.filesToBeUploaded = [];
        this.failedFiles = [];
        this.metadataMap = new Map<string, ParsedMetaDataJSON>();
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
            const { metadataFiles, mediaFiles } = segregateFiles(
                fileWithCollectionToBeUploaded
            );
            if (metadataFiles.length) {
                UIService.setUploadStage(
                    UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES
                );
                await this.seedMetadataMap(metadataFiles);
            }
            if (mediaFiles.length) {
                UIService.setUploadStage(UPLOAD_STAGES.START);
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

    private async seedMetadataMap(metadataFiles: FileWithCollection[]) {
        try {
            UIService.reset(metadataFiles.length);

            for (const fileWithCollection of metadataFiles) {
                const parsedMetaDataJSONWithTitle = await parseMetadataJSON(
                    fileWithCollection.file
                );
                if (parsedMetaDataJSONWithTitle) {
                    const { title, parsedMetaDataJSON } =
                        parsedMetaDataJSONWithTitle;
                    this.metadataMap.set(
                        getMetadataMapKey(
                            fileWithCollection.collectionID,
                            title
                        ),
                        parsedMetaDataJSON
                    );
                    UIService.increaseFileUploaded();
                }
            }
        } catch (e) {
            logError(e, 'error seeding MetadataMap');
            // silently ignore the error
        }
    }

    private async uploadMediaFiles(mediaFiles: FileWithCollection[]) {
        this.filesToBeUploaded.push(...mediaFiles);
        UIService.reset(mediaFiles.length);

        await UploadService.init(mediaFiles.length, this.metadataMap);

        UIService.setUploadStage(UPLOAD_STAGES.UPLOADING);

        const uploadProcesses = [];
        for (
            let i = 0;
            i < MAX_CONCURRENT_UPLOADS && this.filesToBeUploaded.length > 0;
            i++
        ) {
            this.cryptoWorkers[i] = getDedicatedCryptoWorker();
            uploadProcesses.push(
                this.uploadNextFileInQueue(
                    await new this.cryptoWorkers[i].comlink(),
                    new FileReader()
                )
            );
        }
        await Promise.all(uploadProcesses);
    }

    private async uploadNextFileInQueue(worker: any, fileReader: FileReader) {
        while (this.filesToBeUploaded.length > 0) {
            const fileWithCollection = this.filesToBeUploaded.pop();
            const existingFilesInCollection =
                this.existingFilesCollectionWise.get(
                    fileWithCollection.collectionID
                ) ?? [];
            const collection = this.collections.get(
                fileWithCollection.collectionID
            );
            const { fileUploadResult, file } = await uploader(
                worker,
                fileReader,
                existingFilesInCollection,
                fileWithCollection.file,
                collection
            );

            if (fileUploadResult === FileUploadResults.UPLOADED) {
                this.existingFiles.push(file);
                this.existingFiles = sortFiles(this.existingFiles);
                await localForage.setItem(
                    'files',
                    removeUnnecessaryFileProps(this.existingFiles)
                );
                this.setFiles(this.existingFiles);
            }
            if (
                fileUploadResult === FileUploadResults.BLOCKED ||
                fileUploadResult === FileUploadResults.FAILED
            ) {
                this.failedFiles.push(fileWithCollection);
            }

            UIService.moveFileToResultList(fileWithCollection.file.name);
        }
    }

    async retryFailedFiles() {
        await this.queueFilesForUpload(this.failedFiles);
    }
}

export default new UploadManager();
