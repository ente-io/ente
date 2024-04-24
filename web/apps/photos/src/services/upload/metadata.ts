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
import { getEXIFLocation, getEXIFTime, getParsedExifData } from "services/exif";
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

const EXIF_TAGS_NEEDED = [
    "DateTimeOriginal",
    "CreateDate",
    "ModifyDate",
    "GPSLatitude",
    "GPSLongitude",
    "GPSLatitudeRef",
    "GPSLongitudeRef",
    "DateCreated",
    "ExifImageWidth",
    "ExifImageHeight",
    "ImageWidth",
    "ImageHeight",
    "PixelXDimension",
    "PixelYDimension",
    "MetadataDate",
];

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
            extractDateFromFileName(receivedFile.name) ??
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
    let imageMetadata = NULL_EXTRACTED_METADATA;
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
        const exifData = await getParsedExifData(
            receivedFile,
            fileTypeInfo,
            EXIF_TAGS_NEEDED,
        );

        imageMetadata = {
            location: getEXIFLocation(exifData),
            creationTime: getEXIFTime(exifData),
            width: exifData?.imageWidth ?? null,
            height: exifData?.imageHeight ?? null,
        };
    } catch (e) {
        log.error("getExifData failed", e);
    }
    return imageMetadata;
}

// tries to extract date from file name if available else returns null
function extractDateFromFileName(filename: string): number {
    try {
        filename = filename.trim();
        let parsedDate: Date;
        if (filename.startsWith("IMG-") || filename.startsWith("VID-")) {
            // Whatsapp media files
            // sample name IMG-20171218-WA0028.jpg
            parsedDate = parseDateFromFusedDateString(filename.split("-")[1]);
        } else if (filename.startsWith("Screenshot_")) {
            // Screenshots on droid
            // sample name Screenshot_20181227-152914.jpg
            parsedDate = parseDateFromFusedDateString(
                filename.replaceAll("Screenshot_", ""),
            );
        } else if (filename.startsWith("signal-")) {
            // signal images
            // sample name :signal-2018-08-21-100217.jpg
            const dateString = convertSignalNameToFusedDateString(filename);
            parsedDate = parseDateFromFusedDateString(dateString);
        }
        if (!parsedDate) {
            parsedDate = tryToParseDateTime(filename);
        }
        return validateAndGetCreationUnixTimeInMicroSeconds(parsedDate);
    } catch (e) {
        log.error("failed to extract date From FileName ", e);
        return null;
    }
}

function convertSignalNameToFusedDateString(filename: string) {
    const dateStringParts = filename.split("-");
    return `${dateStringParts[1]}${dateStringParts[2]}${dateStringParts[3]}-${dateStringParts[4]}`;
}

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

async function extractLivePhotoMetadata(
    worker: Remote<DedicatedCryptoWorker>,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
    collectionID: number,
    fileTypeInfo: FileTypeInfo,
    livePhotoAssets: LivePhotoAssets2,
): Promise<ExtractMetadataResult> {
    const imageFileTypeInfo: FileTypeInfo = {
        fileType: FILE_TYPE.IMAGE,
        exactType: fileTypeInfo.imageType,
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
