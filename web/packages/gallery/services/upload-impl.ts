import log from "ente-base/log";
import type { Electron } from "ente-base/types/ipc";
import type { UploadItem } from "./upload";

export interface LivePhotoAssets {
    image: UploadItem;
    video: UploadItem;
}

/**
 * An upload item with both parts of a live photo clubbed together.
 *
 * See: [Note: Intermediate file types during upload].
 */
export interface ClusteredUploadItem {
    localID: number;
    collectionID: number;
    fileName: string;
    isLivePhoto: boolean;
    uploadItem?: UploadItem;
    // TODO: Tie this to the isLivePhoto flag using a discriminated union.
    livePhotoAssets?: LivePhotoAssets;
}

export const markUploaded = async (
    electron: Electron,
    item: ClusteredUploadItem,
) => {
    if (item.isLivePhoto) {
        const [p0, p1] = [
            item.livePhotoAssets!.image,
            item.livePhotoAssets!.video,
        ];
        if (Array.isArray(p0) && Array.isArray(p1)) {
            return electron.markUploadedZipItem(p0, p1);
        } else if (typeof p0 == "string" && typeof p1 == "string") {
            return electron.markUploadedFile(p0, p1);
        } else if (
            p0 &&
            typeof p0 == "object" &&
            "path" in p0 &&
            p1 &&
            typeof p1 == "object" &&
            "path" in p1
        ) {
            return electron.markUploadedFile(p0.path, p1.path);
        } else {
            throw new Error(
                "Attempting to mark upload completion of unexpected desktop upload items",
            );
        }
    } else {
        const p = item.uploadItem!;
        if (Array.isArray(p)) {
            return electron.markUploadedZipItem(p);
        } else if (typeof p == "string") {
            return electron.markUploadedFile(p);
        } else if (typeof p == "object" && "path" in p) {
            return electron.markUploadedFile(p.path);
        } else {
            // We can come here when the user saves an image they've edited, in
            // which case `item` will be a web File object which won't have a
            // path. Such a la carte uploads don't mark the file as pending
            // anyways, so there isn't anything to do also.
            //
            // Keeping a log here, though really the upper layers of the code
            // need to be reworked so that we don't even get here in such cases.
            log.info(
                "Ignoring attempt to mark upload completion of (likely edited) item",
            );
            return 0;
        }
    }
};
