import { FILE_TYPE } from 'constants/file';
import { LIVE_PHOTO_ASSET_SIZE_LIMIT } from 'constants/upload';
import { encodeLivePhoto } from 'services/livePhotoService';
import { getFileType } from 'services/typeDetectionService';
import {
    ElectronFile,
    FileTypeInfo,
    FileWithCollection,
    LivePhotoAssets,
    ParsedMetadataJSONMap,
    ExtractMetadataResult,
} from 'types/upload';
import { CustomError } from '@ente/shared/error';
import { getFileTypeFromExtensionForLivePhotoClustering } from 'utils/file/livePhoto';
import {
    splitFilenameAndExtension,
    isImageOrVideo,
    getFileExtensionWithDot,
    getFileNameWithoutExtension,
} from 'utils/file';
import { logError } from '@ente/shared/sentry';
import { getUint8ArrayView } from '../readerService';
import { extractFileMetadata } from './fileService';
import { getFileHash } from './hashService';
import { generateThumbnail } from './thumbnailService';
import uploadCancelService from './uploadCancelService';
import { Remote } from 'comlink';
import { DedicatedCryptoWorker } from '@ente/shared/crypto/internal/crypto.worker';

interface LivePhotoIdentifier {
    collectionID: number;
    fileType: FILE_TYPE;
    name: string;
    size: number;
}

const UNDERSCORE_THREE = '_3';
// Note: The icloud-photos-downloader library appends _HVEC to the end of the filename in case of live photos
// https://github.com/icloud-photos-downloader/icloud_photos_downloader
const UNDERSCORE_HEVC = '_HVEC';

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
    worker: Remote<DedicatedCryptoWorker>,
    parsedMetadataJSONMap: ParsedMetadataJSONMap,
    collectionID: number,
    fileTypeInfo: FileTypeInfo,
    livePhotoAssets: LivePhotoAssets
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
        livePhotoAssets.image
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
        filedata: await encodeLivePhoto({
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
            const firstFileType =
                getFileTypeFromExtensionForLivePhotoClustering(
                    firstMediaFile.file.name
                );
            const secondFileType =
                getFileTypeFromExtensionForLivePhotoClustering(
                    secondMediaFile.file.name
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
                    secondFileIdentifier
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
            logError(e, 'failed to cluster live photo');
            throw e;
        }
    }
}

function areFilesLivePhotoAssets(
    firstFileIdentifier: LivePhotoIdentifier,
    secondFileIdentifier: LivePhotoIdentifier
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
            getFileExtensionWithDot(secondFileIdentifier.name)
        );
        secondFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(secondFileIdentifier.name)
        );
    } else {
        firstFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(firstFileIdentifier.name)
        );
        secondFileNameWithoutSuffix = removePotentialLivePhotoSuffix(
            getFileNameWithoutExtension(secondFileIdentifier.name),
            getFileExtensionWithDot(firstFileIdentifier.name)
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

function removePotentialLivePhotoSuffix(
    filenameWithoutExtension: string,
    suffix?: string
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
