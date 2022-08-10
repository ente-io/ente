import { FILE_TYPE } from 'constants/file';
import { LIVE_PHOTO_ASSET_SIZE_LIMIT } from 'constants/upload';
import { encodeMotionPhoto } from 'services/motionPhotoService';
import {
    ElectronFile,
    FileTypeInfo,
    FileWithCollection,
    LivePhotoAssets,
    Metadata,
} from 'types/upload';
import { CustomError } from 'utils/error';
import { isImageOrVideo, splitFilenameAndExtension } from 'utils/file';
import { logError } from 'utils/sentry';
import { getUint8ArrayView } from '../readerService';
import { generateThumbnail } from './thumbnailService';
import uploadService from './uploadService';
import UploadService from './uploadService';

interface LivePhotoIdentifier {
    collectionID: number;
    fileType: FILE_TYPE;
    name: string;
    size: number;
}

interface Asset {
    file: File | ElectronFile;
    metadata: Metadata;
    fileTypeInfo: FileTypeInfo;
}

const ENTE_LIVE_PHOTO_FORMAT = 'elp';

const UNDERSCORE_THREE = '_3';

const UNDERSCORE = '_';

export function getLivePhotoFileType(
    imageFileTypeInfo: FileTypeInfo,
    videoTypeInfo: FileTypeInfo
): FileTypeInfo {
    return {
        fileType: FILE_TYPE.LIVE_PHOTO,
        exactType: `${imageFileTypeInfo.exactType}+${videoTypeInfo.exactType}`,
        imageType: imageFileTypeInfo.exactType,
        videoType: videoTypeInfo.exactType,
    };
}

export function getLivePhotoMetadata(
    imageMetadata: Metadata,
    videoMetadata: Metadata
) {
    return {
        ...imageMetadata,
        title: getLivePhotoName(imageMetadata.title),
        fileType: FILE_TYPE.LIVE_PHOTO,
        imageHash: imageMetadata.hash,
        videoHash: videoMetadata.hash,
        hash: undefined,
    };
}

export function getLivePhotoFilePath(imageAsset: Asset): string {
    return getLivePhotoName((imageAsset.file as any).path);
}

export function getLivePhotoSize(livePhotoAssets: LivePhotoAssets) {
    return livePhotoAssets.image.size + livePhotoAssets.video.size;
}

export function getLivePhotoName(imageTitle: string) {
    return `${
        splitFilenameAndExtension(imageTitle)[0]
    }.${ENTE_LIVE_PHOTO_FORMAT}`;
}

export async function readLivePhoto(
    fileTypeInfo: FileTypeInfo,
    livePhotoAssets: LivePhotoAssets
) {
    if (uploadService.isUploadPausing()) {
        throw Error(CustomError.UPLOAD_PAUSED);
    }
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

export function clusterLivePhotoFiles(mediaFiles: FileWithCollection[]) {
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
            const firstMediaFile = mediaFiles[index];
            const secondMediaFile = mediaFiles[index + 1];
            const {
                fileTypeInfo: firstFileTypeInfo,
                metadata: firstFileMetadata,
            } = UploadService.getFileMetadataAndFileTypeInfo(
                firstMediaFile.localID
            );
            const {
                fileTypeInfo: secondFileFileInfo,
                metadata: secondFileMetadata,
            } = UploadService.getFileMetadataAndFileTypeInfo(
                secondMediaFile.localID
            );
            const firstFileIdentifier: LivePhotoIdentifier = {
                collectionID: firstMediaFile.collectionID,
                fileType: firstFileTypeInfo.fileType,
                name: firstMediaFile.file.name,
                size: firstMediaFile.file.size,
            };
            const secondFileIdentifier: LivePhotoIdentifier = {
                collectionID: secondMediaFile.collectionID,
                fileType: secondFileFileInfo.fileType,
                name: secondMediaFile.file.name,
                size: secondMediaFile.file.size,
            };
            const firstAsset = {
                file: firstMediaFile.file,
                metadata: firstFileMetadata,
                fileTypeInfo: firstFileTypeInfo,
            };
            const secondAsset = {
                file: secondMediaFile.file,
                metadata: secondFileMetadata,
                fileTypeInfo: secondFileFileInfo,
            };
            if (
                areFilesLivePhotoAssets(
                    firstFileIdentifier,
                    secondFileIdentifier
                )
            ) {
                let imageAsset: Asset;
                let videoAsset: Asset;
                if (
                    firstFileTypeInfo.fileType === FILE_TYPE.IMAGE &&
                    secondFileFileInfo.fileType === FILE_TYPE.VIDEO
                ) {
                    imageAsset = firstAsset;
                    videoAsset = secondAsset;
                } else {
                    videoAsset = firstAsset;
                    imageAsset = secondAsset;
                }
                const livePhotoLocalID = firstMediaFile.localID;
                analysedMediaFiles.push({
                    localID: livePhotoLocalID,
                    collectionID: firstMediaFile.collectionID,
                    isLivePhoto: true,
                    livePhotoAssets: {
                        image: imageAsset.file,
                        video: videoAsset.file,
                    },
                });
                const livePhotoFileTypeInfo: FileTypeInfo =
                    getLivePhotoFileType(
                        imageAsset.fileTypeInfo,
                        videoAsset.fileTypeInfo
                    );
                const livePhotoMetadata: Metadata = getLivePhotoMetadata(
                    imageAsset.metadata,
                    videoAsset.metadata
                );
                const livePhotoPath = getLivePhotoFilePath(imageAsset);
                uploadService.setFileMetadataAndFileTypeInfo(livePhotoLocalID, {
                    fileTypeInfo: { ...livePhotoFileTypeInfo },
                    metadata: { ...livePhotoMetadata },
                    filePath: livePhotoPath,
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
        logError(e, 'failed to cluster live photo');
        throw e;
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
        isImageOrVideo(firstFileIdentifier.fileType) &&
        isImageOrVideo(secondFileIdentifier.fileType) &&
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
