import JSZip from 'jszip';
import { EnteFile } from 'types/file';
import { fileExtensionWithDot, fileNameWithoutExtension } from 'utils/file';

class LivePhoto {
    image: Uint8Array;
    video: Uint8Array;
    imageNameTitle: string;
    videoNameTitle: string;
}

export const decodeLivePhoto = async (file: EnteFile, zipBlob: Blob) => {
    const originalName = fileNameWithoutExtension(file.metadata.title);
    const zip = await JSZip.loadAsync(zipBlob, { createFolders: true });

    const livePhoto = new LivePhoto();
    for (const zipFilename in zip.files) {
        if (zipFilename.startsWith('image')) {
            livePhoto.imageNameTitle =
                originalName + fileExtensionWithDot(zipFilename);
            livePhoto.image = await zip.files[zipFilename].async('uint8array');
        } else if (zipFilename.startsWith('video')) {
            livePhoto.videoNameTitle =
                originalName + fileExtensionWithDot(zipFilename);
            livePhoto.video = await zip.files[zipFilename].async('uint8array');
        }
    }
    return livePhoto;
};

export const encodeLivePhoto = async (livePhoto: LivePhoto) => {
    const zip = new JSZip();
    zip.file(
        'image' + fileExtensionWithDot(livePhoto.imageNameTitle),
        livePhoto.image
    );
    zip.file(
        'video' + fileExtensionWithDot(livePhoto.videoNameTitle),
        livePhoto.video
    );
    return await zip.generateAsync({ type: 'uint8array' });
};
