import JSZip from 'jszip';
import { EnteFile } from 'types/file';
import {
    getFileExtensionWithDot,
    getFileNameWithoutExtension,
} from 'utils/file';

class LivePhoto {
    image: Uint8Array;
    video: Uint8Array;
    imageNameTitle: string;
    videoNameTitle: string;
}

export const decodeLivePhoto = async (file: EnteFile, zipBlob: Blob) => {
    const originalName = getFileNameWithoutExtension(file.metadata.title);
    const zip = await JSZip.loadAsync(zipBlob, { createFolders: true });

    const livePhoto = new LivePhoto();
    for (const zipFilename in zip.files) {
        if (zipFilename.startsWith('image')) {
            livePhoto.imageNameTitle =
                originalName + getFileExtensionWithDot(zipFilename);
            livePhoto.image = await zip.files[zipFilename].async('uint8array');
        } else if (zipFilename.startsWith('video')) {
            livePhoto.videoNameTitle =
                originalName + getFileExtensionWithDot(zipFilename);
            livePhoto.video = await zip.files[zipFilename].async('uint8array');
        }
    }
    return livePhoto;
};

export const encodeLivePhoto = async (livePhoto: LivePhoto) => {
    const zip = new JSZip();
    zip.file(
        'image' + getFileExtensionWithDot(livePhoto.imageNameTitle),
        livePhoto.image
    );
    zip.file(
        'video' + getFileExtensionWithDot(livePhoto.videoNameTitle),
        livePhoto.video
    );
    return await zip.generateAsync({ type: 'uint8array' });
};
