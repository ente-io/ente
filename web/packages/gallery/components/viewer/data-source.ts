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
export interface SlideData {
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

    // Our props. TODO(PS) document if end up using these.

    isContentLoading?: boolean;
    isContentZoomable?: boolean;
    isFinal?: boolean;
}

/**
 * A class that stores and serves data required by our custom PhotoSwipe
 * instance, effectively acting as an in-memory cache.
 *
 * By keeping this independent of the lifetime of the PhotoSwipe instance, we
 * can reuse the same cache for multiple displays of our file viewer.
 */
export class FileViewerDataSource {
    /**
     * The best available SlideData for rendering the file with the given ID.
     *
     * If an entry does not exist for a particular fileID, then it is lazily
     * added on demand, and updated as we keep getting better data (thumbnail,
     * original) for the file.
     */
    private itemDataByFileID = new Map<number, SlideData>();

    /**
     *
     * The {@link onUpdate} callback is invoked each time we have data about the
     * given {@link file}.
     *
     * If we already have the final data about file, then {@link onUpdate} will
     * be called once with this final {@link itemData}. Otherwise it'll be
     * called multiple times.
     *
     * 1. First with empty itemData.
     *
     * 2. Then with the thumbnail data.
     *
     * 3. Then with the original. For live photos, this will happen twice, first
     *    with the original image, then again with the video component.
     *
     * 4. At this point, the data for this file will be considered final, and
     *    subsequent calls for the same file will return this same value unless
     *    it is invalidated.
     *
     *   The same entry might get updated multiple times, as we start with the
     * thumbnail but then also update this as we keep getting more of the
     * original (e.g. for a live photo, it'll be updated once when we get the
     * original image, and then again later once we get the original video).
     *
     * @param index
     * @param file
     * @param onUpdate Callback invoked each time we have data about the given
     * {@link file}.
     */
    private async enqueueUpdates(
        file: EnteFile,
        onUpdate: (itemData: SlideData) => void,
    ) {
        const update = (itemData: SlideData) => {
            this.itemDataByFileID.set(file.id, itemData);
            onUpdate(itemData);
        };

        // We might not have anything to show immediately, though in most cases
        // a cached renderable thumbnail URL will be available shortly.
        //
        // Meanwhile,
        //
        // 1. Return empty slide data; PhotoSwipe will not show anything in the
        //    image area but will otherwise render UI controls properly.
        //
        // 2. Insert empty data so that we don't enqueue multiple updates.

        const itemData = this.itemDataByFileID.get(file.id);
            if (itemData) {
                itemData = {};
                this.itemDataByFileID.set(file.id, itemData);
                this.enqueueUpdates(index, file);
            }
        }

        const thumbnailURL = await downloadManager.renderableThumbnailURL(file);
        const thumbnailData = await augmentedWithDimensions(thumbnailURL);
        update({
            ...thumbnailData,
            isContentLoading: true,
            isContentZoomable: false,
        });

        switch (file.metadata.fileType) {
            case FileType.image: {
                const sourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                update(await augmentedWithDimensions(sourceURLs.url));
                break;
            }

            case FileType.video: {
                const sourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                const disableDownload = !!this.opts.disableDownload;
                update({ html: videoHTML(sourceURLs.url, disableDownload) });
                break;
            }

            default: {
                const sourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                const livePhotoSourceURLs =
                    sourceURLs.url as LivePhotoSourceURL;
                const imageURL = await livePhotoSourceURLs.image();
                const imageData = await augmentedWithDimensions(imageURL);
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
 * {@link SlideData}.
 */
const augmentedWithDimensions = (imageURL: string): Promise<SlideData> =>
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
