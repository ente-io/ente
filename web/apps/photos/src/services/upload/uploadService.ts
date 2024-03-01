import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { B64EncryptionResult } from "@ente/shared/crypto/types";
import { CustomError, handleUploadError } from "@ente/shared/error";
import { logError } from "@ente/shared/sentry";
import { Remote } from "comlink";
import { Collection } from "types/collection";
import { FilePublicMagicMetadataProps } from "types/file";
import {
    BackupedFile,
    EncryptedFile,
    ExtractMetadataResult,
    FileTypeInfo,
    FileWithCollection,
    FileWithMetadata,
    Logger,
    ParsedMetadataJSON,
    ParsedMetadataJSONMap,
    ProcessedFile,
    PublicUploadProps,
    UploadAsset,
    UploadFile,
    UploadURL,
    isDataStream,
} from "types/upload";
import { getFileType } from "../typeDetectionService";
import {
    encryptFile,
    extractFileMetadata,
    getFileSize,
    getFilename,
    readFile,
} from "./fileService";
import {
    clusterLivePhotoFiles,
    extractLivePhotoMetadata,
    getLivePhotoFileType,
    getLivePhotoName,
    getLivePhotoSize,
    readLivePhoto,
} from "./livePhotoService";
import { constructPublicMagicMetadata } from "./magicMetadataService";
import { uploadStreamUsingMultipart } from "./multiPartUploadService";
import publicUploadHttpClient from "./publicUploadHttpClient";
import UIService from "./uiService";
import UploadHttpClient from "./uploadHttpClient";

class UploadService {
    private uploadURLs: UploadURL[] = [];
    private parsedMetadataJSONMap: ParsedMetadataJSONMap = new Map<
        string,
        ParsedMetadataJSON
    >();

    private uploaderName: string;

    private pendingUploadCount: number = 0;

    private publicUploadProps: PublicUploadProps = undefined;

    private isCFUploadProxyDisabled: boolean = false;

    init(
        publicUploadProps: PublicUploadProps,
        isCFUploadProxyDisabled: boolean,
    ) {
        this.publicUploadProps = publicUploadProps;
        this.isCFUploadProxyDisabled = isCFUploadProxyDisabled;
    }

    async setFileCount(fileCount: number) {
        this.pendingUploadCount = fileCount;
        await this.preFetchUploadURLs();
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

    getIsCFUploadProxyDisabled() {
        return this.isCFUploadProxyDisabled;
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
        { isLivePhoto, file, livePhotoAssets }: UploadAsset,
    ) {
        return isLivePhoto
            ? await readLivePhoto(fileTypeInfo, livePhotoAssets)
            : await readFile(fileTypeInfo, file);
    }

    async extractAssetMetadata(
        worker: Remote<DedicatedCryptoWorker>,
        { isLivePhoto, file, livePhotoAssets }: UploadAsset,
        collectionID: number,
        fileTypeInfo: FileTypeInfo,
    ): Promise<ExtractMetadataResult> {
        return isLivePhoto
            ? extractLivePhotoMetadata(
                  worker,
                  this.parsedMetadataJSONMap,
                  collectionID,
                  fileTypeInfo,
                  livePhotoAssets,
              )
            : await extractFileMetadata(
                  worker,
                  this.parsedMetadataJSONMap,
                  collectionID,
                  fileTypeInfo,
                  file,
              );
    }

    clusterLivePhotoFiles(mediaFiles: FileWithCollection[]) {
        return clusterLivePhotoFiles(mediaFiles);
    }

    constructPublicMagicMetadata(
        publicMagicMetadataProps: FilePublicMagicMetadataProps,
    ) {
        return constructPublicMagicMetadata(publicMagicMetadataProps);
    }

    async encryptAsset(
        worker: Remote<DedicatedCryptoWorker>,
        file: FileWithMetadata,
        encryptionKey: string,
    ): Promise<EncryptedFile> {
        return encryptFile(worker, file, encryptionKey);
    }

    async uploadToBucket(
        logger: Logger,
        file: ProcessedFile,
    ): Promise<BackupedFile> {
        try {
            let fileObjectKey: string = null;
            logger("uploading file to bucket");
            if (isDataStream(file.file.encryptedData)) {
                logger("uploading using multipart");
                fileObjectKey = await uploadStreamUsingMultipart(
                    logger,
                    file.localID,
                    file.file.encryptedData,
                );
                logger("uploading using multipart done");
            } else {
                logger("uploading using single part");
                const progressTracker = UIService.trackUploadProgress(
                    file.localID,
                );
                const fileUploadURL = await this.getUploadURL();
                if (!this.isCFUploadProxyDisabled) {
                    logger("uploading using cf proxy");
                    fileObjectKey = await UploadHttpClient.putFileV2(
                        fileUploadURL,
                        file.file.encryptedData as Uint8Array,
                        progressTracker,
                    );
                } else {
                    logger("uploading directly to s3");
                    fileObjectKey = await UploadHttpClient.putFile(
                        fileUploadURL,
                        file.file.encryptedData as Uint8Array,
                        progressTracker,
                    );
                }
                logger("uploading using single part done");
            }
            logger("uploading thumbnail to bucket");
            const thumbnailUploadURL = await this.getUploadURL();
            let thumbnailObjectKey: string = null;
            if (!this.isCFUploadProxyDisabled) {
                thumbnailObjectKey = await UploadHttpClient.putFileV2(
                    thumbnailUploadURL,
                    file.thumbnail.encryptedData,
                    null,
                );
            } else {
                thumbnailObjectKey = await UploadHttpClient.putFile(
                    thumbnailUploadURL,
                    file.thumbnail.encryptedData,
                    null,
                );
            }
            logger("uploading thumbnail to bucket done");

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
                logError(e, "error uploading to bucket");
            }
            throw e;
        }
    }

    getUploadFile(
        collection: Collection,
        backupedFile: BackupedFile,
        fileKey: B64EncryptionResult,
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
            logError(e, "prefetch uploadURL failed");
            handleUploadError(e);
        }
    }

    async uploadFile(uploadFile: UploadFile) {
        if (this.publicUploadProps.accessedThroughSharedURL) {
            return publicUploadHttpClient.uploadFile(
                uploadFile,
                this.publicUploadProps.token,
                this.publicUploadProps.passwordToken,
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
                this.publicUploadProps.passwordToken,
            );
        } else {
            await UploadHttpClient.fetchUploadURLs(
                this.pendingUploadCount,
                this.uploadURLs,
            );
        }
    }

    async fetchMultipartUploadURLs(count: number) {
        if (this.publicUploadProps.accessedThroughSharedURL) {
            return await publicUploadHttpClient.fetchMultipartUploadURLs(
                count,
                this.publicUploadProps.token,
                this.publicUploadProps.passwordToken,
            );
        } else {
            return await UploadHttpClient.fetchMultipartUploadURLs(count);
        }
    }
}

export default new UploadService();
