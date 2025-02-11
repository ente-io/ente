/* eslint-disable */
// @ts-nocheck

import type { EnteFile } from "@/media/file";

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
    pswp: PhotoSwipe;

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
            return files.length;
        });
        // const enqueueUpdates = index;
        pswp.addFilter("itemData", (itemData, index) => {
            const file = files[index];
            console.log({ itemData, index, file });

            return {
                src: `https://dummyimage.com/100/777/fff/?text=i${index}`,
                width: 100,
                height: 100,
            };
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
        this.pswp = undefined;
    }

    updateFiles(files: EnteFile[]) {
        // TODO(PS)
    }
}
