import { encodeLivePhoto } from "@/media/live-photo";
import { getFileNameSize } from "@/next/file";
import log from "@/next/log";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { CustomError } from "@ente/shared/error";
import {
    parseDateFromFusedDateString,
    tryToParseDateTime,
    validateAndGetCreationUnixTimeInMicroSeconds,
} from "@ente/shared/time";
import { Remote } from "comlink";
import { FILE_TYPE } from "constants/file";
import {
    LIVE_PHOTO_ASSET_SIZE_LIMIT,
    NULL_EXTRACTED_METADATA,
    NULL_LOCATION,
} from "constants/upload";
import * as ffmpegService from "services/ffmpeg/ffmpegService";
import { getFileType } from "services/typeDetectionService";
import { FilePublicMagicMetadataProps } from "types/file";
import {
    ElectronFile,
    ExtractMetadataResult,
    FileTypeInfo,
    FileWithCollection,
    LivePhotoAssets,
    Location,
    Metadata,
    ParsedExtractedMetadata,
    ParsedMetadataJSON,
    ParsedMetadataJSONMap,
} from "types/upload";
import { getFileTypeFromExtensionForLivePhotoClustering } from "utils/file/livePhoto";
import { getUint8ArrayView } from "../readerService";
import { getEXIFLocation, getEXIFTime, getParsedExifData } from "./exifService";
import { getFileHash } from "./hashService";
import { generateThumbnail } from "./thumbnailService";
import uploadCancelService from "./uploadCancelService";
import { extractFileMetadata } from "./uploadService";

const NULL_PARSED_METADATA_JSON: ParsedMetadataJSON = {
    creationTime: null,
    modificationTime: null,
    ...NULL_LOCATION,
};

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

export const MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT = 46;

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

export const getMetadataJSONMapKeyForJSON = (
    collectionID: number,
    jsonFileName: string,
) => {
    let title = jsonFileName.slice(0, -1 * ".json".length);
    const endsWithNumberedSuffixWithBrackets = title.match(/\(\d+\)$/);
    if (endsWithNumberedSuffixWithBrackets) {
        title = title.slice(
            0,
            -1 * endsWithNumberedSuffixWithBrackets[0].length,
        );
        const [name, extension] = splitFilenameAndExtension(title);
        return `${collectionID}-${name}${endsWithNumberedSuffixWithBrackets[0]}.${extension}`;
    }
    return `${collectionID}-${title}`;
};

// if the file name is greater than MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT(46) , then google photos clips the file name
// so we need to use the clipped file name to get the metadataJSON file
export const getClippedMetadataJSONMapKeyForFile = (
    collectionID: number,
    fileName: string,
) => {
    return `${collectionID}-${fileName.slice(
        0,
        MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT,
    )}`;
};

export const getMetadataJSONMapKeyForFile = (
    collectionID: number,
    fileName: string,
) => {
    return `${collectionID}-${getFileOriginalName(fileName)}`;
};

export async function parseMetadataJSON(receivedFile: File | ElectronFile) {
    try {
        if (!(receivedFile instanceof File)) {
            receivedFile = new File(
                [await receivedFile.blob()],
                receivedFile.name,
            );
        }
        const metadataJSON: object = JSON.parse(await receivedFile.text());

        const parsedMetadataJSON: ParsedMetadataJSON =
            NULL_PARSED_METADATA_JSON;
        if (!metadataJSON) {
            return;
        }

        if (
            metadataJSON["photoTakenTime"] &&
            metadataJSON["photoTakenTime"]["timestamp"]
        ) {
            parsedMetadataJSON.creationTime =
                metadataJSON["photoTakenTime"]["timestamp"] * 1000000;
        } else if (
            metadataJSON["creationTime"] &&
            metadataJSON["creationTime"]["timestamp"]
        ) {
            parsedMetadataJSON.creationTime =
                metadataJSON["creationTime"]["timestamp"] * 1000000;
        }
        if (
            metadataJSON["modificationTime"] &&
            metadataJSON["modificationTime"]["timestamp"]
        ) {
            parsedMetadataJSON.modificationTime =
                metadataJSON["modificationTime"]["timestamp"] * 1000000;
        }
        let locationData: Location = NULL_LOCATION;
        if (
            metadataJSON["geoData"] &&
            (metadataJSON["geoData"]["latitude"] !== 0.0 ||
                metadataJSON["geoData"]["longitude"] !== 0.0)
        ) {
            locationData = metadataJSON["geoData"];
        } else if (
            metadataJSON["geoDataExif"] &&
            (metadataJSON["geoDataExif"]["latitude"] !== 0.0 ||
                metadataJSON["geoDataExif"]["longitude"] !== 0.0)
        ) {
            locationData = metadataJSON["geoDataExif"];
        }
        if (locationData !== null) {
            parsedMetadataJSON.latitude = locationData.latitude;
            parsedMetadataJSON.longitude = locationData.longitude;
        }
        return parsedMetadataJSON;
    } catch (e) {
        log.error("parseMetadataJSON failed", e);
        // ignore
    }
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

const EDITED_FILE_SUFFIX = "-edited";

/*
    Get the original file name for edited file to associate it to original file's metadataJSON file
    as edited file doesn't have their own metadata file
*/
function getFileOriginalName(fileName: string) {
    let originalName: string = null;
    const [nameWithoutExtension, extension] =
        splitFilenameAndExtension(fileName);

    const isEditedFile = nameWithoutExtension.endsWith(EDITED_FILE_SUFFIX);
    if (isEditedFile) {
        originalName = nameWithoutExtension.slice(
            0,
            -1 * EDITED_FILE_SUFFIX.length,
        );
    } else {
        originalName = nameWithoutExtension;
    }
    if (extension) {
        originalName += "." + extension;
    }
    return originalName;
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

export async function extractLivePhotoMetadata(
    worker: Remote<DedicatedCryptoWorker>,
    parsedMetadataJSONMap: ParsedMetadataJSONMap,
    collectionID: number,
    fileTypeInfo: FileTypeInfo,
    livePhotoAssets: LivePhotoAssets,
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
    const videoHash = await getFileHash(worker, livePhotoAssets.video);
    return {
        metadata: {
            ...imageMetadata,
            title: getLivePhotoName(livePhotoAssets),
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

export function getLivePhotoName(livePhotoAssets: LivePhotoAssets) {
    return livePhotoAssets.image.name;
}

export async function readLivePhoto(
    fileTypeInfo: FileTypeInfo,
    livePhotoAssets: LivePhotoAssets,
) {
    const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
        livePhotoAssets.image,
        {
            exactType: fileTypeInfo.imageType,
            fileType: FILE_TYPE.IMAGE,
        },
    );

    const imageData = await getUint8ArrayView(livePhotoAssets.image);

    const videoData = await getUint8ArrayView(livePhotoAssets.video);

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

export async function clusterLivePhotoFiles(mediaFiles: FileWithCollection[]) {
    try {
        const analysedMediaFiles: FileWithCollection[] = [];
        mediaFiles
            .sort((firstMediaFile, secondMediaFile) =>
                splitFilenameAndExtension(
                    firstMediaFile.file.name,
                )[0].localeCompare(
                    splitFilenameAndExtension(secondMediaFile.file.name)[0],
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
                    firstMediaFile.file.name,
                );
            const secondFileType =
                getFileTypeFromExtensionForLivePhotoClustering(
                    secondMediaFile.file.name,
                );
            const firstFileIdentifier: LivePhotoIdentifier = {
                collectionID: firstMediaFile.collectionID,
                fileType: firstFileType,
                name: firstMediaFile.file.name,
                size: firstMediaFile.file.size,
            };
            const secondFileIdentifier: LivePhotoIdentifier = {
                collectionID: secondMediaFile.collectionID,
                fileType: secondFileType,
                name: secondMediaFile.file.name,
                size: secondMediaFile.file.size,
            };
            if (
                areFilesLivePhotoAssets(
                    firstFileIdentifier,
                    secondFileIdentifier,
                )
            ) {
                let imageFile: File | ElectronFile;
                let videoFile: File | ElectronFile;
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
