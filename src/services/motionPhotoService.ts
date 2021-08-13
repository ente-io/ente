import JSZip from 'jszip';
import { fileExtensionWithDot } from 'utils/file';

class MotionPhoto {
    image: Uint8Array;
    video: Uint8Array;
    imageNameTitle: String;
    videoNameTitle: String;
}

export const decodeMotionPhoto = async (
    zipBlob: Blob,
    originalName: string
) => {
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
