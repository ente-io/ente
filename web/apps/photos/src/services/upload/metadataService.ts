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
import uploadCancelService from "./uploadCancelService";
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

interface LivePhotoIdentifier {
    collectionID: number;
    fileType: FILE_TYPE;
    name: string;
    size: number;
}

const UNDERSCORE_THREE = "_3";
// Note: The icloud-photos-downloader library appends _HVEC to the end of the filename in case of live photos
// https://github.com/icloud-photos-downloader/icloud_photos_downloader
const UNDERSCORE_HEVC = "_HVEC";

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

export async function clusterLivePhotoFiles(mediaFiles: FileWithCollection2[]) {
    try {
        const analysedMediaFiles: FileWithCollection2[] = [];
        mediaFiles
            .sort((firstMediaFile, secondMediaFile) =>
                splitFilenameAndExtension(
                    getFileName(firstMediaFile.file),
                )[0].localeCompare(
                    splitFilenameAndExtension(
                        getFileName(secondMediaFile.file),
                    )[0],
                ),
            )
            .sort(
                (firstMediaFile, secondMediaFile) =>
                    firstMediaFile.collectionID - secondMediaFile.collectionID,
            );
        let index = 0;
        while (index < mediaFiles.length - 1) {
            if (uploadCancelService.isUploadCancelationRequested()) {
                throw Error(CustomError.UPLOAD_CANCELLED);
            }
            const firstMediaFile = mediaFiles[index];
            const secondMediaFile = mediaFiles[index + 1];
            const firstFileType =
                getFileTypeFromExtensionForLivePhotoClustering(
                    getFileName(firstMediaFile.file),
                );
            const secondFileType =
                getFileTypeFromExtensionForLivePhotoClustering(
                    getFileName(secondMediaFile.file),
                );
            const firstFileIdentifier: LivePhotoIdentifier = {
                collectionID: firstMediaFile.collectionID,
                fileType: firstFileType,
                name: getFileName(firstMediaFile.file),
                /* TODO(MR): ElectronFile changes */
                size: (firstMediaFile as FileWithCollection).file.size,
            };
            const secondFileIdentifier: LivePhotoIdentifier = {
                collectionID: secondMediaFile.collectionID,
                fileType: secondFileType,
                name: getFileName(secondMediaFile.file),
                /* TODO(MR): ElectronFile changes */
                size: (secondMediaFile as FileWithCollection).file.size,
            };
            if (
                areFilesLivePhotoAssets(
                    firstFileIdentifier,
                    secondFileIdentifier,
                )
            ) {
                let imageFile: File | ElectronFile | string;
                let videoFile: File | ElectronFile | string;
                if (
                    firstFileType === FILE_TYPE.IMAGE &&
                    secondFileType === FILE_TYPE.VIDEO
                ) {
                    imageFile = firstMediaFile.file;
                    videoFile = secondMediaFile.file;
                } else {
                    videoFile = firstMediaFile.file;
                    imageFile = secondMediaFile.file;
                }
                const livePhotoLocalID = firstMediaFile.localID;
                analysedMediaFiles.push({
                    localID: livePhotoLocalID,
                    collectionID: firstMediaFile.collectionID,
                    isLivePhoto: true,
                    livePhotoAssets: {
                        image: imageFile,
                        video: videoFile,
                    },
                });
                index += 2;
            } else {
                analysedMediaFiles.push({
                    ...firstMediaFile,
                    isLivePhoto: false,
                });
                index += 1;
            }
        }
        if (index === mediaFiles.length - 1) {
            analysedMediaFiles.push({
                ...mediaFiles[index],
                isLivePhoto: false,
            });
        }
        return analysedMediaFiles;
    } catch (e) {
        if (e.message === CustomError.UPLOAD_CANCELLED) {
            throw e;
        } else {
            log.error("failed to cluster live photo", e);
            throw e;
        }
    }
}

function areFilesLivePhotoAssets(
    firstFileIdentifier: LivePhotoIdentifier,
    secondFileIdentifier: LivePhotoIdentifier,
) {
    const haveSameCollectionID =
        firstFileIdentifier.collectionID === secondFileIdentifier.collectionID;
    const areNotSameFileType =
        firstFileIdentifier.fileType !== secondFileIdentifier.fileType;

    let firstFileNameWithoutSuffix: string;
    let secondFileNameWithoutSuffix: string;
    if (firstFileIdentifier.fileType === FILE_TYPE.IMAGE) {
        firstFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(firstFileIdentifier.name),
            // Note: The Google Live Photo image file can have video extension appended as suffix, passing that to removePotentialLivePhotoSuffix to remove it
            // Example: IMG_20210630_0001.mp4.jpg (Google Live Photo image file)
            getFileExtensionWithDot(secondFileIdentifier.name),
        );
        secondFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(secondFileIdentifier.name),
        );
    } else {
        firstFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(firstFileIdentifier.name),
        );
        secondFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(secondFileIdentifier.name),
            getFileExtensionWithDot(firstFileIdentifier.name),
        );
    }
    if (
        haveSameCollectionID &&
        isImageOrVideo(firstFileIdentifier.fileType) &&
        isImageOrVideo(secondFileIdentifier.fileType) &&
        areNotSameFileType &&
        firstFileNameWithoutSuffix === secondFileNameWithoutSuffix
    ) {
        const LIVE_PHOTO_ASSET_SIZE_LIMIT = 20 * 1024 * 1024; // 20MB

        // checks size of live Photo assets are less than allowed limit
        // I did that based on the assumption that live photo assets ideally would not be larger than LIVE_PHOTO_ASSET_SIZE_LIMIT
        // also zipping library doesn't support stream as a input
        if (
            firstFileIdentifier.size <= LIVE_PHOTO_ASSET_SIZE_LIMIT &&
            secondFileIdentifier.size <= LIVE_PHOTO_ASSET_SIZE_LIMIT
        ) {
            return true;
        } else {
            log.error(
                `${CustomError.TOO_LARGE_LIVE_PHOTO_ASSETS} - ${JSON.stringify({
                    fileSizes: [
                        firstFileIdentifier.size,
                        secondFileIdentifier.size,
                    ],
                })}`,
            );
        }
    }
    return false;
}

function removePotentialLivePhotoSuffix(
    filenameWithoutExtension: string,
    suffix?: string,
) {
    let presentSuffix: string;
    if (filenameWithoutExtension.endsWith(UNDERSCORE_THREE)) {
        presentSuffix = UNDERSCORE_THREE;
    } else if (filenameWithoutExtension.endsWith(UNDERSCORE_HEVC)) {
        presentSuffix = UNDERSCORE_HEVC;
    } else if (
        filenameWithoutExtension.endsWith(UNDERSCORE_HEVC.toLowerCase())
    ) {
        presentSuffix = UNDERSCORE_HEVC.toLowerCase();
    } else if (suffix) {
        if (filenameWithoutExtension.endsWith(suffix)) {
            presentSuffix = suffix;
        } else if (filenameWithoutExtension.endsWith(suffix.toLowerCase())) {
            presentSuffix = suffix.toLowerCase();
        }
    }
    if (presentSuffix) {
        return filenameWithoutExtension.slice(0, presentSuffix.length * -1);
    } else {
        return filenameWithoutExtension;
    }
}

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

function splitFilenameAndExtension(filename: string): [string, string] {
    const lastDotPosition = filename.lastIndexOf(".");
    if (lastDotPosition === -1) return [filename, null];
    else
        return [
            filename.slice(0, lastDotPosition),
            filename.slice(lastDotPosition + 1),
        ];
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
