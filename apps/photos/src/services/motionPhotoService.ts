import JSZip from 'jszip';
import { EnteFile } from 'types/file';
import { fileExtensionWithDot, fileNameWithoutExtension } from 'utils/file';

class MotionPhoto {
    image: Uint8Array;
    video: Uint8Array;
    imageNameTitle: string;
    videoNameTitle: string;
}

export const decodeMotionPhoto = async (file: EnteFile, zipBlob: Blob) => {
    const originalName = fileNameWithoutExtension(file.metadata.title);
    const zip = await JSZip.loadAsync(zipBlob, { createFolders: true });

    const motionPhoto = new MotionPhoto();
    for (const zipFilename in zip.files) {
        if (zipFilename.startsWith('image')) {
            motionPhoto.imageNameTitle =
                originalName + fileExtensionWithDot(zipFilename);
            motionPhoto.image = await zip.files[zipFilename].async(
                'uint8array'
            );
        } else if (zipFilename.startsWith('video')) {
            motionPhoto.videoNameTitle =
                originalName + fileExtensionWithDot(zipFilename);
            motionPhoto.video = await zip.files[zipFilename].async(
                'uint8array'
            );
        }
    }
    return motionPhoto;
};

export const encodeMotionPhoto = async (motionPhoto: MotionPhoto) => {
    const zip = new JSZip();
    zip.file(
        'image' + fileExtensionWithDot(motionPhoto.imageNameTitle),
        motionPhoto.image
    );
    zip.file(
        'video' + fileExtensionWithDot(motionPhoto.videoNameTitle),
        motionPhoto.video
    );
    return await zip.generateAsync({ type: 'uint8array' });
};
