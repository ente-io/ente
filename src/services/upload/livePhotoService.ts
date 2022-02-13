import { FILE_TYPE } from 'constants/file';
import { encodeMotionPhoto } from 'services/motionPhotoService';
import { Collection } from 'types/collection';
import { FileTypeInfo, isDataStream, LivePhotoAssets } from 'types/upload';
import { splitFilenameAndExtension } from 'utils/file';
import { getFileMetadata, readFile } from './fileService';
import { getFileType } from './readFileService';

export async function getLivePhotoFileType(
    worker,
    livePhotoAssets: LivePhotoAssets
) {
    const file1TypeInfo = await getFileType(worker, livePhotoAssets[0]);
    const file2TypeInfo = await getFileType(worker, livePhotoAssets[1]);
    return {
        fileType: FILE_TYPE.LIVE_PHOTO,
        exactType: `${file1TypeInfo.exactType}+${file2TypeInfo.exactType}`,
    };
}

export function getLivePhotoSize(livePhotoAssets: LivePhotoAssets) {
    return livePhotoAssets[0].size + livePhotoAssets[1].size;
}

export async function getLivePhotoMetadata(
    livePhotoAssets: LivePhotoAssets,
    collection: Collection,
    fileTypeInfo: FileTypeInfo
) {
    const imageMetadata = await getFileMetadata(
        livePhotoAssets.image,
        collection,
        fileTypeInfo
    );
    const videoMetadata = await getFileMetadata(
        livePhotoAssets.video,
        collection,
        fileTypeInfo
    );
    return {
        ...videoMetadata,
        ...imageMetadata,
        title: splitFilenameAndExtension(livePhotoAssets[0].name)[0],
    };
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
        fileTypeInfo,
        livePhotoAssets.image
    );
    const video = await readFile(
        worker,
        reader,
        fileTypeInfo,
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
