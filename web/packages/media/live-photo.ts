import { nameAndExtension } from "@/next/file";
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
    const [name] = nameAndExtension(fileName);
    const zip = await JSZip.loadAsync(zipBlob, { createFolders: true });

    const livePhoto = new LivePhoto();
    for (const zipFileName in zip.files) {
        if (zipFileName.startsWith("image")) {
            livePhoto.imageNameTitle =
                name + getFileExtensionWithDot(zipFileName);
            livePhoto.image = await zip.files[zipFileName].async("uint8array");
        } else if (zipFileName.startsWith("video")) {
            livePhoto.videoNameTitle =
                name + getFileExtensionWithDot(zipFileName);
            livePhoto.video = await zip.files[zipFileName].async("uint8array");
        }
    }
    return livePhoto;
};

export const encodeLivePhoto = async (livePhoto: LivePhoto) => {
    const [, imageExt] = nameAndExtension(livePhoto.imageNameTitle);
    const [, videoExt] = nameAndExtension(livePhoto.videoNameTitle);

    const zip = new JSZip();
    zip.file(["image", imageExt].filter((x) => !!x).join("."), livePhoto.image);
    zip.file(["video", videoExt].filter((x) => !!x).join("."), livePhoto.video);
    return await zip.generateAsync({ type: "uint8array" });
};
