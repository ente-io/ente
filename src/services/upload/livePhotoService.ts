import { FILE_TYPE } from 'constants/file';
import { encodeMotionPhoto } from 'services/motionPhotoService';
import {
    FileTypeInfo,
    FileWithCollection,
    isDataStream,
    LivePhotoAssets,
    Metadata,
} from 'types/upload';
import { splitFilenameAndExtension } from 'utils/file';
import { readFile } from './fileService';
import { getFileData } from './readFileService';
import uploadService from './uploadService';
import UploadService from './uploadService';

interface LivePhotoIdentifier {
    collectionID: number;
    fileType: FILE_TYPE;
    name: string;
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
    const image = await getFileData(reader, livePhotoAssets.image);

    const video = await readFile(
        worker,
        reader,
        { exactType: fileTypeInfo.exactType, fileType: FILE_TYPE.VIDEO },
        livePhotoAssets.video
    );

    if (isDataStream(video.filedata) || isDataStream(image)) {
        throw new Error('too large live photo assets');
    }
    return {
        filedata: await encodeMotionPhoto({
            image: image as Uint8Array,
            video: video.filedata as Uint8Array,
            imageNameTitle: livePhotoAssets.image.name,
            videoNameTitle: livePhotoAssets.video.name,
        }),
        thumbnail: video.thumbnail,
        hasStaticThumbnail: video.hasStaticThumbnail,
    };
}

export function clusterLivePhotoFiles(mediaFiles: FileWithCollection[]) {
    const analysedMediaFiles: FileWithCollection[] = [];
    mediaFiles.sort((media1Files, media2Files) =>
        splitFilenameAndExtension(media1Files.file.name)[0].localeCompare(
            splitFilenameAndExtension(media2Files.file.name)[0]
        )
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
            name: firstFileMetadata.title,
        };
        const secondFileIdentifier: LivePhotoIdentifier = {
            collectionID: secondMediaFile.collectionID,
            fileType: secondFileFileInfo.fileType,
            name: secondFileMetadata.title,
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
    return (
        firstFileIdentifier.collectionID ===
            secondFileIdentifier.collectionID &&
        firstFileIdentifier.fileType !== secondFileIdentifier.fileType &&
        firstFileIdentifier.fileType !== FILE_TYPE.OTHERS &&
        secondFileIdentifier.fileType !== FILE_TYPE.OTHERS &&
        splitFilenameAndExtension(firstFileIdentifier.name)[0] ===
            splitFilenameAndExtension(secondFileIdentifier.name)[0]
    );
}
