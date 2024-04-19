import { getFileNameSize } from "@/next/file";
import log from "@/next/log";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import {
    B64EncryptionResult,
    EncryptionResult,
} from "@ente/shared/crypto/types";
import { CustomError, handleUploadError } from "@ente/shared/error";
import { Remote } from "comlink";
import { FILE_READER_CHUNK_SIZE, MULTIPART_PART_SIZE } from "constants/upload";
import { Collection } from "types/collection";
import {
    FilePublicMagicMetadata,
    FilePublicMagicMetadataProps,
} from "types/file";
import { EncryptedMagicMetadata } from "types/magicMetadata";
import {
    BackupedFile,
    DataStream,
    ElectronFile,
    EncryptedFile,
    ExtractMetadataResult,
    FileInMemory,
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
import {
    getNonEmptyMagicMetadataProps,
    updateMagicMetadata,
} from "utils/magicMetadata";
import {
    getElectronFileStream,
    getFileStream,
    getUint8ArrayView,
} from "../readerService";
import { getFileType } from "../typeDetectionService";
import {
    clusterLivePhotoFiles,
    extractLivePhotoMetadata,
    getLivePhotoFileType,
    getLivePhotoName,
    getLivePhotoSize,
    readLivePhoto,
} from "./livePhotoService";
import {
    MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT,
    extractMetadata,
    getClippedMetadataJSONMapKeyForFile,
    getMetadataJSONMapKeyForFile,
} from "./metadataService";
import { uploadStreamUsingMultipart } from "./multiPartUploadService";
import publicUploadHttpClient from "./publicUploadHttpClient";
import { generateThumbnail } from "./thumbnailService";
import UIService from "./uiService";
import UploadHttpClient from "./uploadHttpClient";

/** Upload files to cloud storage */
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
                log.error("error uploading to bucket", e);
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
            log.error("prefetch uploadURL failed", e);
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

export async function constructPublicMagicMetadata(
    publicMagicMetadataProps: FilePublicMagicMetadataProps,
): Promise<FilePublicMagicMetadata> {
    const nonEmptyPublicMagicMetadataProps = getNonEmptyMagicMetadataProps(
        publicMagicMetadataProps,
    );

    if (Object.values(nonEmptyPublicMagicMetadataProps)?.length === 0) {
        return null;
    }
    return await updateMagicMetadata(publicMagicMetadataProps);
}

function getFileSize(file: File | ElectronFile) {
    return file.size;
}

function getFilename(file: File | ElectronFile) {
    return file.name;
}

async function readFile(
    fileTypeInfo: FileTypeInfo,
    rawFile: File | ElectronFile,
): Promise<FileInMemory> {
    const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
        rawFile,
        fileTypeInfo,
    );
    log.info(`reading file data ${getFileNameSize(rawFile)} `);
    let filedata: Uint8Array | DataStream;
    if (!(rawFile instanceof File)) {
        if (rawFile.size > MULTIPART_PART_SIZE) {
            filedata = await getElectronFileStream(
                rawFile,
                FILE_READER_CHUNK_SIZE,
            );
        } else {
            filedata = await getUint8ArrayView(rawFile);
        }
    } else if (rawFile.size > MULTIPART_PART_SIZE) {
        filedata = getFileStream(rawFile, FILE_READER_CHUNK_SIZE);
    } else {
        filedata = await getUint8ArrayView(rawFile);
    }

    log.info(`read file data successfully ${getFileNameSize(rawFile)} `);

    return {
        filedata,
        thumbnail,
        hasStaticThumbnail,
    };
}

export async function extractFileMetadata(
    worker: Remote<DedicatedCryptoWorker>,
    parsedMetadataJSONMap: ParsedMetadataJSONMap,
    collectionID: number,
    fileTypeInfo: FileTypeInfo,
    rawFile: File | ElectronFile,
): Promise<ExtractMetadataResult> {
    let key = getMetadataJSONMapKeyForFile(collectionID, rawFile.name);
    let googleMetadata: ParsedMetadataJSON = parsedMetadataJSONMap.get(key);

    if (!googleMetadata && key.length > MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT) {
        key = getClippedMetadataJSONMapKeyForFile(collectionID, rawFile.name);
        googleMetadata = parsedMetadataJSONMap.get(key);
    }

    const { metadata, publicMagicMetadata } = await extractMetadata(
        worker,
        rawFile,
        fileTypeInfo,
    );

    for (const [key, value] of Object.entries(googleMetadata ?? {})) {
        if (!value) {
            continue;
        }
        metadata[key] = value;
    }
    return { metadata, publicMagicMetadata };
}

async function encryptFile(
    worker: Remote<DedicatedCryptoWorker>,
    file: FileWithMetadata,
    encryptionKey: string,
): Promise<EncryptedFile> {
    try {
        const { key: fileKey, file: encryptedFiledata } = await encryptFiledata(
            worker,
            file.filedata,
        );

        const { file: encryptedThumbnail } = await worker.encryptThumbnail(
            file.thumbnail,
            fileKey,
        );
        const { file: encryptedMetadata } = await worker.encryptMetadata(
            file.metadata,
            fileKey,
        );

        let encryptedPubMagicMetadata: EncryptedMagicMetadata;
        if (file.pubMagicMetadata) {
            const { file: encryptedPubMagicMetadataData } =
                await worker.encryptMetadata(
                    file.pubMagicMetadata.data,
                    fileKey,
                );
            encryptedPubMagicMetadata = {
                version: file.pubMagicMetadata.version,
                count: file.pubMagicMetadata.count,
                data: encryptedPubMagicMetadataData.encryptedData,
                header: encryptedPubMagicMetadataData.decryptionHeader,
            };
        }

        const encryptedKey = await worker.encryptToB64(fileKey, encryptionKey);

        const result: EncryptedFile = {
            file: {
                file: encryptedFiledata,
                thumbnail: encryptedThumbnail,
                metadata: encryptedMetadata,
                pubMagicMetadata: encryptedPubMagicMetadata,
                localID: file.localID,
            },
            fileKey: encryptedKey,
        };
        return result;
    } catch (e) {
        log.error("Error encrypting files", e);
        throw e;
    }
}

async function encryptFiledata(
    worker: Remote<DedicatedCryptoWorker>,
    filedata: Uint8Array | DataStream,
): Promise<EncryptionResult<Uint8Array | DataStream>> {
    return isDataStream(filedata)
        ? await encryptFileStream(worker, filedata)
        : await worker.encryptFile(filedata);
}

async function encryptFileStream(
    worker: Remote<DedicatedCryptoWorker>,
    fileData: DataStream,
) {
    const { stream, chunkCount } = fileData;
    const fileStreamReader = stream.getReader();
    const { key, decryptionHeader, pushState } =
        await worker.initChunkEncryption();
    const ref = { pullCount: 1 };
    const encryptedFileStream = new ReadableStream({
        async pull(controller) {
            const { value } = await fileStreamReader.read();
            const encryptedFileChunk = await worker.encryptFileChunk(
                value,
                pushState,
                ref.pullCount === chunkCount,
            );
            controller.enqueue(encryptedFileChunk);
            if (ref.pullCount === chunkCount) {
                controller.close();
            }
            ref.pullCount++;
        },
    });
    return {
        key,
        file: {
            decryptionHeader,
            encryptedData: { stream: encryptedFileStream, chunkCount },
        },
    };
}
