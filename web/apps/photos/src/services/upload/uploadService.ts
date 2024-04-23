import { encodeLivePhoto } from "@/media/live-photo";
import {
    basename,
    convertBytesToHumanReadable,
    getFileNameSize,
} from "@/next/file";
import log from "@/next/log";
import { ElectronFile } from "@/next/types/file";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import {
    B64EncryptionResult,
    EncryptionResult,
} from "@ente/shared/crypto/types";
import { CustomError, handleUploadError } from "@ente/shared/error";
import { wait } from "@ente/shared/utils";
import { Remote } from "comlink";
import { FILE_TYPE } from "constants/file";
import {
    FILE_READER_CHUNK_SIZE,
    MULTIPART_PART_SIZE,
    UPLOAD_RESULT,
} from "constants/upload";
import { addToCollection } from "services/collectionService";
import { Collection } from "types/collection";
import {
    EnteFile,
    FilePublicMagicMetadata,
    FilePublicMagicMetadataProps,
} from "types/file";
import { EncryptedMagicMetadata } from "types/magicMetadata";
import {
    BackupedFile,
    DataStream,
    EncryptedFile,
    ExtractMetadataResult,
    FileInMemory,
    FileTypeInfo,
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
    type FileWithCollection2,
    type LivePhotoAssets,
    type UploadAsset2,
} from "types/upload";
import {
    getNonEmptyMagicMetadataProps,
    updateMagicMetadata,
} from "utils/magicMetadata";
import { findMatchingExistingFiles } from "utils/upload";
import {
    getElectronFileStream,
    getFileStream,
    getUint8ArrayView,
} from "../readerService";
import { getFileType } from "../typeDetectionService";
import {
    MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT,
    extractLivePhotoMetadata,
    extractMetadata,
    getClippedMetadataJSONMapKeyForFile,
    getLivePhotoFileType,
    getLivePhotoName,
    getLivePhotoSize,
    getMetadataJSONMapKeyForFile,
} from "./metadataService";
import { uploadStreamUsingMultipart } from "./multiPartUploadService";
import publicUploadHttpClient from "./publicUploadHttpClient";
import { generateThumbnail } from "./thumbnail";
import UIService from "./uiService";
import uploadCancelService from "./uploadCancelService";
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

    getAssetName({ isLivePhoto, file, livePhotoAssets }: UploadAsset2) {
        return isLivePhoto
            ? getLivePhotoName(livePhotoAssets)
            : getFileName(file);
    }

    getAssetFileType({ isLivePhoto, file, livePhotoAssets }: UploadAsset) {
        return isLivePhoto
            ? getLivePhotoFileType(livePhotoAssets)
            : getFileType(file);
    }

    async extractAssetMetadata(
        worker: Remote<DedicatedCryptoWorker>,
        { isLivePhoto, file, livePhotoAssets }: UploadAsset2,
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

/** The singleton instance of {@link UploadService}. */
const uploadService = new UploadService();

export default uploadService;

const constructPublicMagicMetadata = async (
    publicMagicMetadataProps: FilePublicMagicMetadataProps,
): Promise<FilePublicMagicMetadata> => {
    const nonEmptyPublicMagicMetadataProps = getNonEmptyMagicMetadataProps(
        publicMagicMetadataProps,
    );

    if (Object.values(nonEmptyPublicMagicMetadataProps)?.length === 0) {
        return null;
    }
    return await updateMagicMetadata(publicMagicMetadataProps);
};

function getFileSize(file: File | ElectronFile) {
    return file.size;
}

export const getFileName = (file: File | ElectronFile | string) =>
    typeof file == "string" ? basename(file) : file.name;

const readAsset = async (
    fileTypeInfo: FileTypeInfo,
    { isLivePhoto, file, livePhotoAssets }: UploadAsset,
) => {
    return isLivePhoto
        ? await readLivePhoto(fileTypeInfo, livePhotoAssets)
        : await readFile(fileTypeInfo, file);
};

// TODO(MR): Merge with the uploader
class ModuleState {
    /**
     * This will be set to true if we get an error from the Node.js side of our
     * desktop app telling us that native JPEG conversion is not available for
     * the current OS/arch combination. That way, we can stop pestering it again
     * and again (saving an IPC round-trip).
     *
     * Note the double negative when it is used.
     */
    isNativeThumbnailCreationNotAvailable = false;
}

const moduleState = new ModuleState();


async function readFile(
    fileTypeInfo: FileTypeInfo,
    rawFile: File | ElectronFile,
): Promise<FileInMemory> {
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

    const electron = globalThis.electron;
    const available = !moduleState.isNativeThumbnailCreationNotAvailable;
    if (electron && available) {
        try {
            return await generateImageThumbnailInElectron(electron, blob);
        } catch (e) {
            if (e.message == CustomErrorMessage.NotAvailable) {
                moduleState.isNativeThumbnailCreationNotAvailable = true;
            } else {
                log.error("Native thumbnail creation failed", e);
            }
        }
    }

    if (filedata instanceof Uint8Array) {

    } else {
        filedata.stream
    }

    log.info(`read file data successfully ${getFileNameSize(rawFile)} `);

    const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
        rawFile,
        fileTypeInfo,
    );

    return {
        filedata,
        thumbnail,
        hasStaticThumbnail,
    };
}

async function readLivePhoto(
    fileTypeInfo: FileTypeInfo,
    livePhotoAssets: LivePhotoAssets,
) {
    const imageData = await getUint8ArrayView(livePhotoAssets.image);

    const videoData = await getUint8ArrayView(livePhotoAssets.video);

    const imageBlob = new Blob([imageData]);
    const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
        imageBlob,
        {
            exactType: fileTypeInfo.imageType,
            fileType: FILE_TYPE.IMAGE,
        },
    );

    return {
        filedata: await encodeLivePhoto({
            imageFileName: livePhotoAssets.image.name,
            imageData,
            videoFileName: livePhotoAssets.video.name,
            videoData,
        }),
        thumbnail,
        hasStaticThumbnail,
    };
}

export async function extractFileMetadata(
    worker: Remote<DedicatedCryptoWorker>,
    parsedMetadataJSONMap: ParsedMetadataJSONMap,
    collectionID: number,
    fileTypeInfo: FileTypeInfo,
    rawFile: File | ElectronFile | string,
): Promise<ExtractMetadataResult> {
    const rawFileName = getFileName(rawFile);
    let key = getMetadataJSONMapKeyForFile(collectionID, rawFileName);
    let googleMetadata: ParsedMetadataJSON = parsedMetadataJSONMap.get(key);

    if (!googleMetadata && key.length > MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT) {
        key = getClippedMetadataJSONMapKeyForFile(collectionID, rawFileName);
        googleMetadata = parsedMetadataJSONMap.get(key);
    }

    const { metadata, publicMagicMetadata } = await extractMetadata(
        worker,
        /* TODO(MR): ElectronFile changes */
        rawFile as File | ElectronFile,
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

interface UploadResponse {
    fileUploadResult: UPLOAD_RESULT;
    uploadedFile?: EnteFile;
}

export async function uploader(
    worker: Remote<DedicatedCryptoWorker>,
    existingFiles: EnteFile[],
    fileWithCollection: FileWithCollection2,
    uploaderName: string,
): Promise<UploadResponse> {
    const { collection, localID, ...uploadAsset2 } = fileWithCollection;
    /* TODO(MR): ElectronFile changes */
    const uploadAsset = uploadAsset2 as UploadAsset;
    const fileNameSize = `${uploadService.getAssetName(
        fileWithCollection,
    )}_${convertBytesToHumanReadable(uploadService.getAssetSize(uploadAsset))}`;

    log.info(`uploader called for  ${fileNameSize}`);
    UIService.setFileProgress(localID, 0);
    await wait(0);
    let fileTypeInfo: FileTypeInfo;
    let fileSize: number;
    try {
        const maxFileSize = 4 * 1024 * 1024 * 1024; // 4 GB

        fileSize = uploadService.getAssetSize(uploadAsset);
        if (fileSize >= maxFileSize) {
            return { fileUploadResult: UPLOAD_RESULT.TOO_LARGE };
        }
        log.info(`getting filetype for ${fileNameSize}`);
        fileTypeInfo = await uploadService.getAssetFileType(uploadAsset);
        log.info(
            `got filetype for ${fileNameSize} - ${JSON.stringify(fileTypeInfo)}`,
        );

        log.info(`extracting  metadata ${fileNameSize}`);
        const { metadata, publicMagicMetadata } =
            await uploadService.extractAssetMetadata(
                worker,
                uploadAsset,
                collection.id,
                fileTypeInfo,
            );

        const matchingExistingFiles = findMatchingExistingFiles(
            existingFiles,
            metadata,
        );
        log.debug(
            () =>
                `matchedFileList: ${matchingExistingFiles
                    .map((f) => `${f.id}-${f.metadata.title}`)
                    .join(",")}`,
        );
        if (matchingExistingFiles?.length) {
            const matchingExistingFilesCollectionIDs =
                matchingExistingFiles.map((e) => e.collectionID);
            log.debug(
                () =>
                    `matched file collectionIDs:${matchingExistingFilesCollectionIDs}
                       and collectionID:${collection.id}`,
            );
            if (matchingExistingFilesCollectionIDs.includes(collection.id)) {
                log.info(
                    `file already present in the collection , skipped upload for  ${fileNameSize}`,
                );
                const sameCollectionMatchingExistingFile =
                    matchingExistingFiles.find(
                        (f) => f.collectionID === collection.id,
                    );
                return {
                    fileUploadResult: UPLOAD_RESULT.ALREADY_UPLOADED,
                    uploadedFile: sameCollectionMatchingExistingFile,
                };
            } else {
                log.info(
                    `same file in ${matchingExistingFilesCollectionIDs.length} collection found for  ${fileNameSize} ,adding symlink`,
                );
                // any of the matching file can used to add a symlink
                const resultFile = Object.assign({}, matchingExistingFiles[0]);
                resultFile.collectionID = collection.id;
                await addToCollection(collection, [resultFile]);
                return {
                    fileUploadResult: UPLOAD_RESULT.ADDED_SYMLINK,
                    uploadedFile: resultFile,
                };
            }
        }
        if (uploadCancelService.isUploadCancelationRequested()) {
            throw Error(CustomError.UPLOAD_CANCELLED);
        }
        log.info(`reading asset ${fileNameSize}`);

        const file = readAsset(fileTypeInfo, uploadAsset);

        if (file.hasStaticThumbnail) {
            metadata.hasStaticThumbnail = true;
        }

        const pubMagicMetadata = await constructPublicMagicMetadata({
            ...publicMagicMetadata,
            uploaderName,
        });

        const fileWithMetadata: FileWithMetadata = {
            localID,
            filedata: file.filedata,
            thumbnail: file.thumbnail,
            metadata,
            pubMagicMetadata,
        };

        if (uploadCancelService.isUploadCancelationRequested()) {
            throw Error(CustomError.UPLOAD_CANCELLED);
        }
        log.info(`encryptAsset ${fileNameSize}`);
        const encryptedFile = await uploadService.encryptAsset(
            worker,
            fileWithMetadata,
            collection.key,
        );

        if (uploadCancelService.isUploadCancelationRequested()) {
            throw Error(CustomError.UPLOAD_CANCELLED);
        }
        log.info(`uploadToBucket ${fileNameSize}`);
        const logger: Logger = (message: string) => {
            log.info(message, `fileNameSize: ${fileNameSize}`);
        };
        const backupedFile: BackupedFile = await uploadService.uploadToBucket(
            logger,
            encryptedFile.file,
        );

        const uploadFile: UploadFile = uploadService.getUploadFile(
            collection,
            backupedFile,
            encryptedFile.fileKey,
        );
        log.info(`uploading file to server ${fileNameSize}`);

        const uploadedFile = await uploadService.uploadFile(uploadFile);

        log.info(`${fileNameSize} successfully uploaded`);

        return {
            fileUploadResult: metadata.hasStaticThumbnail
                ? UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL
                : UPLOAD_RESULT.UPLOADED,
            uploadedFile: uploadedFile,
        };
    } catch (e) {
        log.info(`upload failed for  ${fileNameSize} ,error: ${e.message}`);
        if (
            e.message !== CustomError.UPLOAD_CANCELLED &&
            e.message !== CustomError.UNSUPPORTED_FILE_FORMAT
        ) {
            log.error(
                `file upload failed - ${JSON.stringify({
                    fileFormat: fileTypeInfo?.exactType,
                    fileSize: convertBytesToHumanReadable(fileSize),
                })}`,
                e,
            );
        }
        const error = handleUploadError(e);
        switch (error.message) {
            case CustomError.ETAG_MISSING:
                return { fileUploadResult: UPLOAD_RESULT.BLOCKED };
            case CustomError.UNSUPPORTED_FILE_FORMAT:
                return { fileUploadResult: UPLOAD_RESULT.UNSUPPORTED };
            case CustomError.FILE_TOO_LARGE:
                return {
                    fileUploadResult:
                        UPLOAD_RESULT.LARGER_THAN_AVAILABLE_STORAGE,
                };
            default:
                return { fileUploadResult: UPLOAD_RESULT.FAILED };
        }
    }
}
