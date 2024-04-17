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

/**
 * Convert a binary serialized representation of a live photo to an in-memory
 * {@link LivePhoto}.
 *
 * A live photo is a zip file containing two files - an image and a video. This
 * functions reads that zip file (blob), and return separate bytes (and
 * filenames) for the image and video parts.
 *
 * @param fileName The name of the overall live photo. Both the image and video
 * parts of the decompressed live photo use this as their name, combined with
 * their original extensions.
 *
 * @param zipBlob A blob contained the zipped data (i.e. the binary serialized
 * live photo).
 */
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

/**
 * Return a binary serialized representation of a live photo.
 *
 * This function takes the (in-memory) image and video data from the
 * {@link livePhoto} object, writes them to a zip file (using the respective
 * filenames), and returns the {@link Uint8Array} that represent the bytes of
 * this zip file.
 *
 * @param livePhoto The in-mem photo to serialized.
 */
export const encodeLivePhoto = async (livePhoto: LivePhoto) => {
    const [, imageExt] = nameAndExtension(livePhoto.imageNameTitle);
    const [, videoExt] = nameAndExtension(livePhoto.videoNameTitle);

    const zip = new JSZip();
    zip.file(["image", imageExt].filter((x) => !!x).join("."), livePhoto.image);
    zip.file(["video", videoExt].filter((x) => !!x).join("."), livePhoto.video);
    return await zip.generateAsync({ type: "uint8array" });
};
