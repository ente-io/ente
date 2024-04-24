import { FILE_TYPE } from "@/media/file";
import { encodeLivePhoto } from "@/media/live-photo";
import { ensureElectron } from "@/next/electron";
import { basename } from "@/next/file";
import log from "@/next/log";
import { ElectronFile } from "@/next/types/file";
import { CustomErrorMessage } from "@/next/types/ipc";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { EncryptionResult } from "@ente/shared/crypto/types";
import { CustomError, handleUploadError } from "@ente/shared/error";
import { isDataStream, type DataStream } from "@ente/shared/utils/data-stream";
import { Remote } from "comlink";
import {
    FILE_CHUNKS_COMBINED_FOR_A_UPLOAD_PART,
    FILE_READER_CHUNK_SIZE,
    MULTIPART_PART_SIZE,
    RANDOM_PERCENTAGE_PROGRESS_FOR_PUT,
    UPLOAD_RESULT,
} from "constants/upload";
import { addToCollection } from "services/collectionService";
import {
    EnteFile,
    type FilePublicMagicMetadata,
    type FilePublicMagicMetadataProps,
} from "types/file";
import { EncryptedMagicMetadata } from "types/magicMetadata";
import {
    BackupedFile,
    EncryptedFile,
    FileInMemory,
    FileTypeInfo,
    FileWithMetadata,
    ProcessedFile,
    PublicUploadProps,
    UploadAsset,
    UploadFile,
    UploadURL,
    type FileWithCollection2,
    type LivePhotoAssets,
    type LivePhotoAssets2,
    type Metadata,
    type UploadAsset2,
} from "types/upload";
import {
    getNonEmptyMagicMetadataProps,
    updateMagicMetadata,
} from "utils/magicMetadata";
import { readStream } from "utils/native-stream";
import { hasFileHash } from "utils/upload";
import * as convert from "xml-js";
import { getFileStream } from "../readerService";
import { getFileType } from "../typeDetectionService";
import { extractAssetMetadata } from "./metadata";
import publicUploadHttpClient from "./publicUploadHttpClient";
import type { ParsedMetadataJSON } from "./takeout";
import {
    fallbackThumbnail,
    generateThumbnailNative,
    generateThumbnailWeb,
} from "./thumbnail";
import uploadCancelService from "./uploadCancelService";
import UploadHttpClient from "./uploadHttpClient";

/** Upload files to cloud storage */
class UploadService {
    private uploadURLs: UploadURL[] = [];
    private pendingUploadCount: number = 0;
    private publicUploadProps: PublicUploadProps = undefined;

    init(publicUploadProps: PublicUploadProps) {
        this.publicUploadProps = publicUploadProps;
    }

    async setFileCount(fileCount: number) {
        this.pendingUploadCount = fileCount;
        await this.preFetchUploadURLs();
    }

    reducePendingUploadCount() {
        this.pendingUploadCount--;
    }

    async getUploadURL() {
        if (this.uploadURLs.length === 0 && this.pendingUploadCount) {
            await this.fetchUploadURLs();
        }
        return this.uploadURLs.pop();
    }

    private async preFetchUploadURLs() {
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

/**
 * A function that can be called to obtain a "progressTracker" that then is
 * directly fed to axios to both cancel the upload if needed, and update the
 * progress status.
 *
 * Enhancement: The return value needs to be typed.
 */
type MakeProgressTracker = (
    fileLocalID: number,
    percentPerPart?: number,
    index?: number,
) => unknown;

interface UploadResponse {
    fileUploadResult: UPLOAD_RESULT;
    uploadedFile?: EnteFile;
}

export const uploader = async (
    worker: Remote<DedicatedCryptoWorker>,
    existingFiles: EnteFile[],
    fileWithCollection: FileWithCollection2,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
    uploaderName: string,
    isCFUploadProxyDisabled: boolean,
    makeProgessTracker: MakeProgressTracker,
): Promise<UploadResponse> => {
    const name = assetName(fileWithCollection);
    log.info(`Uploading ${name}`);

    const abortIfCancelled = () => {
        if (uploadCancelService.isUploadCancelationRequested())
            throw Error(CustomError.UPLOAD_CANCELLED);
    };

    const { collection, localID, ...uploadAsset2 } = fileWithCollection;
    /* TODO(MR): ElectronFile changes */
    const uploadAsset = uploadAsset2 as UploadAsset;
    let fileTypeInfo: FileTypeInfo;
    let fileSize: number;
    try {
        const maxFileSize = 4 * 1024 * 1024 * 1024; // 4 GB

        fileSize = getAssetSize(uploadAsset);
        if (fileSize >= maxFileSize) {
            return { fileUploadResult: UPLOAD_RESULT.TOO_LARGE };
        }
        fileTypeInfo = await getAssetFileType(uploadAsset);

        const { metadata, publicMagicMetadata } = await extractAssetMetadata(
            worker,
            parsedMetadataJSONMap,
            uploadAsset2,
            collection.id,
            fileTypeInfo,
        );

        const matches = existingFiles.filter((file) =>
            areFilesSame(file.metadata, metadata),
        );

        const anyMatch = matches?.length > 0 ? matches[0] : undefined;

        if (anyMatch) {
            const matchInSameCollection = matches.find(
                (f) => f.collectionID == collection.id,
            );
            if (matchInSameCollection) {
                return {
                    fileUploadResult: UPLOAD_RESULT.ALREADY_UPLOADED,
                    uploadedFile: matchInSameCollection,
                };
            } else {
                // Any of the matching files can be used to add a symlink.
                const symlink = Object.assign({}, anyMatch);
                symlink.collectionID = collection.id;
                await addToCollection(collection, [symlink]);
                return {
                    fileUploadResult: UPLOAD_RESULT.ADDED_SYMLINK,
                    uploadedFile: symlink,
                };
            }
        }

        abortIfCancelled();

        const file = await readAsset(fileTypeInfo, uploadAsset2);

        if (file.hasStaticThumbnail) metadata.hasStaticThumbnail = true;

        const pubMagicMetadata = await constructPublicMagicMetadata({
            ...publicMagicMetadata,
            uploaderName,
        });

        abortIfCancelled();

        const fileWithMetadata: FileWithMetadata = {
            localID,
            filedata: file.filedata,
            thumbnail: file.thumbnail,
            metadata,
            pubMagicMetadata,
        };

        const encryptedFile = await encryptFile(
            worker,
            fileWithMetadata,
            collection.key,
        );

        abortIfCancelled();

        const backupedFile = await uploadToBucket(
            encryptedFile.file,
            makeProgessTracker,
            isCFUploadProxyDisabled,
            abortIfCancelled,
        );

        const uploadedFile = await uploadService.uploadFile({
            collectionID: collection.id,
            encryptedKey: encryptedFile.fileKey.encryptedData,
            keyDecryptionNonce: encryptedFile.fileKey.nonce,
            ...backupedFile,
        });

        return {
            fileUploadResult: metadata.hasStaticThumbnail
                ? UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL
                : UPLOAD_RESULT.UPLOADED,
            uploadedFile: uploadedFile,
        };
    } catch (e) {
        if (e.message == CustomError.UPLOAD_CANCELLED) {
            log.info(`Upload for ${name} cancelled`);
        } else if (e.message == CustomError.UNSUPPORTED_FILE_FORMAT) {
            log.info(`Not uploading ${name}: unsupported file format`);
        } else {
            log.error(`Upload failed for ${name}`, e);
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
};

export const getFileName = (file: File | ElectronFile | string) =>
    typeof file == "string" ? basename(file) : file.name;

function getFileSize(file: File | ElectronFile) {
    return file.size;
}
export const getAssetName = ({
    isLivePhoto,
    file,
    livePhotoAssets,
}: UploadAsset) =>
    isLivePhoto ? getFileName(livePhotoAssets.image) : getFileName(file);

export const assetName = ({
    isLivePhoto,
    file,
    livePhotoAssets,
}: UploadAsset2) =>
    isLivePhoto ? getFileName(livePhotoAssets.image) : getFileName(file);

const getAssetSize = ({ isLivePhoto, file, livePhotoAssets }: UploadAsset) => {
    return isLivePhoto ? getLivePhotoSize(livePhotoAssets) : getFileSize(file);
};

const getLivePhotoSize = (livePhotoAssets: LivePhotoAssets) => {
    return livePhotoAssets.image.size + livePhotoAssets.video.size;
};

const getAssetFileType = ({
    isLivePhoto,
    file,
    livePhotoAssets,
}: UploadAsset) => {
    return isLivePhoto
        ? getLivePhotoFileType(livePhotoAssets)
        : getFileType(file);
};

const getLivePhotoFileType = async (
    livePhotoAssets: LivePhotoAssets,
): Promise<FileTypeInfo> => {
    const imageFileTypeInfo = await getFileType(livePhotoAssets.image);
    const videoFileTypeInfo = await getFileType(livePhotoAssets.video);
    return {
        fileType: FILE_TYPE.LIVE_PHOTO,
        exactType: `${imageFileTypeInfo.exactType}+${videoFileTypeInfo.exactType}`,
        imageType: imageFileTypeInfo.exactType,
        videoType: videoFileTypeInfo.exactType,
    };
};

const readAsset = async (
    fileTypeInfo: FileTypeInfo,
    { isLivePhoto, file, livePhotoAssets }: UploadAsset2,
) => {
    return isLivePhoto
        ? await readLivePhoto(livePhotoAssets, fileTypeInfo)
        : await readImageOrVideo(file, fileTypeInfo);
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
    isNativeImageThumbnailGenerationNotAvailable = false;
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
): Promise<{ dataOrStream: Uint8Array | DataStream; fileSize: number }> => {
    let dataOrStream: Uint8Array | DataStream;
    let fileSize: number;

    if (fileOrPath instanceof File) {
        const file = fileOrPath;
        fileSize = file.size;
        dataOrStream =
            fileSize > MULTIPART_PART_SIZE
                ? getFileStream(file, FILE_READER_CHUNK_SIZE)
                : new Uint8Array(await file.arrayBuffer());
    } else {
        const path = fileOrPath;
        const { response, size } = await readStream(ensureElectron(), path);
        fileSize = size;
        if (size > MULTIPART_PART_SIZE) {
            const chunkCount = Math.ceil(size / FILE_READER_CHUNK_SIZE);
            dataOrStream = { stream: response.body, chunkCount };
        } else {
            dataOrStream = new Uint8Array(await response.arrayBuffer());
        }
    }

    return { dataOrStream, fileSize };
};

/**
 * Augment the given {@link dataOrStream} with thumbnail information.
 *
 * This is a companion method for {@link readFileOrPath}, and can be used to
 * convert the result of {@link readFileOrPath} into an {@link FileInMemory}.
 *
 * Note: The returned dataOrStream might be different from the one that we
 * provide to it.
 */
const withThumbnail = async (
    fileOrPath: File | string,
    fileTypeInfo: FileTypeInfo,
    dataOrStream: Uint8Array | DataStream,
    fileSize: number,
): Promise<FileInMemory> => {
    let thumbnail: Uint8Array | undefined;
    let hasStaticThumbnail = false;

    const electron = globalThis.electron;
    const notAvailable =
        fileTypeInfo.fileType == FILE_TYPE.IMAGE &&
        moduleState.isNativeImageThumbnailGenerationNotAvailable;

    // 1. Native thumbnail generation.
    if (electron && !notAvailable) {
        try {
            if (fileOrPath instanceof File) {
                if (dataOrStream instanceof Uint8Array) {
                    thumbnail = await generateThumbnailNative(
                        electron,
                        dataOrStream,
                        fileTypeInfo,
                    );
                } else {
                    // This was large enough to need streaming, and trying to
                    // read it into memory or copying over IPC might cause us to
                    // run out of memory. So skip the native generation for it,
                    // instead let it get processed by the browser based
                    // thumbnailer (case 2).
                }
            } else {
                thumbnail = await generateThumbnailNative(
                    electron,
                    fileOrPath,
                    fileTypeInfo,
                );
            }
        } catch (e) {
            if (e.message == CustomErrorMessage.NotAvailable) {
                moduleState.isNativeImageThumbnailGenerationNotAvailable = true;
            } else {
                log.error("Native thumbnail generation failed", e);
            }
        }
    }

    if (!thumbnail) {
        let blob: Blob | undefined;
        if (fileOrPath instanceof File) {
            // 2. Browser based thumbnail generation for `File`s.
            blob = fileOrPath;
        } else {
            // 3. Browser based thumbnail generation for paths.
            if (dataOrStream instanceof Uint8Array) {
                blob = new Blob([dataOrStream]);
            } else {
                // Read the stream into memory. Don't try this fallback for huge
                // files though lest we run out of memory.
                if (fileSize < 100 * 1024 * 1024 /* 100 MB */) {
                    const data = await readEntireStream(dataOrStream.stream);
                    // The Readable stream cannot be read twice, so also
                    // overwrite the stream with the data we read.
                    dataOrStream = data;
                    blob = new Blob([data]);
                } else {
                    // There isn't a normal scenario where this should happen.
                    // Case 1, should've already worked, and the only known
                    // reason it'd have been  skipped is for image files on
                    // Windows, but those should be less than 100 MB.
                    //
                    // So don't risk running out of memory for a case we don't
                    // comprehend.
                    log.error(
                        `Not using browser based thumbnail generation fallback for large file at path ${fileOrPath}`,
                    );
                }
            }
        }

        try {
            thumbnail = await generateThumbnailWeb(blob, fileTypeInfo);
        } catch (e) {
            log.error("Web thumbnail creation failed", e);
        }
    }

    if (!thumbnail) {
        thumbnail = fallbackThumbnail();
        hasStaticThumbnail = true;
    }

    return {
        filedata: dataOrStream,
        thumbnail,
        hasStaticThumbnail,
    };
};

/**
 * Read the entirety of a readable stream.
 *
 * It is not recommended to use this for large (say, multi-hundred MB) files. It
 * is provided as a syntactic shortcut for cases where we already know that the
 * size of the stream will be reasonable enough to be read in its entirety
 * without us running out of memory.
 */
const readEntireStream = async (stream: ReadableStream) =>
    new Uint8Array(await new Response(stream).arrayBuffer());

const readImageOrVideo = async (
    fileOrPath: File | string,
    fileTypeInfo: FileTypeInfo,
) => {
    const { dataOrStream, fileSize } = await readFileOrPath(fileOrPath);
    return withThumbnail(fileOrPath, fileTypeInfo, dataOrStream, fileSize);
};

const readLivePhoto = async (
    livePhotoAssets: LivePhotoAssets2,
    fileTypeInfo: FileTypeInfo,
) => {
    const readImage = await readFileOrPath(livePhotoAssets.image);
    const {
        filedata: imageDataOrStream,
        thumbnail,
        hasStaticThumbnail,
    } = await withThumbnail(
        livePhotoAssets.image,
        {
            exactType: fileTypeInfo.imageType,
            fileType: FILE_TYPE.IMAGE,
        },
        readImage.dataOrStream,
        readImage.fileSize,
    );
    const readVideo = await readFileOrPath(livePhotoAssets.video);

    // We can revisit this later, but the existing code always read the
    // full files into memory here, and to avoid changing the rest of
    // the scaffolding retain the same behaviour.
    //
    // This is a reasonable assumption too, since the videos
    // corresponding to live photos are only a couple of seconds long.
    const toData = async (dataOrStream: Uint8Array | DataStream) =>
        dataOrStream instanceof Uint8Array
            ? dataOrStream
            : await readEntireStream(dataOrStream.stream);

    return {
        filedata: await encodeLivePhoto({
            imageFileName: getFileName(livePhotoAssets.image),
            imageData: await toData(imageDataOrStream),
            videoFileName: getFileName(livePhotoAssets.video),
            videoData: await toData(readVideo.dataOrStream),
        }),
        thumbnail,
        hasStaticThumbnail,
    };
};

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

/**
 * Return true if the two files, as represented by their metadata, are same.
 *
 * Note that the metadata includes the hash of the file's contents (when
 * available), so this also in effect compares the contents of the files, not
 * just the "meta" information about them.
 */
const areFilesSame = (f: Metadata, g: Metadata) =>
    hasFileHash(f) && hasFileHash(g)
        ? areFilesSameHash(f, g)
        : areFilesSameNoHash(f, g);

const areFilesSameHash = (f: Metadata, g: Metadata) => {
    if (f.fileType !== g.fileType || f.title !== g.title) {
        return false;
    }
    if (f.fileType === FILE_TYPE.LIVE_PHOTO) {
        return f.imageHash === g.imageHash && f.videoHash === g.videoHash;
    } else {
        return f.hash === g.hash;
    }
};

/**
 * Older files that were uploaded before we introduced hashing will not have
 * hashes, so retain and use the logic we used back then for such files.
 *
 * Deprecation notice April 2024: Note that hashing was introduced very early
 * (years ago), so the chance of us finding files without hashes is rare. And
 * even in these cases, the worst that'll happen is that a duplicate file would
 * get uploaded which can later be deduped. So we can get rid of this case at
 * some point (e.g. the mobile app doesn't do this extra check, just uploads).
 */
const areFilesSameNoHash = (f: Metadata, g: Metadata) => {
    /*
     * The maximum difference in the creation/modification times of two similar
     * files is set to 1 second. This is because while uploading files in the
     * web - browsers and users could have set reduced precision of file times
     * to prevent timing attacks and fingerprinting.
     *
     * See:
     * https://developer.mozilla.org/en-US/docs/Web/API/File/lastModified#reduced_time_precision
     */
    const oneSecond = 1e6;
    return (
        f.fileType == g.fileType &&
        f.title == g.title &&
        Math.abs(f.creationTime - g.creationTime) < oneSecond &&
        Math.abs(f.modificationTime - g.modificationTime) < oneSecond
    );
};

const uploadToBucket = async (
    file: ProcessedFile,
    makeProgessTracker: MakeProgressTracker,
    isCFUploadProxyDisabled: boolean,
    abortIfCancelled: () => void,
): Promise<BackupedFile> => {
    try {
        let fileObjectKey: string = null;

        if (isDataStream(file.file.encryptedData)) {
            fileObjectKey = await uploadStreamUsingMultipart(
                file.localID,
                file.file.encryptedData,
                makeProgessTracker,
                isCFUploadProxyDisabled,
                abortIfCancelled,
            );
        } else {
            const progressTracker = makeProgessTracker(file.localID);
            const fileUploadURL = await uploadService.getUploadURL();
            if (!isCFUploadProxyDisabled) {
                fileObjectKey = await UploadHttpClient.putFileV2(
                    fileUploadURL,
                    file.file.encryptedData as Uint8Array,
                    progressTracker,
                );
            } else {
                fileObjectKey = await UploadHttpClient.putFile(
                    fileUploadURL,
                    file.file.encryptedData as Uint8Array,
                    progressTracker,
                );
            }
        }
        const thumbnailUploadURL = await uploadService.getUploadURL();
        let thumbnailObjectKey: string = null;
        if (!isCFUploadProxyDisabled) {
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
};

interface PartEtag {
    PartNumber: number;
    ETag: string;
}

async function uploadStreamUsingMultipart(
    fileLocalID: number,
    dataStream: DataStream,
    makeProgessTracker: MakeProgressTracker,
    isCFUploadProxyDisabled: boolean,
    abortIfCancelled: () => void,
) {
    const uploadPartCount = Math.ceil(
        dataStream.chunkCount / FILE_CHUNKS_COMBINED_FOR_A_UPLOAD_PART,
    );
    const multipartUploadURLs =
        await uploadService.fetchMultipartUploadURLs(uploadPartCount);

    const { stream } = dataStream;

    const streamReader = stream.getReader();
    const percentPerPart =
        RANDOM_PERCENTAGE_PROGRESS_FOR_PUT() / uploadPartCount;
    const partEtags: PartEtag[] = [];
    for (const [
        index,
        fileUploadURL,
    ] of multipartUploadURLs.partURLs.entries()) {
        abortIfCancelled();

        const uploadChunk = await combineChunksToFormUploadPart(streamReader);
        const progressTracker = makeProgessTracker(
            fileLocalID,
            percentPerPart,
            index,
        );
        let eTag = null;
        if (!isCFUploadProxyDisabled) {
            eTag = await UploadHttpClient.putFilePartV2(
                fileUploadURL,
                uploadChunk,
                progressTracker,
            );
        } else {
            eTag = await UploadHttpClient.putFilePart(
                fileUploadURL,
                uploadChunk,
                progressTracker,
            );
        }
        partEtags.push({ PartNumber: index + 1, ETag: eTag });
    }
    const { done } = await streamReader.read();
    if (!done) {
        throw Error(CustomError.CHUNK_MORE_THAN_EXPECTED);
    }

    const completeURL = multipartUploadURLs.completeURL;
    const cBody = convert.js2xml(
        { CompleteMultipartUpload: { Part: partEtags } },
        { compact: true, ignoreComment: true, spaces: 4 },
    );
    if (!isCFUploadProxyDisabled) {
        await UploadHttpClient.completeMultipartUploadV2(completeURL, cBody);
    } else {
        await UploadHttpClient.completeMultipartUpload(completeURL, cBody);
    }

    return multipartUploadURLs.objectKey;
}

async function combineChunksToFormUploadPart(
    streamReader: ReadableStreamDefaultReader<Uint8Array>,
) {
    const combinedChunks = [];
    for (let i = 0; i < FILE_CHUNKS_COMBINED_FOR_A_UPLOAD_PART; i++) {
        const { done, value: chunk } = await streamReader.read();
        if (done) {
            break;
        }
        for (let index = 0; index < chunk.length; index++) {
            combinedChunks.push(chunk[index]);
        }
    }
    return Uint8Array.from(combinedChunks);
}
