import { Collection } from 'types/collection';
import { logError } from 'utils/sentry';
import UploadHttpClient from './uploadHttpClient';
import { extractFileMetadata, getFilename } from './fileService';
import { getFileType } from '../typeDetectionService';
import { CustomError, handleUploadError } from 'utils/error';
import {
    B64EncryptionResult,
    BackupedFile,
    ElectronFile,
    EncryptedFile,
    FileTypeInfo,
    FileWithCollection,
    FileWithMetadata,
    isDataStream,
    Metadata,
    MetadataAndFileTypeInfo,
    MetadataAndFileTypeInfoMap,
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
    getLivePhotoName,
    getLivePhotoSize,
    readLivePhoto,
} from './livePhotoService';
import { encryptFile, getFileSize, readFile } from './fileService';
import { uploadStreamUsingMultipart } from './multiPartUploadService';
import UIService from './uiService';
import { USE_CF_PROXY } from 'constants/upload';
import publicUploadHttpClient from './publicUploadHttpClient';

class UploadService {
    private uploadURLs: UploadURL[] = [];
    private parsedMetadataJSONMap: ParsedMetadataJSONMap = new Map<
        string,
        ParsedMetadataJSON
    >();
    private metadataAndFileTypeInfoMap: MetadataAndFileTypeInfoMap = new Map<
        number,
        MetadataAndFileTypeInfo
    >();

    private uploaderName: string;

    private pendingUploadCount: number = 0;

    private publicUploadProps: PublicUploadProps = undefined;

    setPublicUploadProps(publicUploadProps: PublicUploadProps) {
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

    setMetadataAndFileTypeInfoMap(
        metadataAndFileTypeInfoMap: MetadataAndFileTypeInfoMap
    ) {
        this.metadataAndFileTypeInfoMap = metadataAndFileTypeInfoMap;
    }

    reducePendingUploadCount() {
        this.pendingUploadCount--;
    }

    getAssetSize({ isLivePhoto, file, livePhotoAssets }: UploadAsset) {
        return isLivePhoto
            ? getLivePhotoSize(livePhotoAssets)
            : getFileSize(file);
    }

    getAssetName({ isLivePhoto, file, livePhotoAssets }: FileWithCollection) {
        return isLivePhoto
            ? getLivePhotoName(livePhotoAssets.image.name)
            : getFilename(file);
    }

    async getFileType(file: File | ElectronFile) {
        return getFileType(file);
    }

    async readAsset(
        fileTypeInfo: FileTypeInfo,
        { isLivePhoto, file, livePhotoAssets }: UploadAsset
    ) {
        return isLivePhoto
            ? await readLivePhoto(fileTypeInfo, livePhotoAssets)
            : await readFile(fileTypeInfo, file);
    }

    async extractFileMetadata(
        file: File | ElectronFile,
        collectionID: number,
        fileTypeInfo: FileTypeInfo
    ): Promise<Metadata> {
        return extractFileMetadata(
            this.parsedMetadataJSONMap,
            file,
            collectionID,
            fileTypeInfo
        );
    }

    getFileMetadataAndFileTypeInfo(localID: number) {
        return this.metadataAndFileTypeInfoMap.get(localID);
    }

    setFileMetadataAndFileTypeInfo(
        localID: number,
        metadataAndFileTypeInfo: MetadataAndFileTypeInfo
    ) {
        return this.metadataAndFileTypeInfoMap.set(
            localID,
            metadataAndFileTypeInfo
        );
    }

    clusterLivePhotoFiles(mediaFiles: FileWithCollection[]) {
        return clusterLivePhotoFiles(mediaFiles);
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
                    file.thumbnail.encryptedData as Uint8Array,
                    null
                );
            } else {
                thumbnailObjectKey = await UploadHttpClient.putFile(
                    thumbnailUploadURL,
                    file.thumbnail.encryptedData as Uint8Array,
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

    public async preFetchUploadURLs() {
        try {
            await this.fetchUploadURLs();
            // checking for any subscription related errors
        } catch (e) {
            logError(e, 'prefetch uploadURL failed');
            handleUploadError(e);
        }
    }

    private async getUploadURL() {
        if (this.uploadURLs.length === 0 && this.pendingUploadCount) {
            await this.fetchUploadURLs();
        }
        return this.uploadURLs.pop();
    }

    private async fetchUploadURLs() {
        if (!this.publicUploadProps.accessedThroughSharedURL) {
            await UploadHttpClient.fetchUploadURLs(
                this.pendingUploadCount,
                this.uploadURLs
            );
        } else {
            await publicUploadHttpClient.fetchUploadURLs(
                this.pendingUploadCount,
                this.uploadURLs,
                this.publicUploadProps.token,
                this.publicUploadProps.passwordToken
            );
        }
    }
}

export default new UploadService();
