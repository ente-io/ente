import downloadManager from "./downloadManager"
import { File } from './fileService';
import JSZip from 'jszip';
import { fileExtensionWithDot, fileNameWithoutExtension } from "utils/file";

class MotionPhoto {
    imageBlob: Promise<Uint8Array>
    videoBlob: Promise<Uint8Array>
    imageNameTitle: String
    videoNameTitle: String
}

export const downloadAndDecodeMotionPhoto = async (file: File) => {
    const fileStream = await downloadManager.downloadFile(file);
    let zipBlob = await new Response(fileStream).blob();
    return JSZip.loadAsync(zipBlob, { createFolders: true })
        .then(function (zip) {
            let instance = new MotionPhoto();
            let orignalName = fileNameWithoutExtension(file.metadata.title)
            Object.keys(zip.files).forEach(function (zipFilename) {
                if (zipFilename.startsWith("image")) {
                    instance.imageNameTitle = orignalName + fileExtensionWithDot(zipFilename);
                    instance.imageBlob = zip.files[zipFilename].async('uint8array');
                } else if (zipFilename.startsWith("video")) {
                    instance.videoNameTitle = orignalName + fileExtensionWithDot(zipFilename);
                    instance.videoBlob = zip.files[zipFilename].async('uint8array');
                }
            })
            return instance;
        });
}
