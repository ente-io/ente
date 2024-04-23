import { encodeLivePhoto } from "@/media/live-photo";
import {
    basename,
    convertBytesToHumanReadable,
    fopLabel,
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
import { readStream } from "utils/native-stream";
import { findMatchingExistingFiles } from "utils/upload";
import { getFileStream, getUint8ArrayView } from "../readerService";
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
     * desktop app telling us that native image thumbnail generation is not
     * available for the current OS/arch combination.
     *
     * That way, we can stop pestering it again and again (saving an IPC
     * round-trip).
     *
     * Note the double negative when it is used.
     */
    isNativeImageThumbnailCreationNotAvailable = false;
}

const moduleState = new ModuleState();

/**
 * Read the given file or path into an in-memory representation.
 *
 * [Note: The fileOrPath parameter to upload]
 *
 * The file can be either a web
 * [File](https://developer.mozilla.org/en-US/docs/Web/API/File) or the absolute
 * path to a file on desk. When and why, read on.
 *
 * This code gets invoked in two contexts:
 *
 * 1. web: the normal mode, when we're running in as a web app in the browser.
 *
 * 2. desktop: when we're running inside our desktop app.
 *
 * In the web context, we'll always get a File, since within the browser we
 * cannot programmatically construct paths to or arbitrarily access files on the
 * user's filesystem. Note that even if we were to have an absolute path at
 * hand, we cannot programmatically create such File objects to arbitrary
 * absolute paths on user's local filesystem for security reasons.
 *
 * So in the web context, this will always be a File we get as a result of an
 * explicit user interaction (e.g. drag and drop).
 *
 * In the desktop context, this can be either a File or a path.
 *
 * 1. If the user provided us this file via some user interaction (say a drag
 *    and a drop), this'll still be a File.
 *
 * 2. However, when running in the desktop app we have the ability to access
 *    absolute paths on the user's file system. For example, if the user asks us
 *    to watch certain folders on their disk for changes, we'll be able to pick
 *    up new images being added, and in such cases, the parameter here will be a
 *    path. Another example is when resuming an previously interrupted upload -
 *    we'll only have the path at hand in such cases, not the File object.
 *
 * The advantage of the File object is that the browser has already read it into
 * memory for us. The disadvantage comes in the case where we need to
 * communicate with the native Node.js layer of our desktop app. Since this
 * communication happens over IPC, the File's contents need to be serialized and
 * copied, which is a bummer for large videos etc.
 *
 * So when we do have a path, we first try to see if we can perform IPC using
 * the path itself (e.g. when generating thumbnails). Eventually, we'll need to
 * read the file once when we need to encrypt and upload it, but if we're smart
 * we can do all the rest of the IPC operations using the path itself, and for
 * the read during upload using a streaming IPC mechanism.
 */
const readFileOrPath = async (
    fileOrPath: File | string,
    fileTypeInfo: FileTypeInfo,
): Promise<FileInMemory> => {
    log.info(`Reading file ${fopLabel(fileOrPath)} `);

    let dataOrStream: Uint8Array | DataStream;
    if (fileOrPath instanceof File) {
        const file = fileOrPath;
        if (file.size > MULTIPART_PART_SIZE) {
            dataOrStream = getFileStream(file, FILE_READER_CHUNK_SIZE);
        } else {
            dataOrStream = new Uint8Array(await file.arrayBuffer());
        }
    } else {
        const path = fileOrPath;
        const { stream, size } = await readStream(path);
        if (size > MULTIPART_PART_SIZE) {
            const chunkCount = Math.ceil(size / FILE_READER_CHUNK_SIZE);
            dataOrStream = { stream, chunkCount };
        } else {
            dataOrStream = new Uint8Array(
                await new Response(stream).arrayBuffer(),
            );
        }
    }

    let filedata: Uint8Array | DataStream;

    // If it's a file, read-in its data. We need to do it once anyway for
    // generating the thumbnail.
    const dataOrPath =
        fileOrPath instanceof File
            ? new Uint8Array(await fileOrPath.arrayBuffer())
            : fileOrPath;

    // let thumbnail: Uint8Array;

    // const electron = globalThis.electron;
    // if (electron) {
    //     if  !moduleState.isNativeImageThumbnailCreationNotAvailable;
    //     try {
    //         return await generateImageThumbnailNative(electron, fileOrPath);
    //     } catch (e) {
    //         if (e.message == CustomErrorMessage.NotAvailable) {
    //             moduleState.isNativeThumbnailCreationNotAvailable = true;
    //         } else {
    //             log.error("Native thumbnail creation failed", e);
    //         }
    //     }
    // }

    // try {
    //     const thumbnail =
    //         fileTypeInfo.fileType === FILE_TYPE.IMAGE
    //             ? await generateImageThumbnailUsingCanvas(blob, fileTypeInfo)
    //             : await generateVideoThumbnail(blob);

    //     if (thumbnail.length == 0) throw new Error("Empty thumbnail");
    //     return { thumbnail, hasStaticThumbnail: false };
    // } catch (e) {
    //     log.error(`Failed to generate ${fileTypeInfo.exactType} thumbnail`, e);
    //     return { thumbnail: fallbackThumbnail(), hasStaticThumbnail: true };
    // }

    // if (filedata instanceof Uint8Array) {
    // } else {
    //     filedata.stream;
    // }

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
};

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
