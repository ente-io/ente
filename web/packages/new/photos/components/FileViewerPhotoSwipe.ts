/* eslint-disable */
// @ts-nocheck

import { assertionFailed } from "@/base/assert";
import log from "@/base/log";
import { downloadManager } from "@/gallery/services/download";
import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";

// TODO(PS): WIP gallery using upstream photoswipe
//
// Needs (not committed yet):
// yarn workspace gallery add photoswipe@^5.4.4
// mv node_modules/photoswipe packages/new/photos/components/ps5

if (process.env.NEXT_PUBLIC_ENTE_WIP_PS5) {
    console.warn("Using WIP upstream photoswipe");
} else {
    throw new Error("Whoa");
}

let PhotoSwipe;
if (process.env.NEXT_PUBLIC_ENTE_WIP_PS5) {
    PhotoSwipe = require("./ps5/dist/photoswipe.esm.js").default;
}
// TODO(PS):
//import { type SlideData } from "./ps5/dist/types/slide/"
type SlideData = {
    /**
     * thumbnail element
     */
    element?: HTMLElement | undefined;
    /**
     * image URL
     */
    src?: string | undefined;
    /**
     * image srcset
     */
    srcset?: string | undefined;
    /**
     * image width (deprecated)
     */
    w?: number | undefined;
    /**
     * image height (deprecated)
     */
    h?: number | undefined;
    /**
     * image width
     */
    width?: number | undefined;
    /**
     * image height
     */
    height?: number | undefined;
    /**
     * placeholder image URL that's displayed before large image is loaded
     */
    msrc?: string | undefined;
    /**
     * image alt text
     */
    alt?: string | undefined;
    /**
     * whether thumbnail is cropped client-side or not
     */
    thumbCropped?: boolean | undefined;
    /**
     * html content of a slide
     */
    html?: string | undefined;
    /**
     * slide type
     */
    type?: string | undefined;
};

interface FileViewerPhotoSwipeOptions {
    files: EnteFile[];
    initialIndex: number;
    onClose: () => void;
}

/**
 * A wrapper over {@link PhotoSwipe} to tailor its interface for use by our file
 * viewer.
 *
 * This is somewhat akin to the {@link PhotoSwipeLightbox}, except this doesn't
 * have any UI of its own, it only modifies PhotoSwipe Core's behaviour.
 *
 * [Note: PhotoSwipe]
 *
 * PhotoSwipe is a library that behaves similarly to the OG "lightbox" image
 * gallery JavaScript component from the middle ages.
 *
 * We don't need the lightbox functionality since we already have our own
 * thumbnail list (the "gallery"), so we only use the "Core" PhotoSwipe module
 * as our image viewer component.
 *
 * When the user clicks on one of the thumbnails in our gallery, we make the
 * root PhotoSwipe component visible. Within the DOM this is a dialog-like div
 * that takes up the entire viewport, shows the image, various controls etc.
 *
 * Documentation: https://photoswipe.com/.
 */
export class FileViewerPhotoSwipe {
    private pswp: PhotoSwipe;
    private itemDataByFileID: Map<number, SlideData> = new Map();

    constructor({ files, initialIndex, onClose }: FileViewerPhotoSwipeOptions) {
        this.files = files;

        const pswp = new PhotoSwipe({
            // Opaque background.
            bgOpacity: 1,
            // Set the index within files that we should open to. Subsequent
            // updates to the index will be tracked by PhotoSwipe internally.
            index: initialIndex,
            // TODO(PS): padding option? for handling custom title bar.
            // TODO(PS): will we need this?
            mainClass: "our-extra-pswp-main-class",
        });
        // Provide data about slides to PhotoSwipe via callbacks
        // https://photoswipe.com/data-sources/#dynamically-generated-data
        pswp.addFilter("numItems", () => {
            return this.files.length;
        });
        // const enqueueUpdates = index;
        pswp.addFilter("itemData", (_, index) => {
            const file = files[index];

            let itemData: SlideData | undefined;
            if (file) {
                itemData = this.itemDataByFileID.get(file.id);
                if (!itemData) {
                    // We don't have anything to show immediately, though in
                    // most cases a cached renderable thumbnail URL will be
                    // available shortly.
                    //
                    // Meanwhile,
                    //
                    // 1. Return empty slide data; PhotoSwipe will not show
                    //    anything in the image area but will otherwise render
                    //    the surrounding UI properly.
                    //
                    // 2. Insert empty data so that we don't enqueue multiple
                    //    updates.
                    itemData = {};
                    this.itemDataByFileID.set(file.id, itemData);
                    this.enqueueUpdates(index, file);
                }
            }

            log.debug(() => ["[ps]", { itemData, index, file, itemData }]);
            if (!file) assertionFailed();

            return itemData ?? {};
        });
        pswp.on("close", () => {
            // The user did some action within the file viewer to close it. Let
            // our parent know that we have been closed.
            onClose();
        });
        // Initializing PhotoSwipe adds it to the DOM as a dialog-like div with
        // the class "pswp".
        pswp.init();

        this.pswp = pswp;
    }

    /**
     * Close this instance of {@link FileViewerPhotoSwipe} if it hasn't itself
     * initiated the close.
     *
     * This instance **cannot** be used after this function has been called.
     */
    closeIfNeeded() {
        // Closing PhotoSwipe removes it from the DOM.
        //
        // This will only have an effect if we're being closed externally (e.g.
        // if the user selects an album in the file info).
        //
        // If this cleanup function is running in the sequence where we were
        // closed internally (e.g. the user activated the close button within
        // the file viewer), then PhotoSwipe will ignore this extra close.
        this.pswp.close();
    }

    updateFiles(files: EnteFile[]) {
        // TODO(PS)
    }

    async enqueueUpdates(index: number, file: EnteFile) {
        const update = (itemData: SlideData) => {
            this.itemDataByFileID.set(file.id, itemData);
            this.pswp.refreshSlideContent(index);
        };

        const thumbnailURL = await downloadManager.renderableThumbnailURL(file);
        // We don't have the dimensions of the thumbnail. We could try to deduce
        // something from the file's aspect ratio etc, but that's not needed:
        // PhotoSwipe already correctly (for our purposes) handles just a source
        // URL being present.
        update({ src: thumbnailURL });

        switch (file.metadata.fileType) {
            case FileType.image: {
                const sourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                update({
                    src: sourceURLs.url,
                    width: file.pubMagicMetadata?.data?.w,
                    height: file.pubMagicMetadata?.data?.h,
                });
                break;
            }

            default:
                break;
        }
    }
}
