import { File, getLocalFiles } from '../fileService';
import { Collection } from '../collectionService';
import { SetFiles } from 'pages/gallery';
import { ComlinkWorker, getDedicatedCryptoWorker } from 'utils/crypto';
import {
    sortFilesIntoCollections,
    sortFiles,
    removeUnneccessaryFileProps,
} from 'utils/file';
import { logError } from 'utils/sentry';
import localForage from 'utils/storage/localForage';
import { ParsedMetaDataJSON, parseMetadataJSON } from './metadataService';
import { segregateFiles } from 'utils/upload';
import { ProgressUpdater } from 'components/pages/gallery/Upload';
import uploader from './uploader';
import uiService from './uiService';
import uploadService from './uploadService';

const MAX_CONCURRENT_UPLOADS = 4;
const FILE_UPLOAD_COMPLETED = 100;

export enum FileUploadResults {
    FAILED = -1,
    SKIPPED = -2,
    UNSUPPORTED = -3,
    BLOCKED = -4,
    UPLOADED = 100,
}

export interface UploadURL {
    url: string;
    objectKey: string;
}

export interface FileWithCollection {
    file: globalThis.File;
    collection: Collection;
}

export enum UPLOAD_STAGES {
    START,
    READING_GOOGLE_METADATA_FILES,
    UPLOADING,
    FINISH,
}

class UploadManager {
    private cryptoWorkers = new Array<ComlinkWorker>(MAX_CONCURRENT_UPLOADS);
    private metadataMap: Map<string, ParsedMetaDataJSON>;
    private filesToBeUploaded: FileWithCollection[];
    private failedFiles: FileWithCollection[];
    private existingFilesCollectionWise: Map<number, File[]>;
    private existingFiles: File[];
    private setFiles: SetFiles;

    public initUploader(progressUpdater: ProgressUpdater, setFiles: SetFiles) {
        uiService.init(progressUpdater);
        this.setFiles = setFiles;
    }

    private async init() {
        this.filesToBeUploaded = [];
        this.failedFiles = [];
        this.metadataMap = new Map<string, ParsedMetaDataJSON>();
        this.existingFiles = await getLocalFiles();
        this.existingFilesCollectionWise = sortFilesIntoCollections(
            this.existingFiles,
        );
    }

    public async queueFilesForUpload(
        filesWithCollectionToUpload: FileWithCollection[],
    ) {
        try {
            await this.init();

            const { metadataFiles, mediaFiles } = segregateFiles(
                filesWithCollectionToUpload,
            );
            if (metadataFiles.length) {
                uiService.setUploadStage(
                    UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES,
                );
                await this.seedMetadataMap(metadataFiles);
            }
            if (mediaFiles.length) {
                uiService.setUploadStage(UPLOAD_STAGES.START);
                await this.uploadMediaFiles(mediaFiles);
            }
            uiService.setUploadStage(UPLOAD_STAGES.FINISH);
            uiService.setPercentComplete(FILE_UPLOAD_COMPLETED);
        } catch (e) {
            logError(e, 'uploading failed with error');
            throw e;
        } finally {
            for (let i = 0; i < MAX_CONCURRENT_UPLOADS; i++) {
                this.cryptoWorkers[i]?.worker.terminate();
            }
        }
    }

    private async seedMetadataMap(metadataFiles: globalThis.File[]) {
        uiService.reset(metadataFiles.length);

        for (const rawFile of metadataFiles) {
            const parsedMetaDataJSON = await parseMetadataJSON(rawFile);
            this.metadataMap.set(parsedMetaDataJSON.title, parsedMetaDataJSON);
            uiService.increaseFileUploaded();
        }
    }

    private async uploadMediaFiles(mediaFiles: FileWithCollection[]) {
        this.filesToBeUploaded.push(...mediaFiles);
        uiService.reset(mediaFiles.length);

        uploadService.init(mediaFiles.length, this.metadataMap);

        uiService.setUploadStage(UPLOAD_STAGES.UPLOADING);

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
                    new FileReader(),
                ),
            );
        }
        await Promise.all(uploadProcesses);
    }

    private async uploadNextFileInQueue(worker: any, fileReader: FileReader) {
        while (this.filesToBeUploaded.length > 0) {
            const fileWithCollection = this.filesToBeUploaded.pop();
            const { fileUploadResult, file } = await uploader(
                worker,
                fileReader,
                fileWithCollection,
                this.existingFilesCollectionWise,
            );

            if (fileUploadResult === FileUploadResults.UPLOADED) {
                this.existingFiles.push(file);
                this.existingFiles = sortFiles(this.existingFiles);
                await localForage.setItem(
                    'files',
                    removeUnneccessaryFileProps(this.existingFiles),
                );
                this.setFiles(this.existingFiles);
            }

            uiService.moveFileToResultList(fileWithCollection.file.name);
        }
    }

    async retryFailedFiles() {
        await this.queueFilesForUpload(this.failedFiles);
    }
}

export default new UploadManager();
