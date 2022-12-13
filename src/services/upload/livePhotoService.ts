import { FILE_TYPE, TYPE_HEIC, TYPE_MOV } from 'constants/file';
import { LIVE_PHOTO_ASSET_SIZE_LIMIT } from 'constants/upload';
import { encodeMotionPhoto } from 'services/motionPhotoService';
import { getFileType } from 'services/typeDetectionService';
import {
    ElectronFile,
    FileTypeInfo,
    FileWithCollection,
    LivePhotoAssets,
    ParsedMetadataJSONMap,
} from 'types/upload';
import { CustomError } from 'utils/error';
import {
    getFileExtension,
    isHeicOrMov,
    splitFilenameAndExtension,
} from 'utils/file';
import { logError } from 'utils/sentry';
import { getUint8ArrayView } from '../readerService';
import { extractFileMetadata } from './fileService';
import { getFileHash } from './hashService';
import { generateThumbnail } from './thumbnailService';
import uploadCancelService from './uploadCancelService';

interface LivePhotoIdentifier {
    collectionID: number;
    fileType: string;
    name: string;
    size: number;
}

const ENTE_LIVE_PHOTO_FORMAT = 'elp';

const UNDERSCORE_THREE = '_3';

const UNDERSCORE = '_';

export async function getLivePhotoFileType(
    livePhotoAssets: LivePhotoAssets
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
    worker,
    parsedMetadataJSONMap: ParsedMetadataJSONMap,
    collectionID: number,
    fileTypeInfo: FileTypeInfo,
    livePhotoAssets: LivePhotoAssets
) {
    const imageFileTypeInfo: FileTypeInfo = {
        fileType: FILE_TYPE.IMAGE,
        exactType: fileTypeInfo.imageType,
    };
    const imageMetadata = await extractFileMetadata(
        worker,
        parsedMetadataJSONMap,
        collectionID,
        imageFileTypeInfo,
        livePhotoAssets.image
    );
    const videoHash = await getFileHash(worker, livePhotoAssets.video);
    return {
        ...imageMetadata,
        title: getLivePhotoName(livePhotoAssets),
        fileType: FILE_TYPE.LIVE_PHOTO,
        imageHash: imageMetadata.hash,
        videoHash: videoHash,
        hash: undefined,
    };
}

export function getLivePhotoSize(livePhotoAssets: LivePhotoAssets) {
    return livePhotoAssets.image.size + livePhotoAssets.video.size;
}

export function getLivePhotoName(livePhotoAssets: LivePhotoAssets) {
    return `${
        splitFilenameAndExtension(livePhotoAssets.image.name)[0]
    }.${ENTE_LIVE_PHOTO_FORMAT}`;
}

export async function readLivePhoto(
    fileTypeInfo: FileTypeInfo,
    livePhotoAssets: LivePhotoAssets
) {
    const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
        livePhotoAssets.image,
        {
            exactType: fileTypeInfo.imageType,
            fileType: FILE_TYPE.IMAGE,
        }
    );

    const image = await getUint8ArrayView(livePhotoAssets.image);

    const video = await getUint8ArrayView(livePhotoAssets.video);

    return {
        filedata: await encodeMotionPhoto({
            image,
            video,
            imageNameTitle: livePhotoAssets.image.name,
            videoNameTitle: livePhotoAssets.video.name,
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
                    firstMediaFile.file.name
                )[0].localeCompare(
                    splitFilenameAndExtension(secondMediaFile.file.name)[0]
                )
            )
            .sort(
                (firstMediaFile, secondMediaFile) =>
                    firstMediaFile.collectionID - secondMediaFile.collectionID
            );
        let index = 0;
        while (index < mediaFiles.length - 1) {
            if (uploadCancelService.isUploadCancelationRequested()) {
                throw Error(CustomError.UPLOAD_CANCELLED);
            }
            const firstMediaFile = mediaFiles[index];
            const secondMediaFile = mediaFiles[index + 1];
            const firstFileType = getFileExtension(firstMediaFile.file.name);
            const secondFileType = getFileExtension(secondMediaFile.file.name);
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
                    secondFileIdentifier
                )
            ) {
                let imageFile: File | ElectronFile;
                let videoFile: File | ElectronFile;
                if (
                    firstFileType === TYPE_HEIC &&
                    secondFileType === TYPE_MOV
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
            logError(e, 'failed to cluster live photo');
            throw e;
        }
    }
}

function areFilesLivePhotoAssets(
    firstFileIdentifier: LivePhotoIdentifier,
    secondFileIdentifier: LivePhotoIdentifier
) {
    if (
        firstFileIdentifier.collectionID ===
            secondFileIdentifier.collectionID &&
        firstFileIdentifier.fileType !== secondFileIdentifier.fileType &&
        isHeicOrMov(firstFileIdentifier.fileType) &&
        isHeicOrMov(secondFileIdentifier.fileType) &&
        removeUnderscoreThreeSuffix(
            splitFilenameAndExtension(firstFileIdentifier.name)[0]
        ) ===
            removeUnderscoreThreeSuffix(
                splitFilenameAndExtension(secondFileIdentifier.name)[0]
            )
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
            logError(
                new Error(CustomError.TOO_LARGE_LIVE_PHOTO_ASSETS),
                CustomError.TOO_LARGE_LIVE_PHOTO_ASSETS,
                {
                    fileSizes: [
                        firstFileIdentifier.size,
                        secondFileIdentifier.size,
                    ],
                }
            );
        }
    }
    return false;
}

function removeUnderscoreThreeSuffix(filename: string) {
    if (filename.endsWith(UNDERSCORE_THREE)) {
        return filename.slice(0, filename.lastIndexOf(UNDERSCORE));
    } else {
        return filename;
    }
}
