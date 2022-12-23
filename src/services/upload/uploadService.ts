import { Collection } from 'types/collection';
import { logError } from 'utils/sentry';
import UploadHttpClient from './uploadHttpClient';
import { extractFileMetadata, getFilename } from './fileService';
import { getFileType } from '../typeDetectionService';
import { CustomError, handleUploadError } from 'utils/error';
import {
    B64EncryptionResult,
    BackupedFile,
    EncryptedFile,
    FileTypeInfo,
    FileWithCollection,
    FileWithMetadata,
    isDataStream,
    Metadata,
    ParsedMetadataJSON,
    ParsedMetadataJSONMap,
    ProcessedFile,
    PublicUploadProps,
    UploadAsset,
    UploadFile,
    UploadURL,
} from 'types/upload';
import {
    clusterLivePhotoFiles,
    extractLivePhotoMetadata,
    getLivePhotoFileType,
    getLivePhotoName,
    getLivePhotoSize,
    readLivePhoto,
} from './livePhotoService';
import { encryptFile, getFileSize, readFile } from './fileService';
import { uploadStreamUsingMultipart } from './multiPartUploadService';
import UIService from './uiService';
import { USE_CF_PROXY } from 'constants/upload';
import publicUploadHttpClient from './publicUploadHttpClient';
import { constructPublicMagicMetadata } from './magicMetadataService';
import { FilePublicMagicMetadataProps } from 'types/file';

class UploadService {
    private uploadURLs: UploadURL[] = [];
    private parsedMetadataJSONMap: ParsedMetadataJSONMap = new Map<
        string,
        ParsedMetadataJSON
    >();

    private uploaderName: string;

    private pendingUploadCount: number = 0;

    private publicUploadProps: PublicUploadProps = undefined;

    init(publicUploadProps: PublicUploadProps) {
        this.publicUploadProps = publicUploadProps;
    }

    async setFileCount(fileCount: number) {
        this.pendingUploadCount = fileCount;
        this.preFetchUploadURLs();
    }

    setParsedMetadataJSONMap(parsedMetadataJSONMap: ParsedMetadataJSONMap) {
        this.parsedMetadataJSONMap = parsedMetadataJSONMap;
    }

    setUploaderName(uploaderName: string) {
        this.uploaderName = uploaderName;
    }

    getUploaderName() {
        return this.uploaderName;
    }

    reducePendingUploadCount() {
        this.pendingUploadCount--;
    }

    getAssetSize({ isLivePhoto, file, livePhotoAssets }: UploadAsset) {
        return isLivePhoto
            ? getLivePhotoSize(livePhotoAssets)
            : getFileSize(file);
    }

    getAssetName({ isLivePhoto, file, livePhotoAssets }: UploadAsset) {
        return isLivePhoto
            ? getLivePhotoName(livePhotoAssets)
            : getFilename(file);
    }

    getAssetFileType({ isLivePhoto, file, livePhotoAssets }: UploadAsset) {
        return isLivePhoto
            ? getLivePhotoFileType(livePhotoAssets)
            : getFileType(file);
    }

    async readAsset(
        fileTypeInfo: FileTypeInfo,
        { isLivePhoto, file, livePhotoAssets }: UploadAsset
    ) {
        return isLivePhoto
            ? await readLivePhoto(fileTypeInfo, livePhotoAssets)
            : await readFile(fileTypeInfo, file);
    }

    async extractAssetMetadata(
        worker,
        { isLivePhoto, file, livePhotoAssets }: UploadAsset,
        collectionID: number,
        fileTypeInfo: FileTypeInfo
    ): Promise<Metadata> {
        return isLivePhoto
            ? extractLivePhotoMetadata(
                  worker,
                  this.parsedMetadataJSONMap,
                  collectionID,
                  fileTypeInfo,
                  livePhotoAssets
              )
            : await extractFileMetadata(
                  worker,
                  this.parsedMetadataJSONMap,
                  collectionID,
                  fileTypeInfo,
                  file
              );
    }

    clusterLivePhotoFiles(mediaFiles: FileWithCollection[]) {
        return clusterLivePhotoFiles(mediaFiles);
    }

    constructPublicMagicMetadata(
        publicMagicMetadataProps: FilePublicMagicMetadataProps
    ) {
        return constructPublicMagicMetadata(publicMagicMetadataProps);
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
                    file.localID,
                    file.file.encryptedData
                );
            } else {
                const progressTracker = UIService.trackUploadProgress(
                    file.localID
                );
                const fileUploadURL = await this.getUploadURL();
                if (USE_CF_PROXY) {
                    fileObjectKey = await UploadHttpClient.putFileV2(
                        fileUploadURL,
                        file.file.encryptedData,
                        progressTracker
                    );
                } else {
                    fileObjectKey = await UploadHttpClient.putFile(
                        fileUploadURL,
                        file.file.encryptedData,
                        progressTracker
                    );
                }
            }
            const thumbnailUploadURL = await this.getUploadURL();
            let thumbnailObjectKey: string = null;
            if (USE_CF_PROXY) {
                thumbnailObjectKey = await UploadHttpClient.putFileV2(
                    thumbnailUploadURL,
                    file.thumbnail.encryptedData,
                    null
                );
            } else {
                thumbnailObjectKey = await UploadHttpClient.putFile(
                    thumbnailUploadURL,
                    file.thumbnail.encryptedData,
                    null
                );
            }

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
                pubMagicMetadata: file.pubMagicMetadata,
            };
            return backupedFile;
        } catch (e) {
            if (e.message !== CustomError.UPLOAD_CANCELLED) {
                logError(e, 'error uploading to bucket');
            }
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

    async uploadFile(uploadFile: UploadFile) {
        if (this.publicUploadProps.accessedThroughSharedURL) {
            return publicUploadHttpClient.uploadFile(
                uploadFile,
                this.publicUploadProps.token,
                this.publicUploadProps.passwordToken
            );
        } else {
            return UploadHttpClient.uploadFile(uploadFile);
        }
    }

    private async fetchUploadURLs() {
        if (this.publicUploadProps.accessedThroughSharedURL) {
            await publicUploadHttpClient.fetchUploadURLs(
                this.pendingUploadCount,
                this.uploadURLs,
                this.publicUploadProps.token,
                this.publicUploadProps.passwordToken
            );
        } else {
            await UploadHttpClient.fetchUploadURLs(
                this.pendingUploadCount,
                this.uploadURLs
            );
        }
    }
}

export default new UploadService();
