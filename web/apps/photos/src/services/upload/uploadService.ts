import { hasFileHash } from "@/media/file";
import { FILE_TYPE, type FileTypeInfo } from "@/media/file-type";
import { encodeLivePhoto } from "@/media/live-photo";
import type { Metadata } from "@/media/types/file";
import {
    EnteFile,
    MetadataFileAttributes,
    S3FileAttributes,
    type EncryptedEnteFile,
    type FilePublicMagicMetadata,
    type FilePublicMagicMetadataProps,
} from "@/new/photos/types/file";
import { EncryptedMagicMetadata } from "@/new/photos/types/magicMetadata";
import { ensureElectron } from "@/next/electron";
import { basename } from "@/next/file";
import log from "@/next/log";
import { CustomErrorMessage } from "@/next/types/ipc";
import { ensure } from "@/utils/ensure";
import { ENCRYPTION_CHUNK_SIZE } from "@ente/shared/crypto/constants";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import type { B64EncryptionResult } from "@ente/shared/crypto/types";
import { CustomError, handleUploadError } from "@ente/shared/error";
import type { Remote } from "comlink";
import {
    NULL_LOCATION,
    RANDOM_PERCENTAGE_PROGRESS_FOR_PUT,
    UPLOAD_RESULT,
} from "constants/upload";
import { addToCollection } from "services/collectionService";
import { parseImageMetadata } from "services/exif";
import * as ffmpeg from "services/ffmpeg";
import {
    PublicUploadProps,
    type LivePhotoAssets,
} from "services/upload/uploadManager";
import type { ParsedExtractedMetadata } from "types/metadata";
import {
    getNonEmptyMagicMetadataProps,
    updateMagicMetadata,
} from "utils/magicMetadata";
import { readStream } from "utils/native-stream";
import * as convert from "xml-js";
import { detectFileTypeInfoFromChunk } from "../detect-type";
import { tryParseEpochMicrosecondsFromFileName } from "./date";
import publicUploadHttpClient from "./publicUploadHttpClient";
import type { ParsedMetadataJSON } from "./takeout";
import { matchTakeoutMetadata } from "./takeout";
import {
    fallbackThumbnail,
    generateThumbnailNative,
    generateThumbnailWeb,
} from "./thumbnail";
import type { UploadItem } from "./types";
import UploadHttpClient from "./uploadHttpClient";
import type { UploadableUploadItem } from "./uploadManager";

/**
 * A readable stream for a file, and its associated size and last modified time.
 *
 * This is the in-memory representation of the {@link UploadItem} type that we
 * usually pass around. See: [Note: Reading a UploadItem]
 */
interface FileStream {
    /**
     * A stream of the file's contents
     *
     * This stream is guaranteed to emit data in ENCRYPTION_CHUNK_SIZE chunks
     * (except the last chunk which can be smaller since a file would rarely
     * align exactly to a ENCRYPTION_CHUNK_SIZE multiple).
     *
     * Note: A stream can only be read once!
     */
    stream: ReadableStream<Uint8Array>;
    /**
     * Number of chunks {@link stream} will emit, each ENCRYPTION_CHUNK_SIZE
     * sized (except the last one).
     */
    chunkCount: number;
    /**
     * The size in bytes of the underlying file.
     */
    fileSize: number;
    /**
     * The modification time of the file, in epoch milliseconds.
     */
    lastModifiedMs: number;
    /**
     * Set to the underlying {@link File} when we also have access to it.
     */
    file?: File;
}

/**
 * If the stream we have is more than 5 ENCRYPTION_CHUNK_SIZE chunks, then use
 * multipart uploads for it, with each multipart-part containing 5 chunks.
 *
 * ENCRYPTION_CHUNK_SIZE is 4 MB, and the number of chunks in a single upload
 * part is 5, so each part is (up to) 20 MB.
 */
const multipartChunksPerPart = 5;

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
 * Return the file name for the given {@link uploadItem}.
 */
export const uploadItemFileName = (uploadItem: UploadItem) => {
    if (uploadItem instanceof File) return uploadItem.name;
    if (typeof uploadItem == "string") return basename(uploadItem);
    if (Array.isArray(uploadItem)) return basename(uploadItem[1]);
    return uploadItem.file.name;
};

/* -- Various intermediate type used during upload -- */

interface UploadAsset {
    isLivePhoto?: boolean;
    uploadItem?: UploadItem;
    livePhotoAssets?: LivePhotoAssets;
}

interface ThumbnailedFile {
    fileStreamOrData: FileStream | Uint8Array;
    /** The JPEG data of the generated thumbnail */
    thumbnail: Uint8Array;
    /**
     * `true` if this is a fallback (all black) thumbnail we're returning since
     * thumbnail generation failed for some reason.
     */
    hasStaticThumbnail: boolean;
}

interface FileWithMetadata extends Omit<ThumbnailedFile, "hasStaticThumbnail"> {
    metadata: Metadata;
    localID: number;
    pubMagicMetadata: FilePublicMagicMetadata;
}

interface EncryptedFile {
    file: ProcessedFile;
    fileKey: B64EncryptionResult;
}

interface EncryptedFileStream {
    /**
     * A stream of the file's encrypted contents
     *
     * This stream is guaranteed to emit data in ENCRYPTION_CHUNK_SIZE chunks
     * (except the last chunk which can be smaller since a file would rarely
     * align exactly to a ENCRYPTION_CHUNK_SIZE multiple).
     */
    stream: ReadableStream<Uint8Array>;
    /**
     * Number of chunks {@link stream} will emit, each ENCRYPTION_CHUNK_SIZE
     * sized (except the last one).
     */
    chunkCount: number;
}

interface LocalFileAttributes<
    T extends string | Uint8Array | EncryptedFileStream,
> {
    encryptedData: T;
    decryptionHeader: string;
}

interface EncryptionResult<
    T extends string | Uint8Array | EncryptedFileStream,
> {
    file: LocalFileAttributes<T>;
    key: string;
}

interface ProcessedFile {
    file: LocalFileAttributes<Uint8Array | EncryptedFileStream>;
    thumbnail: LocalFileAttributes<Uint8Array>;
    metadata: LocalFileAttributes<string>;
    pubMagicMetadata: EncryptedMagicMetadata;
    localID: number;
}

export interface BackupedFile {
    file: S3FileAttributes;
    thumbnail: S3FileAttributes;
    metadata: MetadataFileAttributes;
    pubMagicMetadata: EncryptedMagicMetadata;
}

export interface UploadFile extends BackupedFile {
    collectionID: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
}

export interface MultipartUploadURLs {
    objectKey: string;
    partURLs: string[];
    completeURL: string;
}

export interface UploadURL {
    url: string;
    objectKey: string;
}

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
    uploadResult: UPLOAD_RESULT;
    uploadedFile?: EncryptedEnteFile | EnteFile;
}

/**
 * Upload the given {@link UploadableUploadItem}
 *
 * This is lower layer implementation of the upload. It is invoked by
 * {@link UploadManager} after it has assembled all the relevant bits we need to
 * go forth and upload.
 */
export const uploader = async (
    { collection, localID, fileName, ...uploadAsset }: UploadableUploadItem,
    uploaderName: string,
    existingFiles: EnteFile[],
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
    worker: Remote<DedicatedCryptoWorker>,
    isCFUploadProxyDisabled: boolean,
    abortIfCancelled: () => void,
    makeProgessTracker: MakeProgressTracker,
): Promise<UploadResponse> => {
    log.info(`Uploading ${fileName}`);
    try {
        /*
         * We read the file four times:
         * 1. To determine its MIME type (only needs first few KBs).
         * 2. To extract its metadata.
         * 3. To calculate its hash.
         * 4. To encrypt it.
         *
         * When we already have a File object the multiple reads are fine.
         *
         * When we're in the context of our desktop app and have a path, it
         * might be possible to optimize further by using `ReadableStream.tee`
         * to perform these steps simultaneously. However, that'll require
         * restructuring the code so that these steps run in a parallel manner
         * (tee will not work for strictly sequential reads of large streams).
         */

        const { fileTypeInfo, fileSize, lastModifiedMs } =
            await readAssetDetails(uploadAsset);

        const maxFileSize = 4 * 1024 * 1024 * 1024; /* 4 GB */
        if (fileSize >= maxFileSize)
            return { uploadResult: UPLOAD_RESULT.TOO_LARGE };

        abortIfCancelled();

        const { metadata, publicMagicMetadata } = await extractAssetMetadata(
            uploadAsset,
            fileTypeInfo,
            lastModifiedMs,
            collection.id,
            parsedMetadataJSONMap,
            worker,
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
                    uploadResult: UPLOAD_RESULT.ALREADY_UPLOADED,
                    uploadedFile: matchInSameCollection,
                };
            } else {
                // Any of the matching files can be used to add a symlink.
                const symlink = Object.assign({}, anyMatch);
                symlink.collectionID = collection.id;
                await addToCollection(collection, [symlink]);
                return {
                    uploadResult: UPLOAD_RESULT.ADDED_SYMLINK,
                    uploadedFile: symlink,
                };
            }
        }

        abortIfCancelled();

        const { fileStreamOrData, thumbnail, hasStaticThumbnail } =
            await readAsset(fileTypeInfo, uploadAsset);

        if (hasStaticThumbnail) metadata.hasStaticThumbnail = true;

        const pubMagicMetadata = await constructPublicMagicMetadata({
            ...publicMagicMetadata,
            uploaderName,
        });

        abortIfCancelled();

        const fileWithMetadata: FileWithMetadata = {
            localID,
            fileStreamOrData,
            thumbnail,
            metadata,
            pubMagicMetadata,
        };

        const encryptedFile = await encryptFile(
            fileWithMetadata,
            collection.key,
            worker,
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
            uploadResult: metadata.hasStaticThumbnail
                ? UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL
                : UPLOAD_RESULT.UPLOADED,
            uploadedFile: uploadedFile,
        };
    } catch (e) {
        if (e.message == CustomError.UPLOAD_CANCELLED) {
            log.info(`Upload for ${fileName} cancelled`);
        } else if (e.message == CustomError.UNSUPPORTED_FILE_FORMAT) {
            log.info(`Not uploading ${fileName}: unsupported file format`);
        } else {
            log.error(`Upload failed for ${fileName}`, e);
        }

        const error = handleUploadError(e);
        switch (error.message) {
            case CustomError.ETAG_MISSING:
                return { uploadResult: UPLOAD_RESULT.BLOCKED };
            case CustomError.UNSUPPORTED_FILE_FORMAT:
                return { uploadResult: UPLOAD_RESULT.UNSUPPORTED };
            case CustomError.FILE_TOO_LARGE:
                return {
                    uploadResult: UPLOAD_RESULT.LARGER_THAN_AVAILABLE_STORAGE,
                };
            default:
                return { uploadResult: UPLOAD_RESULT.FAILED };
        }
    }
};

/**
 * Read the given file or path or zip item into an in-memory representation.
 *
 * [Note: Reading a UploadItem]
 *
 * The file can be either a web
 * [File](https://developer.mozilla.org/en-US/docs/Web/API/File), the absolute
 * path to a file on desk, a combination of these two, or a entry in a zip file
 * on the user's local file system.
 *
 * tl;dr; There are four cases:
 *
 * 1. web / File
 * 2. desktop / File (+ path)
 * 3. desktop / path
 * 4. desktop / ZipItem
 *
 * For the when and why, read on.
 *
 * The code that accesses files (e.g. uplaads) gets invoked in two contexts:
 *
 * 1. web: the normal mode, when we're running in as a web app in the browser.
 *
 * 2. desktop: when we're running inside our desktop app.
 *
 * In the web context, we'll always get a File, since within the browser we
 * cannot programmatically construct paths to or arbitrarily access files on the
 * user's file system.
 *
 * > Note that even if we were to somehow have an absolute path at hand, we
 *   cannot programmatically create such File objects to arbitrary absolute
 *   paths on user's local file system for security reasons.
 *
 * So in the web context, this will always be a File we get as a result of an
 * explicit user interaction (e.g. drag and drop or using a file selector).
 *
 * In the desktop context, this can be either a File (+ path), or a path, or an
 * entry within a zip file.
 *
 * 2. If the user provided us this file via some user interaction (say a drag
 *    and a drop), this'll still be a File. But unlike in the web context, we
 *    also have access to the full path of this file.
 *
 * 3. In addition, when running in the desktop app we have the ability to
 *    initate programmatic access absolute paths on the user's file system. For
 *    example, if the user asks us to watch certain folders on their disk for
 *    changes, we'll be able to pick up new images being added, and in such
 *    cases, the parameter here will be a path. Another example is when resuming
 *    an previously interrupted upload - we'll only have the path at hand in
 *    such cases, not the original File object since the app subsequently
 *    restarted.
 *
 * 4. The user might've also initiated an upload of a zip file (or we might be
 *    resuming one). In such cases we will get a tuple (path to the zip file on
 *    the local file system, and the name of the entry within that zip file).
 *
 * Case 3 and 4, when we're provided a path, are simple. We don't have a choice,
 * since we cannot still programmatically construct a File object (we can
 * construct it on the Node.js layer, but it can't then be transferred over the
 * IPC boundary). So all our operations use the path itself.
 *
 * Case 2 involves a choice on a use-case basis. Neither File nor the path is a
 * better choice for all use cases.
 *
 * > The advantage of the File object is that the browser has already read it
 *   into memory for us. The disadvantage comes in the case where we need to
 *   communicate with the native Node.js layer of our desktop app. Since this
 *   communication happens over IPC, the File's contents need to be serialized
 *   and copied, which is a bummer for large videos etc.
 */
const readUploadItem = async (uploadItem: UploadItem): Promise<FileStream> => {
    let underlyingStream: ReadableStream;
    let file: File | undefined;
    let fileSize: number;
    let lastModifiedMs: number;

    if (typeof uploadItem == "string" || Array.isArray(uploadItem)) {
        const {
            response,
            size,
            lastModifiedMs: lm,
        } = await readStream(ensureElectron(), uploadItem);
        underlyingStream = response.body;
        fileSize = size;
        lastModifiedMs = lm;
    } else {
        if (uploadItem instanceof File) {
            file = uploadItem;
        } else {
            file = uploadItem.file;
        }
        underlyingStream = file.stream();
        fileSize = file.size;
        lastModifiedMs = file.lastModified;
    }

    const N = ENCRYPTION_CHUNK_SIZE;
    const chunkCount = Math.ceil(fileSize / ENCRYPTION_CHUNK_SIZE);

    // Pipe the underlying stream through a transformer that emits
    // ENCRYPTION_CHUNK_SIZE-ed chunks (except the last one, which can be
    // smaller).
    let pending: Uint8Array | undefined;
    const transformer = new TransformStream<Uint8Array, Uint8Array>({
        async transform(
            chunk: Uint8Array,
            controller: TransformStreamDefaultController,
        ) {
            let next: Uint8Array;
            if (pending) {
                next = new Uint8Array(pending.length + chunk.length);
                next.set(pending);
                next.set(chunk, pending.length);
                pending = undefined;
            } else {
                next = chunk;
            }
            while (next.length >= N) {
                controller.enqueue(next.slice(0, N));
                next = next.slice(N);
            }
            if (next.length) pending = next;
        },
        flush(controller: TransformStreamDefaultController) {
            if (pending) controller.enqueue(pending);
        },
    });

    const stream = underlyingStream.pipeThrough(transformer);

    return { stream, chunkCount, fileSize, lastModifiedMs, file };
};

interface ReadAssetDetailsResult {
    fileTypeInfo: FileTypeInfo;
    fileSize: number;
    lastModifiedMs: number;
}

/**
 * Read the associated file(s) to determine the type, size and last modified
 * time of the given {@link asset}.
 */
const readAssetDetails = async ({
    isLivePhoto,
    livePhotoAssets,
    uploadItem,
}: UploadAsset): Promise<ReadAssetDetailsResult> =>
    isLivePhoto
        ? readLivePhotoDetails(livePhotoAssets)
        : readImageOrVideoDetails(uploadItem);

const readLivePhotoDetails = async ({ image, video }: LivePhotoAssets) => {
    const img = await readImageOrVideoDetails(image);
    const vid = await readImageOrVideoDetails(video);

    return {
        fileTypeInfo: {
            fileType: FILE_TYPE.LIVE_PHOTO,
            extension: `${img.fileTypeInfo.extension}+${vid.fileTypeInfo.extension}`,
            imageType: img.fileTypeInfo.extension,
            videoType: vid.fileTypeInfo.extension,
        },
        fileSize: img.fileSize + vid.fileSize,
        lastModifiedMs: img.lastModifiedMs,
    };
};

/**
 * Read the beginning of the given file (or its path), or use its filename as a
 * fallback, to determine its MIME type. From that, construct and return a
 * {@link FileTypeInfo}.
 *
 * While we're at it, also return the size of the file, and its last modified
 * time (expressed as epoch milliseconds).
 *
 * @param uploadItem See: [Note: Reading a UploadItem]
 */
const readImageOrVideoDetails = async (uploadItem: UploadItem) => {
    const { stream, fileSize, lastModifiedMs } =
        await readUploadItem(uploadItem);

    const fileTypeInfo = await detectFileTypeInfoFromChunk(async () => {
        const reader = stream.getReader();
        const chunk = ensure((await reader.read()).value);
        await reader.cancel();
        return chunk;
    }, uploadItemFileName(uploadItem));

    return { fileTypeInfo, fileSize, lastModifiedMs };
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

interface ExtractAssetMetadataResult {
    metadata: Metadata;
    publicMagicMetadata: FilePublicMagicMetadataProps;
}

/**
 * Compute the hash, extract EXIF or other metadata, and merge in data from the
 * {@link parsedMetadataJSONMap} for the assets. Return the resultant metadatum.
 */
const extractAssetMetadata = async (
    { isLivePhoto, uploadItem, livePhotoAssets }: UploadAsset,
    fileTypeInfo: FileTypeInfo,
    lastModifiedMs: number,
    collectionID: number,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
    worker: Remote<DedicatedCryptoWorker>,
): Promise<ExtractAssetMetadataResult> =>
    isLivePhoto
        ? await extractLivePhotoMetadata(
              livePhotoAssets,
              fileTypeInfo,
              lastModifiedMs,
              collectionID,
              parsedMetadataJSONMap,
              worker,
          )
        : await extractImageOrVideoMetadata(
              uploadItem,
              fileTypeInfo,
              lastModifiedMs,
              collectionID,
              parsedMetadataJSONMap,
              worker,
          );

const extractLivePhotoMetadata = async (
    livePhotoAssets: LivePhotoAssets,
    fileTypeInfo: FileTypeInfo,
    lastModifiedMs: number,
    collectionID: number,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
    worker: Remote<DedicatedCryptoWorker>,
) => {
    const imageFileTypeInfo: FileTypeInfo = {
        fileType: FILE_TYPE.IMAGE,
        extension: fileTypeInfo.imageType,
    };
    const { metadata: imageMetadata, publicMagicMetadata } =
        await extractImageOrVideoMetadata(
            livePhotoAssets.image,
            imageFileTypeInfo,
            lastModifiedMs,
            collectionID,
            parsedMetadataJSONMap,
            worker,
        );

    const videoHash = await computeHash(livePhotoAssets.video, worker);

    return {
        metadata: {
            ...imageMetadata,
            title: uploadItemFileName(livePhotoAssets.image),
            fileType: FILE_TYPE.LIVE_PHOTO,
            imageHash: imageMetadata.hash,
            videoHash: videoHash,
            hash: undefined,
        },
        publicMagicMetadata,
    };
};

const extractImageOrVideoMetadata = async (
    uploadItem: UploadItem,
    fileTypeInfo: FileTypeInfo,
    lastModifiedMs: number,
    collectionID: number,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
    worker: Remote<DedicatedCryptoWorker>,
) => {
    const fileName = uploadItemFileName(uploadItem);
    const { fileType } = fileTypeInfo;

    let extractedMetadata: ParsedExtractedMetadata;
    if (fileType === FILE_TYPE.IMAGE) {
        extractedMetadata =
            (await tryExtractImageMetadata(
                uploadItem,
                fileTypeInfo,
                lastModifiedMs,
            )) ?? NULL_EXTRACTED_METADATA;
    } else if (fileType === FILE_TYPE.VIDEO) {
        extractedMetadata =
            (await tryExtractVideoMetadata(uploadItem)) ??
            NULL_EXTRACTED_METADATA;
    } else {
        throw new Error(`Unexpected file type ${fileType} for ${uploadItem}`);
    }

    const hash = await computeHash(uploadItem, worker);

    const modificationTime = lastModifiedMs * 1000;
    const creationTime =
        extractedMetadata.creationTime ??
        tryParseEpochMicrosecondsFromFileName(fileName) ??
        modificationTime;

    const metadata: Metadata = {
        title: fileName,
        creationTime,
        modificationTime,
        latitude: extractedMetadata.location.latitude,
        longitude: extractedMetadata.location.longitude,
        fileType,
        hash,
    };

    const publicMagicMetadata: FilePublicMagicMetadataProps = {
        w: extractedMetadata.width,
        h: extractedMetadata.height,
    };

    const takeoutMetadata = matchTakeoutMetadata(
        fileName,
        collectionID,
        parsedMetadataJSONMap,
    );

    if (takeoutMetadata)
        for (const [key, value] of Object.entries(takeoutMetadata))
            if (value) metadata[key] = value;

    return { metadata, publicMagicMetadata };
};

const NULL_EXTRACTED_METADATA: ParsedExtractedMetadata = {
    location: { ...NULL_LOCATION },
    creationTime: null,
    width: null,
    height: null,
};

async function tryExtractImageMetadata(
    uploadItem: UploadItem,
    fileTypeInfo: FileTypeInfo,
    lastModifiedMs: number,
): Promise<ParsedExtractedMetadata> {
    let file: File;
    if (typeof uploadItem == "string" || Array.isArray(uploadItem)) {
        // The library we use for extracting EXIF from images, exifr, doesn't
        // support streams. But unlike videos, for images it is reasonable to
        // read the entire stream into memory here.
        const { response } = await readStream(ensureElectron(), uploadItem);
        const path = typeof uploadItem == "string" ? uploadItem : uploadItem[1];
        file = new File([await response.arrayBuffer()], basename(path), {
            lastModified: lastModifiedMs,
        });
    } else if (uploadItem instanceof File) {
        file = uploadItem;
    } else {
        file = uploadItem.file;
    }

    try {
        return await parseImageMetadata(file, fileTypeInfo);
    } catch (e) {
        log.error(`Failed to extract image metadata for ${uploadItem}`, e);
        return undefined;
    }
}

const tryExtractVideoMetadata = async (uploadItem: UploadItem) => {
    try {
        return await ffmpeg.extractVideoMetadata(uploadItem);
    } catch (e) {
        log.error(`Failed to extract video metadata for ${uploadItem}`, e);
        return undefined;
    }
};

const computeHash = async (
    uploadItem: UploadItem,
    worker: Remote<DedicatedCryptoWorker>,
) => {
    const { stream, chunkCount } = await readUploadItem(uploadItem);
    const hashState = await worker.initChunkHashing();

    const streamReader = stream.getReader();
    for (let i = 0; i < chunkCount; i++) {
        const { done, value: chunk } = await streamReader.read();
        if (done) throw new Error("Less chunks than expected");
        await worker.hashFileChunk(hashState, Uint8Array.from(chunk));
    }

    const { done } = await streamReader.read();
    if (!done) throw new Error("More chunks than expected");
    return await worker.completeChunkHashing(hashState);
};

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

const readAsset = async (
    fileTypeInfo: FileTypeInfo,
    { isLivePhoto, uploadItem, livePhotoAssets }: UploadAsset,
): Promise<ThumbnailedFile> =>
    isLivePhoto
        ? await readLivePhoto(livePhotoAssets, fileTypeInfo)
        : await readImageOrVideo(uploadItem, fileTypeInfo);

const readLivePhoto = async (
    livePhotoAssets: LivePhotoAssets,
    fileTypeInfo: FileTypeInfo,
) => {
    const {
        fileStreamOrData: imageFileStreamOrData,
        thumbnail,
        hasStaticThumbnail,
    } = await withThumbnail(
        livePhotoAssets.image,
        {
            extension: fileTypeInfo.imageType,
            fileType: FILE_TYPE.IMAGE,
        },
        await readUploadItem(livePhotoAssets.image),
    );
    const videoFileStreamOrData = await readUploadItem(livePhotoAssets.video);

    // The JS zip library that encodeLivePhoto uses does not support
    // ReadableStreams, so pass the file (blob) if we have one, otherwise read
    // the entire stream into memory and pass the resultant data.
    //
    // This is a reasonable behaviour since the videos corresponding to live
    // photos are only a couple of seconds long (we've already done a pre-flight
    // check during areLivePhotoAssets to ensure their size is small).
    const fileOrData = async (sd: FileStream | Uint8Array) => {
        const fos = async ({ file, stream }: FileStream) =>
            file ? file : await readEntireStream(stream);
        return sd instanceof Uint8Array ? sd : fos(sd);
    };

    return {
        fileStreamOrData: await encodeLivePhoto({
            imageFileName: uploadItemFileName(livePhotoAssets.image),
            imageFileOrData: await fileOrData(imageFileStreamOrData),
            videoFileName: uploadItemFileName(livePhotoAssets.video),
            videoFileOrData: await fileOrData(videoFileStreamOrData),
        }),
        thumbnail,
        hasStaticThumbnail,
    };
};

const readImageOrVideo = async (
    uploadItem: UploadItem,
    fileTypeInfo: FileTypeInfo,
) => {
    const fileStream = await readUploadItem(uploadItem);
    return withThumbnail(uploadItem, fileTypeInfo, fileStream);
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
 * Augment the given {@link dataOrStream} with thumbnail information.
 *
 * This is a companion method for {@link readUploadItem}, and can be used to
 * convert the result of {@link readUploadItem} into an {@link ThumbnailedFile}.
 *
 * @param uploadItem The {@link UploadItem} where the given {@link fileStream}
 * came from.
 *
 * Note: The `fileStream` in the returned {@link ThumbnailedFile} may be
 * different from the one passed to the function.
 */
const withThumbnail = async (
    uploadItem: UploadItem,
    fileTypeInfo: FileTypeInfo,
    fileStream: FileStream,
): Promise<ThumbnailedFile> => {
    let fileData: Uint8Array | undefined;
    let thumbnail: Uint8Array | undefined;
    let hasStaticThumbnail = false;

    const electron = globalThis.electron;
    const notAvailable =
        fileTypeInfo.fileType == FILE_TYPE.IMAGE &&
        moduleState.isNativeImageThumbnailGenerationNotAvailable;

    // 1. Native thumbnail generation using items's (effective) path.
    if (electron && !notAvailable && !(uploadItem instanceof File)) {
        try {
            thumbnail = await generateThumbnailNative(
                electron,
                uploadItem,
                fileTypeInfo,
            );
        } catch (e) {
            if (e.message.endsWith(CustomErrorMessage.NotAvailable)) {
                moduleState.isNativeImageThumbnailGenerationNotAvailable = true;
            } else {
                log.error("Native thumbnail generation failed", e);
            }
        }
    }

    if (!thumbnail) {
        let blob: Blob | undefined;
        if (uploadItem instanceof File) {
            // 2. Browser based thumbnail generation for File (blobs).
            blob = uploadItem;
        } else {
            // 3. Browser based thumbnail generation for paths.
            //
            // There are two reasons why we could get here:
            //
            // - We're running under Electron, but thumbnail generation is not
            //   available. This is currently only a specific scenario for image
            //   files on Windows.
            //
            // - We're running under the Electron, but the thumbnail generation
            //   otherwise failed for some exception.
            //
            // The fallback in this case involves reading the entire stream into
            // memory, and passing that data across the IPC boundary in a single
            // go (i.e. not in a streaming manner). This is risky for videos of
            // unbounded sizes, plus we shouldn't even be getting here unless
            // something went wrong.
            //
            // So instead of trying to cater for arbitrary exceptions, we only
            // run this fallback to cover for the case where thumbnail
            // generation was not available for an image file on Windows.
            // If/when we add support of native thumbnailing on Windows too,
            // this entire branch can be removed.

            if (fileTypeInfo.fileType == FILE_TYPE.IMAGE) {
                const data = await readEntireStream(fileStream.stream);
                blob = new Blob([data]);

                // The Readable stream cannot be read twice, so use the data
                // directly for subsequent steps.
                fileData = data;
            } else {
                log.warn(
                    `Not using browser based thumbnail generation fallback for video at path ${uploadItem}`,
                );
            }
        }

        try {
            if (blob)
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
        fileStreamOrData: fileData ?? fileStream,
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

const encryptFile = async (
    file: FileWithMetadata,
    encryptionKey: string,
    worker: Remote<DedicatedCryptoWorker>,
): Promise<EncryptedFile> => {
    const { key: fileKey, file: encryptedFiledata } = await encryptFiledata(
        file.fileStreamOrData,
        worker,
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
            await worker.encryptMetadata(file.pubMagicMetadata.data, fileKey);
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
};

const encryptFiledata = async (
    fileStreamOrData: FileStream | Uint8Array,
    worker: Remote<DedicatedCryptoWorker>,
): Promise<EncryptionResult<Uint8Array | EncryptedFileStream>> =>
    fileStreamOrData instanceof Uint8Array
        ? await worker.encryptFile(fileStreamOrData)
        : await encryptFileStream(fileStreamOrData, worker);

const encryptFileStream = async (
    fileData: FileStream,
    worker: Remote<DedicatedCryptoWorker>,
) => {
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
};

const uploadToBucket = async (
    file: ProcessedFile,
    makeProgessTracker: MakeProgressTracker,
    isCFUploadProxyDisabled: boolean,
    abortIfCancelled: () => void,
): Promise<BackupedFile> => {
    try {
        let fileObjectKey: string = null;

        const encryptedData = file.file.encryptedData;
        if (
            !(encryptedData instanceof Uint8Array) &&
            encryptedData.chunkCount >= multipartChunksPerPart
        ) {
            // We have a stream, and it is more than multipartChunksPerPart
            // chunks long, so use a multipart upload to upload it.
            fileObjectKey = await uploadStreamUsingMultipart(
                file.localID,
                encryptedData,
                makeProgessTracker,
                isCFUploadProxyDisabled,
                abortIfCancelled,
            );
        } else {
            const data =
                encryptedData instanceof Uint8Array
                    ? encryptedData
                    : await readEntireStream(encryptedData.stream);

            const progressTracker = makeProgessTracker(file.localID);
            const fileUploadURL = await uploadService.getUploadURL();
            if (!isCFUploadProxyDisabled) {
                fileObjectKey = await UploadHttpClient.putFileV2(
                    fileUploadURL,
                    data,
                    progressTracker,
                );
            } else {
                fileObjectKey = await UploadHttpClient.putFile(
                    fileUploadURL,
                    data,
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
            log.error("Error when uploading to bucket", e);
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
    dataStream: EncryptedFileStream,
    makeProgessTracker: MakeProgressTracker,
    isCFUploadProxyDisabled: boolean,
    abortIfCancelled: () => void,
) {
    const uploadPartCount = Math.ceil(
        dataStream.chunkCount / multipartChunksPerPart,
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
    if (!done) throw new Error("More chunks than expected");

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
    for (let i = 0; i < multipartChunksPerPart; i++) {
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
