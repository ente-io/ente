import { getFileNameSize, nameAndExtension } from "@/next/file";
import log from "@/next/log";
import { ElectronFile } from "@/next/types/file";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { CustomError } from "@ente/shared/error";
import {
    parseDateFromFusedDateString,
    tryToParseDateTime,
    validateAndGetCreationUnixTimeInMicroSeconds,
} from "@ente/shared/time";
import { Remote } from "comlink";
import { FILE_TYPE } from "constants/file";
import { FILE_READER_CHUNK_SIZE, NULL_LOCATION } from "constants/upload";
import * as ffmpegService from "services/ffmpeg";
import { getElectronFileStream, getFileStream } from "services/readerService";
import { getFileType } from "services/typeDetectionService";
import { FilePublicMagicMetadataProps } from "types/file";
import {
    FileTypeInfo,
    LivePhotoAssets,
    Metadata,
    ParsedExtractedMetadata,
    type DataStream,
    type FileWithCollection,
    type FileWithCollection2,
    type LivePhotoAssets2,
    type UploadAsset2,
} from "types/upload";
import { getFileTypeFromExtensionForLivePhotoClustering } from "utils/file/livePhoto";
import { getEXIFLocation, getEXIFTime, getParsedExifData } from "./exifService";
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

export const NULL_EXTRACTED_METADATA: ParsedExtractedMetadata = {
    location: NULL_LOCATION,
    creationTime: null,
    width: null,
    height: null,
};

export interface ExtractMetadataResult {
    metadata: Metadata;
    publicMagicMetadata: FilePublicMagicMetadataProps;
}

export async function extractMetadata(
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
    const fileHash = await getFileHash(worker, receivedFile);

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
        hash: fileHash,
    };
    const publicMagicMetadata: FilePublicMagicMetadataProps = {
        w: extractedMetadata.width,
        h: extractedMetadata.height,
    };
    return { metadata, publicMagicMetadata };
}

export async function getImageMetadata(
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
export function extractDateFromFileName(filename: string): number {
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

export async function getLivePhotoFileType(
    livePhotoAssets: LivePhotoAssets,
): Promise<FileTypeInfo> {
    const imageFileTypeInfo = await getFileType(livePhotoAssets.image);
    const videoFileTypeInfo = await getFileType(livePhotoAssets.video);
    return {
        fileType: FILE_TYPE.LIVE_PHOTO,
        exactType: `${imageFileTypeInfo.exactType}+${videoFileTypeInfo.exactType}`,
        imageType: imageFileTypeInfo.exactType,
        videoType: videoFileTypeInfo.exactType,
    };
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

export function getLivePhotoSize(livePhotoAssets: LivePhotoAssets) {
    return livePhotoAssets.image.size + livePhotoAssets.video.size;
}

/**
 * Go through the given files, combining any sibling image + video assets into a
 * single live photo when appropriate.
 */
export const clusterLivePhotos = (mediaFiles: FileWithCollection2[]) => {
    const result: FileWithCollection2[] = [];
    mediaFiles
        .sort((f, g) =>
            nameAndExtension(getFileName(f.file))[0].localeCompare(
                nameAndExtension(getFileName(g.file))[0],
            ),
        )
        .sort((f, g) => f.collectionID - g.collectionID);
    let index = 0;
    while (index < mediaFiles.length - 1) {
        const f = mediaFiles[index];
        const g = mediaFiles[index + 1];
        const fFileType = getFileTypeFromExtensionForLivePhotoClustering(
            getFileName(f.file),
        );
        const gFileType = getFileTypeFromExtensionForLivePhotoClustering(
            getFileName(g.file),
        );
        const fFileIdentifier: LivePhotoIdentifier = {
            collectionID: f.collectionID,
            fileType: fFileType,
            name: getFileName(f.file),
            /* TODO(MR): ElectronFile changes */
            size: (f as FileWithCollection).file.size,
        };
        const gFileIdentifier: LivePhotoIdentifier = {
            collectionID: g.collectionID,
            fileType: gFileType,
            name: getFileName(g.file),
            /* TODO(MR): ElectronFile changes */
            size: (g as FileWithCollection).file.size,
        };
        if (areLivePhotoAssets(fFileIdentifier, gFileIdentifier)) {
            let imageFile: File | ElectronFile | string;
            let videoFile: File | ElectronFile | string;
            if (
                fFileType === FILE_TYPE.IMAGE &&
                gFileType === FILE_TYPE.VIDEO
            ) {
                imageFile = f.file;
                videoFile = g.file;
            } else {
                videoFile = f.file;
                imageFile = g.file;
            }
            const livePhotoLocalID = f.localID;
            result.push({
                localID: livePhotoLocalID,
                collectionID: f.collectionID,
                isLivePhoto: true,
                livePhotoAssets: {
                    image: imageFile,
                    video: videoFile,
                },
            });
            index += 2;
        } else {
            result.push({
                ...f,
                isLivePhoto: false,
            });
            index += 1;
        }
    }
    if (index === mediaFiles.length - 1) {
        result.push({
            ...mediaFiles[index],
            isLivePhoto: false,
        });
    }
    return result;
};

interface LivePhotoIdentifier {
    collectionID: number;
    fileType: FILE_TYPE;
    name: string;
    size: number;
}

const areLivePhotoAssets = (f: LivePhotoIdentifier, g: LivePhotoIdentifier) => {
    const haveSameCollectionID = f.collectionID === g.collectionID;
    const areNotSameFileType = f.fileType !== g.fileType;

    let firstFileNameWithoutSuffix: string;
    let secondFileNameWithoutSuffix: string;
    if (f.fileType === FILE_TYPE.IMAGE) {
        firstFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(f.name),
            // Note: The Google Live Photo image file can have video extension appended as suffix, passing that to removePotentialLivePhotoSuffix to remove it
            // Example: IMG_20210630_0001.mp4.jpg (Google Live Photo image file)
            getFileExtensionWithDot(g.name),
        );
        secondFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(g.name),
        );
    } else {
        firstFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(f.name),
        );
        secondFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(g.name),
            getFileExtensionWithDot(f.name),
        );
    }
    if (
        haveSameCollectionID &&
        isImageOrVideo(f.fileType) &&
        isImageOrVideo(g.fileType) &&
        areNotSameFileType &&
        firstFileNameWithoutSuffix === secondFileNameWithoutSuffix
    ) {
        const LIVE_PHOTO_ASSET_SIZE_LIMIT = 20 * 1024 * 1024; // 20MB

        // checks size of live Photo assets are less than allowed limit
        // I did that based on the assumption that live photo assets ideally would not be larger than LIVE_PHOTO_ASSET_SIZE_LIMIT
        // also zipping library doesn't support stream as a input
        if (
            f.size <= LIVE_PHOTO_ASSET_SIZE_LIMIT &&
            g.size <= LIVE_PHOTO_ASSET_SIZE_LIMIT
        ) {
            return true;
        } else {
            log.error(
                `${CustomError.TOO_LARGE_LIVE_PHOTO_ASSETS} - ${JSON.stringify({
                    fileSizes: [f.size, g.size],
                })}`,
            );
        }
    }
    return false;
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

function getFileNameWithoutExtension(filename: string) {
    const lastDotPosition = filename.lastIndexOf(".");
    if (lastDotPosition === -1) return filename;
    else return filename.slice(0, lastDotPosition);
}

function getFileExtensionWithDot(filename: string) {
    const lastDotPosition = filename.lastIndexOf(".");
    if (lastDotPosition === -1) return "";
    else return filename.slice(lastDotPosition);
}

const isImageOrVideo = (fileType: FILE_TYPE) =>
    [FILE_TYPE.IMAGE, FILE_TYPE.VIDEO].includes(fileType);

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
