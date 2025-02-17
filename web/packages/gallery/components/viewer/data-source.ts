/* xeslint-disable */
// x-@ts-nocheck

import {
    downloadManager,
    type LivePhotoSourceURL,
} from "@/gallery/services/download";
import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";

// TODO(PS):
//import { type SlideData } from "./ps5/dist/types/slide/"
interface SlideData {
    /**
     * image URL
     */
    src?: string | undefined;
    /**
     * image width
     */
    width?: number | undefined;
    /**
     * image height
     */
    height?: number | undefined;
    /**
     * html content of a slide
     */
    html?: string | undefined;
}

type ItemData = SlideData & {
    // Our props. TODO(PS) document if end up using these.
    videoURL?: string;
    livePhotoVideoURL?: string;
    isContentLoading?: boolean;
    isContentZoomable?: boolean;
};

/**
 * A class that stores and serves data required by our custom PhotoSwipe
 * instance, effectively acting as an in-memory cache.
 *
 * By keeping this independent of the lifetime of the PhotoSwipe instance, we
 * can reuse the same cache for multiple displays of our file viewer.
 */
export class FileViewerDataSource {
    private itemDataByFileID = new Map<number, ItemData>();
    private needsRefreshByFileID = new Map<number, () => void>();

    /**
     * Return the best available ItemData for rendering the given {@link file}.
     *
     * If an entry does not exist for a particular file, then it is lazily added
     * on demand, and updated as we keep getting better data (thumbnail,
     * original) for the file.
     *
     * At each step, we call the provided callback so that file viewer can call
     * us again to get the updated data.
     *
     * ---
     *
     * Detailed flow:
     *
     * If we already have the final data about the file, then this function will
     * return it and do nothing subsequently.
     *
     * Otherwise, it will:
     *
     * 1. Return empty slide data; PhotoSwipe will not show anything in the
     *    image area but will otherwise render UI controls properly (in most
     *    cases a cached renderable thumbnail URL will be available shortly)
     *
     * 2. Insert empty data so that we don't enqueue multiple updates, and
     *    return this empty data.
     *
     * Then it we start fetching data for the file.
     *
     * First it'll fetch the thumbnail. Once that is done, it'll update the data
     * it has cached, and notify the caller (using the provided callback) so it
     * can refresh the slide.
     *
     * Then it'll continue fetching the original.
     *
     * - For images and videos, this will be the single original.
     *
     * - For live photos, this will also be a two step process, first with the
     *   original image, then again with the video component.
     *
     * At this point, the data for this file will be considered final, and
     * subsequent calls for the same file will return this same value unless it
     * is invalidated.
     *
     * If at any point an error occurs, we reset our cache so that the next time
     * the data is requested we repeat the process instead of continuing to
     * serve the incomplete result.
     */
    itemDataForFile(file: EnteFile, needsRefresh: () => void) {
        let itemData = this.itemDataByFileID.get(file.id);
        // We assume that there is only one file viewer that is using us
        // at a given point of time. This assumption is currently valid.
        this.needsRefreshByFileID.set(file.id, needsRefresh);

        if (!itemData) {
            itemData = {};
            this.itemDataByFileID.set(file.id, itemData);
            void this.enqueueUpdates(file);
        }

        return itemData;
    }

    private async enqueueUpdates(file: EnteFile) {
        const update = (itemData: ItemData) => {
            this.itemDataByFileID.set(file.id, itemData);
            this.needsRefreshByFileID.get(file.id)?.();
        };

        const thumbnailURL = await downloadManager.renderableThumbnailURL(file);
        // TODO(PS):
        const thumbnailData = await withDimensions(thumbnailURL!);
        update({
            ...thumbnailData,
            isContentLoading: true,
            isContentZoomable: false,
        });

        switch (file.metadata.fileType) {
            case FileType.image: {
                const sourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                // TODO(PS):
                const itemData = await withDimensions(sourceURLs.url as string);
                update(itemData);
                break;
            }

            case FileType.video: {
                const sourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                // TODO(PS):
                update({ videoURL: sourceURLs.url as string });
                break;
            }

            case FileType.livePhoto: {
                const sourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                const livePhotoSourceURLs =
                    sourceURLs.url as LivePhotoSourceURL;
                const imageURL = await livePhotoSourceURLs.image();
                // TODO(PS):
                const imageData = await withDimensions(imageURL!);
                update(imageData);
                const livePhotoVideoURL = await livePhotoSourceURLs.video();
                update({ ...imageData, livePhotoVideoURL });
                break;
            }
        }
    }
}

/**
 * Take a image URL, determine its dimensions using browser APIs, and return the URL
 * and its dimensions in a form that can directly be passed to PhotoSwipe as
 * {@link ItemData}.
 */
const withDimensions = (imageURL: string): Promise<ItemData> =>
    new Promise((resolve) => {
        const image = new Image();
        image.onload = () => {
            resolve({
                src: imageURL,
                width: image.naturalWidth,
                height: image.naturalHeight,
            });
        };
        // image.onerror = ()
        // TODO(PS): Handle imageElement.onerror
        image.src = imageURL;
    });
