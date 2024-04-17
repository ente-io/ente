import JSZip from "jszip";

class LivePhoto {
    image: Uint8Array;
    video: Uint8Array;
    imageNameTitle: string;
    videoNameTitle: string;
}

export function getFileNameWithoutExtension(filename: string) {
    const lastDotPosition = filename.lastIndexOf(".");
    if (lastDotPosition === -1) return filename;
    else return filename.slice(0, lastDotPosition);
}

export function getFileExtensionWithDot(filename: string) {
    const lastDotPosition = filename.lastIndexOf(".");
    if (lastDotPosition === -1) return "";
    else return filename.slice(lastDotPosition);
}

export const decodeLivePhoto = async (fileName: string, zipBlob: Blob) => {
    const originalName = getFileNameWithoutExtension(fileName);
    const zip = await JSZip.loadAsync(zipBlob, { createFolders: true });

    const livePhoto = new LivePhoto();
    for (const zipFilename in zip.files) {
        if (zipFilename.startsWith("image")) {
            livePhoto.imageNameTitle =
                originalName + getFileExtensionWithDot(zipFilename);
            livePhoto.image = await zip.files[zipFilename].async("uint8array");
        } else if (zipFilename.startsWith("video")) {
            livePhoto.videoNameTitle =
                originalName + getFileExtensionWithDot(zipFilename);
            livePhoto.video = await zip.files[zipFilename].async("uint8array");
        }
    }
    return livePhoto;
};

export const encodeLivePhoto = async (livePhoto: LivePhoto) => {
    const zip = new JSZip();
    zip.file(
        "image" + getFileExtensionWithDot(livePhoto.imageNameTitle),
        livePhoto.image,
    );
    zip.file(
        "video" + getFileExtensionWithDot(livePhoto.videoNameTitle),
        livePhoto.video,
    );
    return await zip.generateAsync({ type: "uint8array" });
};
