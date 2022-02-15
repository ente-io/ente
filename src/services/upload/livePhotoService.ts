import { FILE_TYPE } from 'constants/file';
import { LIVE_PHOTO_ASSET_SIZE_LIMIT } from 'constants/upload';
import { encodeMotionPhoto } from 'services/motionPhotoService';
import {
    FileTypeInfo,
    FileWithCollection,
    LivePhotoAssets,
    Metadata,
} from 'types/upload';
import { CustomError } from 'utils/error';
import { splitFilenameAndExtension } from 'utils/file';
import { logError } from 'utils/sentry';
import { getUint8ArrayView } from './readFileService';
import { generateThumbnail } from './thumbnailService';
import uploadService from './uploadService';
import UploadService from './uploadService';

interface LivePhotoIdentifier {
    collectionID: number;
    fileType: FILE_TYPE;
    name: string;
    size: number;
}

export function getLivePhotoFileType(
    file1TypeInfo: FileTypeInfo,
    file2TypeInfo: FileTypeInfo
) {
    return {
        fileType: FILE_TYPE.LIVE_PHOTO,
        exactType: `${file1TypeInfo.exactType}+${file2TypeInfo.exactType}`,
    };
}

export function getLivePhotoMetadata(
    file1Metadata: Metadata,
    file2Metadata: Metadata
) {
    return {
        ...file1Metadata,
        ...file2Metadata,
        title: `${splitFilenameAndExtension(file1Metadata.title)[0]}.zip`,
        fileType: FILE_TYPE.LIVE_PHOTO,
    };
}

export function getLivePhotoSize(livePhotoAssets: LivePhotoAssets) {
    return livePhotoAssets.image.size + livePhotoAssets.video.size;
}

export async function readLivePhoto(
    worker,
    reader: FileReader,
    fileTypeInfo: FileTypeInfo,
    livePhotoAssets: LivePhotoAssets
) {
    const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
        worker,
        reader,
        livePhotoAssets.image,
        { exactType: fileTypeInfo.exactType, fileType: FILE_TYPE.IMAGE }
    );

    const image = await getUint8ArrayView(reader, livePhotoAssets.image);

    const video = await getUint8ArrayView(reader, livePhotoAssets.video);

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
        const { fileTypeInfo: firstFileTypeInfo, metadata: firstFileMetadata } =
            UploadService.getFileMetadataAndFileTypeInfo(
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
        if (
            areFilesLivePhotoAssets(firstFileIdentifier, secondFileIdentifier)
        ) {
            let imageFile;
            let videoFile;
            if (
                firstFileTypeInfo.fileType === FILE_TYPE.IMAGE &&
                secondFileFileInfo.fileType === FILE_TYPE.VIDEO
            ) {
                imageFile = firstMediaFile.file;
                videoFile = secondMediaFile.file;
            } else {
                imageFile = secondMediaFile.file;
                videoFile = firstMediaFile.file;
            }
            const livePhotoLocalID = index;
            analysedMediaFiles.push({
                localID: livePhotoLocalID,
                collectionID: firstMediaFile.collectionID,
                isLivePhoto: true,
                livePhotoAssets: { image: imageFile, video: videoFile },
            });
            const livePhotoFileTypeInfo: FileTypeInfo = getLivePhotoFileType(
                firstFileTypeInfo,
                secondFileFileInfo
            );
            const livePhotoMetadata: Metadata = getLivePhotoMetadata(
                firstFileMetadata,
                secondFileMetadata
            );
            uploadService.setFileMetadataAndFileTypeInfo(livePhotoLocalID, {
                fileTypeInfo: { ...livePhotoFileTypeInfo },
                metadata: { ...livePhotoMetadata },
            });
            index += 2;
        } else {
            analysedMediaFiles.push({ ...firstMediaFile, isLivePhoto: false });
            index += 1;
        }
    }
    if (index === mediaFiles.length - 1) {
        analysedMediaFiles.push({ ...mediaFiles[index], isLivePhoto: false });
    }
    return analysedMediaFiles;
}

function areFilesLivePhotoAssets(
    firstFileIdentifier: LivePhotoIdentifier,
    secondFileIdentifier: LivePhotoIdentifier
) {
    if (
        firstFileIdentifier.collectionID ===
            secondFileIdentifier.collectionID &&
        firstFileIdentifier.fileType !== secondFileIdentifier.fileType &&
        firstFileIdentifier.fileType !== FILE_TYPE.OTHERS &&
        secondFileIdentifier.fileType !== FILE_TYPE.OTHERS &&
        splitFilenameAndExtension(firstFileIdentifier.name)[0] ===
            splitFilenameAndExtension(secondFileIdentifier.name)[0]
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
