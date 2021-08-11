import downloadManager from "./downloadManager"
import { File } from './fileService';
import JSZip from 'jszip';
import { fileExtensionWithDot, fileNameWithoutExtension } from "utils/file";

class MotionPhoto {
    imageBlob: Promise<Uint8Array>
    videoBlob: Promise<Uint8Array>
    title: String
    // name of the file which contains image
    _zipImageName: String
    // name of the file which contains video
    _zipVideoName: String

    imageName() {
        return fileNameWithoutExtension(this.title) + fileExtensionWithDot(this._zipImageName);
    }

    videoName() {
        return fileNameWithoutExtension(this.title) + fileExtensionWithDot(this._zipVideoName);
    }

}

export const downloadAndDecodeMotionPhoto = async (file: File) => {
    const fileStream = await downloadManager.downloadFile(file);
    let zipBlob = await new Response(fileStream).blob();
    return JSZip.loadAsync(zipBlob, { createFolders: true })
        .then(function (zip) {
            let instnace = new MotionPhoto();
            instnace.title = file.metadata.title
            Object.keys(zip.files).forEach(function (filename) {
                if (filename.startsWith("image")) {
                    instnace._zipImageName = filename
                    instnace.imageBlob = zip.files[filename].async('uint8array');
                } else if (filename.startsWith("video")) {
                    instnace._zipVideoName = filename
                    instnace.videoBlob = zip.files[filename].async('uint8array');
                }
            })
            return instnace;
        });
}
