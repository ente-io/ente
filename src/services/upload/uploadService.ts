import { Collection } from 'types/collection';
import { logError } from 'utils/sentry';
import UploadHttpClient from './uploadHttpClient';
import { getFileMetadata } from './fileService';
import { getFileType } from './readFileService';
import { CustomError, handleUploadError } from 'utils/error';
import {
    FileTypeInfo,
    MetadataMap,
    Metadata,
    ParsedMetadataJSON,
    UploadURL,
    UploadAsset,
    B64EncryptionResult,
    BackupedFile,
    isDataStream,
    ProcessedFile,
    UploadFile,
    FileWithMetadata,
    EncryptedFile,
} from 'types/upload';
import { FILE_TYPE } from 'constants/file';
import { FORMAT_MISSED_BY_FILE_TYPE_LIB } from 'constants/upload';
import {
    getLivePhotoFileType,
    getLivePhotoMetadata,
    getLivePhotoSize,
    readLivePhoto,
} from './livePhotoService';
import { encryptFile, getFileSize, readFile } from './fileService';
import { uploadStreamUsingMultipart } from './multiPartUploadService';
import UIService from './uiService';

class UploadService {
    private uploadURLs: UploadURL[] = [];
    private metadataMap: Map<string, ParsedMetadataJSON>;
    private pendingUploadCount: number = 0;

    async init(fileCount: number, metadataMap: MetadataMap) {
        this.pendingUploadCount = fileCount;
        this.metadataMap = metadataMap;
        await this.preFetchUploadURLs();
    }

    reducePendingUploadCount() {
        this.pendingUploadCount--;
    }

    getAssetSize({ isLivePhoto, file, livePhotoAssets }: UploadAsset) {
        return isLivePhoto
            ? getLivePhotoSize(livePhotoAssets)
            : getFileSize(file);
    }

    async getAssetType(
        worker,
        { file, isLivePhoto, livePhotoAssets }: UploadAsset
    ) {
        const fileTypeInfo = isLivePhoto
            ? await getLivePhotoFileType(worker, livePhotoAssets)
            : await getFileType(worker, file);
        if (fileTypeInfo.fileType !== FILE_TYPE.OTHERS) {
            return fileTypeInfo;
        }
        try {
            const formatMissedByTypeDetection =
                FORMAT_MISSED_BY_FILE_TYPE_LIB.find(
                    (a) => a.exactType === fileTypeInfo.exactType
                );
            if (formatMissedByTypeDetection) {
                return formatMissedByTypeDetection;
            }
            throw Error(CustomError.UNSUPPORTED_FILE_FORMAT);
        } catch (e) {
            logError(e, CustomError.TYPE_DETECTION_FAILED, {
                fileType: fileTypeInfo.exactType,
            });
        }
    }
    async readAsset(
        worker: any,
        reader: FileReader,
        fileTypeInfo: FileTypeInfo,
        { isLivePhoto, file, livePhotoAssets }: UploadAsset
    ) {
        return isLivePhoto
            ? await readLivePhoto(worker, reader, fileTypeInfo, livePhotoAssets)
            : await readFile(worker, reader, fileTypeInfo, file);
    }

    async getAssetMetadata(
        { isLivePhoto, file, livePhotoAssets }: UploadAsset,
        collection: Collection,
        fileTypeInfo: FileTypeInfo
    ): Promise<Metadata> {
        return isLivePhoto
            ? await getLivePhotoMetadata(
                  livePhotoAssets,
                  collection,
                  fileTypeInfo
              )
            : await getFileMetadata(file, collection, fileTypeInfo);
    }

    async encryptAsset(
        worker: any,
        file: FileWithMetadata,
        encryptionKey: string
    ): Promise<EncryptedFile> {
        return encryptFile(worker, file, encryptionKey);
    }

    async uploadToBucket(file: ProcessedFile): Promise<BackupedFile> {
        try {
            let fileObjectKey: string = null;
            if (isDataStream(file.file.encryptedData)) {
                fileObjectKey = await uploadStreamUsingMultipart(
                    file.filename,
                    file.file.encryptedData
                );
            } else {
                const progressTracker = UIService.trackUploadProgress(
                    file.filename
                );
                const fileUploadURL = await this.getUploadURL();
                fileObjectKey = await UploadHttpClient.putFile(
                    fileUploadURL,
                    file.file.encryptedData,
                    progressTracker
                );
            }
            const thumbnailUploadURL = await this.getUploadURL();
            const thumbnailObjectKey = await UploadHttpClient.putFile(
                thumbnailUploadURL,
                file.thumbnail.encryptedData as Uint8Array,
                null
            );

            const backupedFile: BackupedFile = {
                file: {
                    decryptionHeader: file.file.decryptionHeader,
                    objectKey: fileObjectKey,
                },
                thumbnail: {
                    decryptionHeader: file.thumbnail.decryptionHeader,
                    objectKey: thumbnailObjectKey,
                },
                metadata: file.metadata,
            };
            return backupedFile;
        } catch (e) {
            logError(e, 'error uploading to bucket');
            throw e;
        }
    }

    getUploadFile(
        collection: Collection,
        backupedFile: BackupedFile,
        fileKey: B64EncryptionResult
    ): UploadFile {
        const uploadFile: UploadFile = {
            collectionID: collection.id,
            encryptedKey: fileKey.encryptedData,
            keyDecryptionNonce: fileKey.nonce,
            ...backupedFile,
        };
        uploadFile;
        return uploadFile;
    }

    private async getUploadURL() {
        if (this.uploadURLs.length === 0 && this.pendingUploadCount) {
            await this.fetchUploadURLs();
        }
        return this.uploadURLs.pop();
    }

    public async preFetchUploadURLs() {
        try {
            await this.fetchUploadURLs();
            // checking for any subscription related errors
        } catch (e) {
            logError(e, 'prefetch uploadURL failed');
            handleUploadError(e);
        }
    }

    private async fetchUploadURLs() {
        await UploadHttpClient.fetchUploadURLs(
            this.pendingUploadCount,
            this.uploadURLs
        );
    }
}

export default new UploadService();
