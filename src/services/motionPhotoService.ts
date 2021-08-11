import downloadManager from "./downloadManager"
import { File } from './fileService';
import JSZip from 'jszip';

class MotionPhoto {
    imageBlob: Promise<Uint8Array>
    videoBlob: Promise<Uint8Array>
}

export const downloadAndDecodeMotionPhoto = async (file: File) => {
    const fileStream = await downloadManager.downloadFile(file);
    let zipBlob = await new Response(fileStream).blob();
    return JSZip.loadAsync(zipBlob, { createFolders: true })
        .then(function (zip) {
            let instnace = new MotionPhoto();
            Object.keys(zip.files).forEach(function (filename) {
                if (filename.startsWith("image")) {
                    instnace.imageBlob = zip.files[filename].async('uint8array');
                } else if (filename.startsWith("video")) {
                    instnace.videoBlob = zip.files[filename].async('uint8array');
                }
            })
            return instnace;
        });
}