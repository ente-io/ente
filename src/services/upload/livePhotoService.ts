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
import uploadService from './uploadService';
import UploadService from './uploadService';

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
    const image = await readFile(
        worker,
        reader,
        { exactType: fileTypeInfo.exactType, fileType: FILE_TYPE.IMAGE },
        livePhotoAssets.image
    );
    const video = await readFile(
        worker,
        reader,
        { exactType: fileTypeInfo.exactType, fileType: FILE_TYPE.VIDEO },
        livePhotoAssets.video
    );

    if (isDataStream(video.filedata) || isDataStream(image.filedata)) {
        throw new Error('too large live photo assets');
    }
    return {
        filedata: await encodeMotionPhoto({
            image: image.filedata as Uint8Array,
            video: video.filedata as Uint8Array,
            imageNameTitle: livePhotoAssets.image.name,
            videoNameTitle: livePhotoAssets.video.name,
        }),
        thumbnail: video.hasStaticThumbnail ? video.thumbnail : image.thumbnail,
        hasStaticThumbnail: !(
            !video.hasStaticThumbnail || !image.hasStaticThumbnail
        ),
    };
}

export function clusterLivePhotoFiles(mediaFiles: FileWithCollection[]) {
    const analysedMediaFiles: FileWithCollection[] = [];
    mediaFiles.sort((media1Files, media2Files) =>
        splitFilenameAndExtension(media1Files.file.name)[0].localeCompare(
            splitFilenameAndExtension(media2Files.file.name)[0]
        )
    );
    for (let i = 0; i < mediaFiles.length - 1; i += 2) {
        const mediaFile1 = mediaFiles[i];
        const mediaFile2 = mediaFiles[i + 1];
        const { fileTypeInfo: file1TypeInfo, metadata: file1Metadata } =
            UploadService.getFileMetadataAndFileTypeInfo(mediaFile1.localID);
        const { fileTypeInfo: file2TypeInfo, metadata: file2Metadata } =
            UploadService.getFileMetadataAndFileTypeInfo(mediaFile2.localID);
        if (areFilesLivePhotoAssets(mediaFile1, mediaFile2)) {
            let imageFile;
            let videoFile;
            if (
                file1TypeInfo.fileType === FILE_TYPE.IMAGE &&
                file2TypeInfo.fileType === FILE_TYPE.VIDEO
            ) {
                imageFile = mediaFile1.file;
                videoFile = mediaFile2.file;
            } else {
                imageFile = mediaFile2.file;
                videoFile = mediaFile1.file;
            }
            const livePhotoLocalID = i;
            analysedMediaFiles.push({
                localID: livePhotoLocalID,
                collectionID: mediaFile1.collectionID,
                isLivePhoto: true,
                livePhotoAssets: { image: imageFile, video: videoFile },
            });
            const livePhotoFileTypeInfo: FileTypeInfo = getLivePhotoFileType(
                file1TypeInfo,
                file2TypeInfo
            );
            const livePhotoMetadata: Metadata = getLivePhotoMetadata(
                file1Metadata,
                file2Metadata
            );
            uploadService.setFileMetadataAndFileTypeInfo(livePhotoLocalID, {
                fileTypeInfo: { ...livePhotoFileTypeInfo },
                metadata: { ...livePhotoMetadata },
            });
        } else {
            analysedMediaFiles.push({ ...mediaFile1, isLivePhoto: false });
            analysedMediaFiles.push({
                ...mediaFile2,
                isLivePhoto: false,
            });
        }
    }
    return analysedMediaFiles;
}

function areFilesLivePhotoAssets(
    mediaFile1: FileWithCollection,
    mediaFile2: FileWithCollection
) {
    const {
        collectionID: file1collectionID,
        file: file1,
        localID: localID1,
    } = mediaFile1;
    const {
        collectionID: file2collectionID,
        file: file2,
        localID: localID2,
    } = mediaFile2;
    const {
        fileTypeInfo: { fileType: file1Type },
    } = UploadService.getFileMetadataAndFileTypeInfo(localID1);
    const {
        fileTypeInfo: { fileType: file2Type },
    } = UploadService.getFileMetadataAndFileTypeInfo(localID2);
    return (
        file1collectionID === file2collectionID &&
        file1Type !== file2Type &&
        file1Type !== FILE_TYPE.OTHERS &&
        file2Type !== FILE_TYPE.OTHERS &&
        splitFilenameAndExtension(file1.name)[0] ===
            splitFilenameAndExtension(file2.name)[0]
    );
}
