import {
    ENCRYPTION_CHUNK_SIZE,
    type B64EncryptionResult,
} from "@/base/crypto/libsodium";
import { type CryptoWorker } from "@/base/crypto/worker";
import { ensureElectron } from "@/base/electron";
import { basename, nameAndExtension } from "@/base/file";
import log from "@/base/log";
import { CustomErrorMessage } from "@/base/types/ipc";
import {
    EncryptedMagicMetadata,
    EnteFile,
    hasFileHash,
    MetadataFileAttributes,
    S3FileAttributes,
    type EncryptedEnteFile,
    type FilePublicMagicMetadata,
    type FilePublicMagicMetadataProps,
} from "@/media/file";
import type {
    Metadata,
    ParsedMetadata,
    PublicMagicMetadata,
} from "@/media/file-metadata";
import { FileType, type FileTypeInfo } from "@/media/file-type";
import { encodeLivePhoto } from "@/media/live-photo";
import { extractExif } from "@/new/photos/services/exif";
import * as ffmpeg from "@/new/photos/services/ffmpeg";
import {
    getNonEmptyMagicMetadataProps,
    updateMagicMetadata,
} from "@/new/photos/services/magic-metadata";
import type { UploadItem } from "@/new/photos/services/upload/types";
import {
    RANDOM_PERCENTAGE_PROGRESS_FOR_PUT,
    UPLOAD_RESULT,
} from "@/new/photos/services/upload/types";
import { detectFileTypeInfoFromChunk } from "@/new/photos/utils/detect-type";
import { readStream } from "@/new/photos/utils/native-stream";
import { ensure, ensureInteger, ensureNumber } from "@/utils/ensure";
import { CustomError, handleUploadError } from "@ente/shared/error";
import { addToCollection } from "services/collectionService";
import {
    PublicUploadProps,
    type LivePhotoAssets,
} from "services/upload/uploadManager";
import * as convert from "xml-js";
import { tryParseEpochMicrosecondsFromFileName } from "./date";
import publicUploadHttpClient from "./publicUploadHttpClient";
import type { ParsedMetadataJSON } from "./takeout";
import { matchTakeoutMetadata } from "./takeout";
import {
    fallbackThumbnail,
    generateThumbnailNative,
    generateThumbnailWeb,
} from "./thumbnail";
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

interface EncryptedMetadata {
    encryptedDataB64: string;
    decryptionHeaderB64: string;
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
    metadata: EncryptedMetadata;
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

export interface PotentialLivePhotoAsset {
    fileName: string;
    fileType: FileType;
    collectionID: number;
    uploadItem: UploadItem;
}

/**
 * Check if the two given assets should be clubbed together as a live photo.
 */
export const areLivePhotoAssets = async (
    f: PotentialLivePhotoAsset,
    g: PotentialLivePhotoAsset,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
) => {
    if (f.collectionID != g.collectionID) return false;

    const [fName, fExt] = nameAndExtension(f.fileName);
    const [gName, gExt] = nameAndExtension(g.fileName);

    let fPrunedName: string;
    let gPrunedName: string;
    if (f.fileType == FileType.image && g.fileType == FileType.video) {
        fPrunedName = removePotentialLivePhotoSuffix(
            fName,
            // A Google Live Photo image file can have video extension appended
            // as suffix, so we pass that to removePotentialLivePhotoSuffix to
            // remove it.
            //
            // Example: IMG_20210630_0001.mp4.jpg (Google Live Photo image file)
            gExt ? `.${gExt}` : undefined,
        );
        gPrunedName = removePotentialLivePhotoSuffix(gName);
    } else if (f.fileType == FileType.video && g.fileType == FileType.image) {
        fPrunedName = removePotentialLivePhotoSuffix(fName);
        gPrunedName = removePotentialLivePhotoSuffix(
            gName,
            fExt ? `.${fExt}` : undefined,
        );
    } else {
        return false;
    }

    if (fPrunedName != gPrunedName) return false;

    // Also check that the size of an individual Live Photo asset is less than
    // an (arbitrary) limit. This should be true in practice as the videos for a
    // live photo are a few seconds long. Further on, the zipping library that
    // we use doesn't support stream as a input.

    const maxAssetSize = 20 * 1024 * 1024; /* 20MB */
    const fSize = await uploadItemSize(f.uploadItem);
    const gSize = await uploadItemSize(g.uploadItem);
    if (fSize > maxAssetSize || gSize > maxAssetSize) {
        log.info(
            `Not classifying files with too large sizes (${fSize} and ${gSize} bytes) as a live photo`,
        );
        return false;
    }

    // Finally, ensure that the creation times of the image and video are within
    // some epsilon of each other. This is to avoid clubbing together unrelated
    // items that coincidentally have the same name (this is not uncommon since,
    // e.g. many cameras use a deterministic numbering scheme).

    const fParsedMetadataJSON = matchTakeoutMetadata(
        f.fileName,
        f.collectionID,
        parsedMetadataJSONMap,
    );

    const gParsedMetadataJSON = matchTakeoutMetadata(
        g.fileName,
        g.collectionID,
        parsedMetadataJSONMap,
    );

    const fDate = await uploadItemCreationDate(
        f.uploadItem,
        f.fileType,
        fParsedMetadataJSON,
    );
    const gDate = await uploadItemCreationDate(
        g.uploadItem,
        g.fileType,
        gParsedMetadataJSON,
    );

    // The exact threshold to use is hard to decide. The times should be usually
    // exact to minute, but it is possible that one of the items is missing the
    // timezone while the other has it. Their dates (as shown by the app) would
    // both be correct, just the UTC epochs will vary.
    //
    // Using a threshold of 1 day makes the app more robust to such timezone
    // discrepancies while only marginally increasing the risk of false
    // positives. But this is a heuristic that might not always be correct.
    const thresholdSeconds = 24 * 60 * 60; /* 1 day */
    const haveSameishDate =
        fDate && gDate && Math.abs(fDate - gDate) / 1e6 < thresholdSeconds;

    if (!haveSameishDate) {
        // Google does not include the metadata JSON for the video part of the
        // live photo in the Takeout, causing this date check to fail.
        //
        // So only incorporate this check if either neither file has a metadata
        // JSON, or both have it.
        if (
            (!fParsedMetadataJSON && !gParsedMetadataJSON) ||
            (fParsedMetadataJSON && gParsedMetadataJSON)
        ) {
            return false;
        }
    }

    // All checks pass. Club these two as a live photo.
    return true;
};

const removePotentialLivePhotoSuffix = (name: string, suffix?: string) => {
    const suffix_3 = "_3";

    // The icloud-photos-downloader library appends _HVEC to the end of the
    // filename in case of live photos.
    //
    // https://github.com/icloud-photos-downloader/icloud_photos_downloader
    const suffix_hvec = "_HVEC";

    let foundSuffix: string | undefined;
    if (name.endsWith(suffix_3)) {
        foundSuffix = suffix_3;
    } else if (
        name.endsWith(suffix_hvec) ||
        name.endsWith(suffix_hvec.toLowerCase())
    ) {
        foundSuffix = suffix_hvec;
    } else if (suffix) {
        if (name.endsWith(suffix) || name.endsWith(suffix.toLowerCase())) {
            foundSuffix = suffix;
        }
    }

    return foundSuffix ? name.slice(0, foundSuffix.length * -1) : name;
};

/**
 * Return the size of the given {@link uploadItem}.
 */
const uploadItemSize = async (uploadItem: UploadItem): Promise<number> => {
    if (uploadItem instanceof File) return uploadItem.size;
    if (typeof uploadItem == "string")
        return ensureElectron().pathOrZipItemSize(uploadItem);
    if (Array.isArray(uploadItem))
        return ensureElectron().pathOrZipItemSize(uploadItem);
    return uploadItem.file.size;
};

/**
 * Return the creation date for the given {@link uploadItem}.
 *
 * [Note: Duplicate retrieval of creation date for live photo clubbing]
 *
 * This function duplicates some logic of {@link extractImageOrVideoMetadata}.
 * This duplication, while not good, is currently unavoidable with the way the
 * code is structured since the live photo clubbing happens at an earlier time
 * in the pipeline when we don't have the Exif data, but the Exif data is needed
 * to determine the file's creation time (to ensure that we only club photos and
 * videos with close by creation times, instead of just relying on file names).
 *
 * Note that unlike {@link extractImageOrVideoMetadata}, we don't try to
 * fallback to the file's modification time. This is because for the purpose of
 * live photo clubbing, we wish to use the creation date only in cases where we
 * have it.
 */
const uploadItemCreationDate = async (
    uploadItem: UploadItem,
    fileType: FileType,
    parsedMetadataJSON: ParsedMetadataJSON | undefined,
) => {
    if (parsedMetadataJSON?.creationTime)
        return parsedMetadataJSON?.creationTime;

    let parsedMetadata: ParsedMetadata | undefined;
    if (fileType == FileType.image) {
        parsedMetadata = await tryExtractImageMetadata(uploadItem, undefined);
    } else if (fileType == FileType.video) {
        parsedMetadata = await tryExtractVideoMetadata(uploadItem);
    } else {
        throw new Error(`Unexpected file type ${fileType} for ${uploadItem}`);
    }

    return parsedMetadata?.creationDate?.timestamp;
};

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
    worker: CryptoWorker,
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
            fileType: FileType.livePhoto,
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
 * Compute the hash, extract Exif or other metadata, and merge in data from the
 * {@link parsedMetadataJSONMap} for the assets. Return the resultant metadatum.
 */
const extractAssetMetadata = async (
    { isLivePhoto, uploadItem, livePhotoAssets }: UploadAsset,
    fileTypeInfo: FileTypeInfo,
    lastModifiedMs: number,
    collectionID: number,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
    worker: CryptoWorker,
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
    worker: CryptoWorker,
) => {
    const imageFileTypeInfo: FileTypeInfo = {
        fileType: FileType.image,
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
            fileType: FileType.livePhoto,
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
    worker: CryptoWorker,
) => {
    const fileName = uploadItemFileName(uploadItem);
    const { fileType } = fileTypeInfo;

    let parsedMetadata: ParsedMetadata | undefined;
    if (fileType == FileType.image) {
        parsedMetadata = await tryExtractImageMetadata(
            uploadItem,
            lastModifiedMs,
        );
    } else if (fileType == FileType.video) {
        parsedMetadata = await tryExtractVideoMetadata(uploadItem);
    } else {
        throw new Error(`Unexpected file type ${fileType} for ${uploadItem}`);
    }

    const hash = await computeHash(uploadItem, worker);

    // Some of this logic is duplicated in `uploadItemCreationDate`.
    //
    // See: [Note: Duplicate retrieval of creation date for live photo clubbing]

    const parsedMetadataJSON = matchTakeoutMetadata(
        fileName,
        collectionID,
        parsedMetadataJSONMap,
    );

    const publicMagicMetadata: PublicMagicMetadata = {};

    const modificationTime =
        parsedMetadataJSON?.modificationTime ?? lastModifiedMs * 1000;

    let creationTime: number;
    if (parsedMetadataJSON?.creationTime) {
        creationTime = parsedMetadataJSON.creationTime;
    } else if (parsedMetadata?.creationDate) {
        const { dateTime, offset, timestamp } = parsedMetadata.creationDate;
        creationTime = timestamp;
        publicMagicMetadata.dateTime = dateTime;
        if (offset) publicMagicMetadata.offsetTime = offset;
    } else {
        creationTime =
            tryParseEpochMicrosecondsFromFileName(fileName) ?? modificationTime;
    }

    // To avoid introducing malformed data into the metadata fields (which the
    // other clients might not expect and handle), we have extra "ensure" checks
    // here that act as a safety valve if somehow the TypeScript type is lying.
    //
    // There is no deterministic sample we found that necessitated adding these
    // extra checks, but we did get one user with a list in the width field of
    // the metadata (it should've been an integer). The most probable theory is
    // that somehow it made its way in through malformed Exif.

    const metadata: Metadata = {
        fileType,
        title: fileName,
        creationTime: ensureInteger(creationTime),
        modificationTime: ensureInteger(modificationTime),
        hash,
    };

    const location = parsedMetadataJSON?.location ?? parsedMetadata?.location;
    if (location) {
        metadata.latitude = ensureNumber(location.latitude);
        metadata.longitude = ensureNumber(location.longitude);
    }

    if (parsedMetadata) {
        const { width: w, height: h } = parsedMetadata;
        if (w) publicMagicMetadata.w = ensureInteger(w);
        if (h) publicMagicMetadata.h = ensureInteger(h);
    }

    const caption = parsedMetadataJSON?.description;
    if (caption) {
        publicMagicMetadata.caption = caption;
    }

    return { metadata, publicMagicMetadata };
};

const tryExtractImageMetadata = async (
    uploadItem: UploadItem,
    lastModifiedMs: number | undefined,
): Promise<ParsedMetadata> => {
    let file: File;
    if (typeof uploadItem == "string" || Array.isArray(uploadItem)) {
        // The library we use for extracting Exif from images, ExifReader,
        // doesn't support streams. But unlike videos, for images it is
        // reasonable to read the entire stream into memory here.
        const { response } = await readStream(ensureElectron(), uploadItem);
        const path = typeof uploadItem == "string" ? uploadItem : uploadItem[1];
        const opts = lastModifiedMs ? { lastModified: lastModifiedMs } : {};
        file = new File([await response.arrayBuffer()], basename(path), opts);
    } else if (uploadItem instanceof File) {
        file = uploadItem;
    } else {
        file = uploadItem.file;
    }

    try {
        return extractExif(file);
    } catch (e) {
        log.error(`Failed to extract image metadata for ${uploadItem}`, e);
        return undefined;
    }
};

const tryExtractVideoMetadata = async (uploadItem: UploadItem) => {
    try {
        return await ffmpeg.extractVideoMetadata(uploadItem);
    } catch (e) {
        log.error(`Failed to extract video metadata for ${uploadItem}`, e);
        return undefined;
    }
};

const computeHash = async (uploadItem: UploadItem, worker: CryptoWorker) => {
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
    if (f.fileType === FileType.livePhoto) {
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
            fileType: FileType.image,
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
        fileTypeInfo.fileType == FileType.image &&
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
            // We can only get here when we're running in our desktop app (since
            // only that works with non-File uploadItems), and the thumbnail
            // generation failed.
            //
            // The only know scenario is when we're trying to generate an image
            // thumbnail on Windows or on ARM64 Linux, or are trying to
            // generated the thumbnail for an HEIC file on Linux. This won't be
            // possible since the bundled imagemagick doesn't yet support these
            // OS/arch combinations.
            //
            // The fallback in this case involves reading the entire stream into
            // memory, and passing that data across the IPC boundary in a single
            // go (i.e. not in a streaming manner). This is risky for videos of
            // unbounded sizes, and since anyways we are not expected to come
            // here for videos, soo we only apply this fallback for images.

            if (fileTypeInfo.fileType == FileType.image) {
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
    worker: CryptoWorker,
): Promise<EncryptedFile> => {
    const { key: fileKey, file: encryptedFiledata } = await encryptFiledata(
        file.fileStreamOrData,
        worker,
    );

    const {
        encryptedData: thumbEncryptedData,
        decryptionHeader: thumbDecryptionHeader,
    } = await worker.encryptThumbnail(file.thumbnail, fileKey);
    const encryptedThumbnail = {
        encryptedData: thumbEncryptedData,
        decryptionHeader: thumbDecryptionHeader,
    };

    const encryptedMetadata = await worker.encryptMetadataJSON({
        jsonValue: file.metadata,
        keyB64: fileKey,
    });

    let encryptedPubMagicMetadata: EncryptedMagicMetadata;
    if (file.pubMagicMetadata) {
        const encryptedPubMagicMetadataData = await worker.encryptMetadataJSON({
            jsonValue: file.pubMagicMetadata.data,
            keyB64: fileKey,
        });
        encryptedPubMagicMetadata = {
            version: file.pubMagicMetadata.version,
            count: file.pubMagicMetadata.count,
            data: encryptedPubMagicMetadataData.encryptedDataB64,
            header: encryptedPubMagicMetadataData.decryptionHeaderB64,
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
    worker: CryptoWorker,
): Promise<EncryptionResult<Uint8Array | EncryptedFileStream>> =>
    fileStreamOrData instanceof Uint8Array
        ? await worker.encryptFile(fileStreamOrData)
        : await encryptFileStream(fileStreamOrData, worker);

const encryptFileStream = async (
    fileData: FileStream,
    worker: CryptoWorker,
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
            metadata: {
                encryptedData: file.metadata.encryptedDataB64,
                decryptionHeader: file.metadata.decryptionHeaderB64,
            },
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
