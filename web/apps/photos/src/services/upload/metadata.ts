import { FILE_TYPE, type FileTypeInfo } from "@/media/file-type";
import { getFileNameSize } from "@/next/file";
import log from "@/next/log";
import { ElectronFile } from "@/next/types/file";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { CustomError } from "@ente/shared/error";
import {
    parseDateFromFusedDateString,
    tryToParseDateTime,
    validateAndGetCreationUnixTimeInMicroSeconds,
} from "@ente/shared/time";
import type { DataStream } from "@ente/shared/utils/data-stream";
import { Remote } from "comlink";
import { FILE_READER_CHUNK_SIZE, NULL_LOCATION } from "constants/upload";
import { parseImageMetadata } from "services/exif";
import * as ffmpegService from "services/ffmpeg";
import { getElectronFileStream, getFileStream } from "services/readerService";
import { FilePublicMagicMetadataProps } from "types/file";
import {
    Metadata,
    ParsedExtractedMetadata,
    type LivePhotoAssets2,
    type UploadAsset2,
} from "types/upload";
import {
    MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT,
    getClippedMetadataJSONMapKeyForFile,
    getMetadataJSONMapKeyForFile,
    type ParsedMetadataJSON,
} from "./takeout";
import { getFileName } from "./uploadService";

const NULL_EXTRACTED_METADATA: ParsedExtractedMetadata = {
    location: NULL_LOCATION,
    creationTime: null,
    width: null,
    height: null,
};

interface ExtractMetadataResult {
    metadata: Metadata;
    publicMagicMetadata: FilePublicMagicMetadataProps;
}

export const extractAssetMetadata = async (
    worker: Remote<DedicatedCryptoWorker>,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
    { isLivePhoto, file, livePhotoAssets }: UploadAsset2,
    collectionID: number,
    fileTypeInfo: FileTypeInfo,
): Promise<ExtractMetadataResult> => {
    return isLivePhoto
        ? await extractLivePhotoMetadata(
              worker,
              parsedMetadataJSONMap,
              collectionID,
              fileTypeInfo,
              livePhotoAssets,
          )
        : await extractFileMetadata(
              worker,
              parsedMetadataJSONMap,
              collectionID,
              fileTypeInfo,
              file,
          );
};

async function extractLivePhotoMetadata(
    worker: Remote<DedicatedCryptoWorker>,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
    collectionID: number,
    fileTypeInfo: FileTypeInfo,
    livePhotoAssets: LivePhotoAssets2,
): Promise<ExtractMetadataResult> {
    const imageFileTypeInfo: FileTypeInfo = {
        fileType: FILE_TYPE.IMAGE,
        extension: fileTypeInfo.imageType,
    };
    const {
        metadata: imageMetadata,
        publicMagicMetadata: imagePublicMagicMetadata,
    } = await extractFileMetadata(
        worker,
        parsedMetadataJSONMap,
        collectionID,
        imageFileTypeInfo,
        livePhotoAssets.image,
    );
    const videoHash = await getFileHash(
        worker,
        /* TODO(MR): ElectronFile changes */
        livePhotoAssets.video as File | ElectronFile,
    );
    return {
        metadata: {
            ...imageMetadata,
            title: getFileName(livePhotoAssets.image),
            fileType: FILE_TYPE.LIVE_PHOTO,
            imageHash: imageMetadata.hash,
            videoHash: videoHash,
            hash: undefined,
        },
        publicMagicMetadata: imagePublicMagicMetadata,
    };
}

async function extractFileMetadata(
    worker: Remote<DedicatedCryptoWorker>,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
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

async function extractMetadata(
    worker: Remote<DedicatedCryptoWorker>,
    receivedFile: File | ElectronFile,
    fileTypeInfo: FileTypeInfo,
): Promise<ExtractMetadataResult> {
    let extractedMetadata: ParsedExtractedMetadata = NULL_EXTRACTED_METADATA;
    if (fileTypeInfo.fileType === FILE_TYPE.IMAGE) {
        extractedMetadata = await getImageMetadata(receivedFile, fileTypeInfo);
    } else if (fileTypeInfo.fileType === FILE_TYPE.VIDEO) {
        extractedMetadata = await getVideoMetadata(receivedFile);
    }
    const hash = await getFileHash(worker, receivedFile);

    const metadata: Metadata = {
        title: receivedFile.name,
        creationTime:
            extractedMetadata.creationTime ??
            tryExtractDateFromFileName(receivedFile.name) ??
            receivedFile.lastModified * 1000,
        modificationTime: receivedFile.lastModified * 1000,
        latitude: extractedMetadata.location.latitude,
        longitude: extractedMetadata.location.longitude,
        fileType: fileTypeInfo.fileType,
        hash,
    };
    const publicMagicMetadata: FilePublicMagicMetadataProps = {
        w: extractedMetadata.width,
        h: extractedMetadata.height,
    };
    return { metadata, publicMagicMetadata };
}

async function getImageMetadata(
    receivedFile: File | ElectronFile,
    fileTypeInfo: FileTypeInfo,
): Promise<ParsedExtractedMetadata> {
    try {
        if (!(receivedFile instanceof File)) {
            receivedFile = new File(
                [await receivedFile.blob()],
                receivedFile.name,
                {
                    lastModified: receivedFile.lastModified,
                },
            );
        }
        return await parseImageMetadata(receivedFile, fileTypeInfo);
    } catch (e) {
        log.error("Failed to parse image metadata", e);
        return NULL_EXTRACTED_METADATA;
    }
}

/**
 * Try to extract a date from file name for certain known patterns.
 *
 * If it doesn't match a known pattern, or if there is some error during the
 * extraction, return `undefined`.
 */
const tryExtractDateFromFileName = (fileName: string): number | undefined => {
    try {
        fileName = fileName.trim();
        let parsedDate: Date;
        if (fileName.startsWith("IMG-") || fileName.startsWith("VID-")) {
            // WhatsApp media files
            // Sample name: IMG-20171218-WA0028.jpg
            parsedDate = parseDateFromFusedDateString(fileName.split("-")[1]);
        } else if (fileName.startsWith("Screenshot_")) {
            // Screenshots on Android
            // Sample name: Screenshot_20181227-152914.jpg
            parsedDate = parseDateFromFusedDateString(
                fileName.replaceAll("Screenshot_", ""),
            );
        } else if (fileName.startsWith("signal-")) {
            // Signal images
            // Sample name: signal-2018-08-21-100217.jpg
            const p = fileName.split("-");
            const dateString = `${p[1]}${p[2]}${p[3]}-${p[4]}`;
            parsedDate = parseDateFromFusedDateString(dateString);
        }
        if (!parsedDate) {
            parsedDate = tryToParseDateTime(fileName);
        }
        return validateAndGetCreationUnixTimeInMicroSeconds(parsedDate);
    } catch (e) {
        log.error(`Could not extract date from file name ${fileName}`, e);
        return undefined;
    }
};

async function getVideoMetadata(file: File | ElectronFile) {
    let videoMetadata = NULL_EXTRACTED_METADATA;
    try {
        log.info(`getVideoMetadata called for ${getFileNameSize(file)}`);
        videoMetadata = await ffmpegService.extractVideoMetadata(file);
        log.info(
            `videoMetadata successfully extracted ${getFileNameSize(file)}`,
        );
    } catch (e) {
        log.error("failed to get video metadata", e);
        log.info(
            `videoMetadata extracted failed ${getFileNameSize(file)} ,${
                e.message
            } `,
        );
    }

    return videoMetadata;
}

async function getFileHash(
    worker: Remote<DedicatedCryptoWorker>,
    file: File | ElectronFile,
) {
    try {
        log.info(`getFileHash called for ${getFileNameSize(file)}`);
        let filedata: DataStream;
        if (file instanceof File) {
            filedata = getFileStream(file, FILE_READER_CHUNK_SIZE);
        } else {
            filedata = await getElectronFileStream(
                file,
                FILE_READER_CHUNK_SIZE,
            );
        }
        const hashState = await worker.initChunkHashing();

        const streamReader = filedata.stream.getReader();
        for (let i = 0; i < filedata.chunkCount; i++) {
            const { done, value: chunk } = await streamReader.read();
            if (done) {
                throw Error(CustomError.CHUNK_LESS_THAN_EXPECTED);
            }
            await worker.hashFileChunk(hashState, Uint8Array.from(chunk));
        }
        const { done } = await streamReader.read();
        if (!done) {
            throw Error(CustomError.CHUNK_MORE_THAN_EXPECTED);
        }
        const hash = await worker.completeChunkHashing(hashState);
        log.info(
            `file hashing completed successfully ${getFileNameSize(file)}`,
        );
        return hash;
    } catch (e) {
        log.error("getFileHash failed", e);
        log.info(`file hashing failed ${getFileNameSize(file)} ,${e.message} `);
    }
}
