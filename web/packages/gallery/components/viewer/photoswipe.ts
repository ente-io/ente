/* eslint-disable */
// @ts-nocheck

import log from "@/base/log";
import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { t } from "i18next";
import {
    forgetExif,
    forgetExifForItemData,
    forgetFailedItemDataForFile,
    forgetFailedItems,
    itemDataForFile,
    updateFileInfoExifIfNeeded,
} from "./data-source";
import type { FileViewerProps } from "./FileViewer";
import { createPSRegisterElementIconHTML } from "./icons";

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
    // TODO(PS): Comment me before merging into main.
    // PhotoSwipe = require("./ps5/dist/photoswipe.esm.js").default;
}

type FileViewerPhotoSwipeOptions = FileViewerProps & {
    /**
     * Called when the file viewer is closed.
     */
    onClose: () => void;
    /**
     * Called when the user activates the info action on a file.
     */
    onViewInfo: (file: EnteFile) => void;
};

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
    /**
     * The PhotoSwipe instance which we wrap.
     */
    private pswp: PhotoSwipe;
    /**
     * The options with which we were initialized.
     */
    private opts: Pick<FileViewerPhotoSwipeOptions, "disableDownload">;
    /**
     * An interval that invokes a periodic check of whether we should the hide
     * controls if the user does not perform any pointer events for a while.
     */
    private autoHideCheckIntervalId: ReturnType<typeof setTimeout> | undefined;
    /**
     * The time the last activity occurred. Used in tandem with
     * {@link autoHideCheckIntervalId} to implement the auto hiding of controls
     * when the user stops moving the pointer for a while.
     *
     * Apart from a date, this can also be:
     *
     * - "already-hidden" if controls have already been hidden, say by a
     *   bgClickAction.
     *
     * - "auto-hidden" if controls were hidden by us because of inactivity.
     */
    private lastActivityDate: Date | "auto-hidden" | "already-hidden";

    constructor({
        files,
        initialIndex,
        disableDownload,
        onClose,
        onViewInfo,
    }: FileViewerPhotoSwipeOptions) {
        this.files = files;
        this.opts = { disableDownload };

        const pswp = new PhotoSwipe({
            // Opaque background.
            bgOpacity: 1,
            // The default, "zoom", cannot be used since we're not animating
            // from a thumbnail, so effectively "fade" is in effect anyway. Set
            // it still, just for and explicitness and documentation.
            showHideAnimationType: "fade",
            // The default imageClickAction is "zoom-or-close". When the image
            // is small and cannot be zoomed into further (which is common when
            // just the thumbnail has been loaded), this causes PhotoSwipe to
            // close. Disable this behaviour.
            clickToCloseNonZoomable: false,
            // The default `bgClickAction` is "close", but it is not always
            // apparent where the background is and where the controls are,
            // since everything is black, and so accidentally closing PhotoSwipe
            // is easy.
            //
            // Disable this behaviour, instead repurposing this action to behave
            // the same as the `tapAction` ("tap on PhotoSwipe viewport
            // content") and toggle the visibility of UI controls (We also have
            // auto hide based on mouse activity, but that would not have any
            // effect on touch devices)
            bgClickAction: "toggle-controls",
            // At least on macOS, manual zooming with the trackpad is very
            // cumbersome (possibly because of the small multiplier in the
            // PhotoSwipe source, but I'm not sure). The other option to do a
            // manual zoom is to scroll (e.g. with the trackpad) but with the
            // CTRL key pressed, however on macOS this invokes the system zoom
            // if enabled in accessibility settings.
            //
            // Taking a step back though, the PhotoSwipe viewport is fixed, so
            // we can just directly map wheel / trackpad scrolls to zooming.
            wheelToZoom: true,
            // Chrome yells about incorrectly mixing focus and aria-hidden if we
            // leave this at the default (true) and then swipe between slides
            // fast, or show MUI drawers etc.
            //
            // See: [Note: Overzealous Chrome? Complicated ARIA?], but time with
            // a different library.
            trapFocus: false,
            // Set the index within files that we should open to. Subsequent
            // updates to the index will be tracked by PhotoSwipe internally.
            index: initialIndex,
            // TODO(PS): padding option? for handling custom title bar.
            // TODO(PS): will we need this?
            mainClass: "pswp-ente",
            // Translated variants
            closeTitle: t("close_key"),
            zoomTitle: t("zoom_in_out_key") /* TODO(PS): Add "(scroll)" */,
            arrowPrevTitle: t("previous_key"),
            arrowNextTitle: t("next_key"),
            // TODO(PS): Move to translations (unpreviewable_file_notification).
            errorMsg: "This file could not be previewed",
        });

        // Helper routines to obtain the file at `currIndex`.
        const currentFile = () => this.files[pswp.currIndex]!;
        const withCurrentFile = (cb: (file: EnteFile) => void) => () =>
            cb(currentFile());

        // Provide data about slides to PhotoSwipe via callbacks
        // https://photoswipe.com/data-sources/#dynamically-generated-data

        pswp.addFilter("numItems", () => {
            return this.files.length;
        });

        pswp.addFilter("itemData", (_, index) => {
            const file = files[index]!;

            let itemData = itemDataForFile(file, () => {
                this.pswp.refreshSlideContent(index);
            });

            const { fileType, videoURL, ...rest } = itemData;
            if (fileType === FileType.video && videoURL) {
                const disableDownload = !!this.opts.disableDownload;
                itemData = {
                    ...rest,
                    html: videoHTML(videoURL, disableDownload),
                };
            }

            log.debug(() => ["[viewer]", { index, itemData, file }]);

            if (this.lastActivityDate != "already-hidden")
                this.lastActivityDate = new Date();

            return itemData;
        });

        pswp.addFilter("isContentLoading", (isLoading, content) => {
            return content.data.isContentLoading ?? isLoading;
        });

        pswp.addFilter("isContentZoomable", (isZoomable, content) => {
            return content.data.isContentZoomable ?? isZoomable;
        });

        pswp.addFilter("preventPointerEvent", (preventPointerEvent) => {
            // There was a pointer event. We don't care which one, we just use
            // this as a hook to show the UI again (if needed), and update our
            // last activity date.
            this.onPointerActivity();
            return preventPointerEvent;
        });

        pswp.on("contentAppend", (e) => {
            const { fileType, videoURL } = e.content.data;
            if (fileType !== FileType.livePhoto) return;
            if (!videoURL) return;

            // This slide is displaying a live photo. Append a video element to
            // show its video part.

            const img = e.content.element;
            const video = createElementFromHTMLString(
                livePhotoVideoHTML(videoURL),
            );
            const container = e.content.slide.container;
            container.style = "position: relative";
            container.appendChild(video);
            // Set z-index to 1 to keep it on top, and set pointer-events to
            // none to pass the clicks through.
            video.style =
                "position: absolute; top: 0; left: 0; z-index: 1; pointer-events: none;";

            // Size it to the underlying image.
            video.style.width = img.style.width;
            video.style.height = img.style.height;
        });

        pswp.on("imageSizeChange", ({ content, width, height }) => {
            if (content.data.fileType !== FileType.livePhoto) return;

            // This slide is displaying a live photo. Resize the size of the
            // video element to match that of the image.

            const video =
                content.slide.container.getElementsByTagName("video")[0];
            if (!video) {
                // We might have been called before "contentAppend".
                return;
            }

            video.style.width = `${width}px`;
            video.style.height = `${height}px`;
        });

        pswp.on("contentDeactivate", (e) => {
            // Reset failures, if any, for this file so that the fetch is tried
            // again when we come back to it^.
            //
            // ^ Note that because of how the preloading works, this will have
            //   an effect (i.e. the retry will happen) only if the user moves
            //   more than 2 slides and then back, or if they reopen the viewer.
            //
            // See: [Note: File viewer error handling]
            forgetFailedItemDataForFile(currentFile());

            // Pause the video element, if any, when we move away from the
            // slide.
            const video =
                e.content?.slide?.container?.getElementsByTagName("video")[0];
            video?.pause();
        });

        pswp.on("contentActivate", (e) => {
            // Undo the effect of a previous "contentDeactivate" if it was
            // displaying a live photo.
            if (e.content?.slide.data?.fileType === FileType.livePhoto) {
                e.content?.slide?.container
                    ?.getElementsByTagName("video")[0]
                    ?.play();
            }
        });

        pswp.on("loadComplete", (e) =>
            updateFileInfoExifIfNeeded(e.content.data),
        );

        // pswp.on("change", (e) => {
        //     const itemData = pswp.currSlide.content.data;
        //     exifForItemData(itemData).then((data) =>
        //         console.log("exif data", data),
        //     );
        // });

        pswp.on("contentDestroy", (e) => forgetExifForItemData(e.content.data));

        // The PhotoSwipe dialog has being closed and the animations have
        // completed.
        pswp.on("destroy", () => {
            this.clearAutoHideIntervalIfNeeded();
            forgetFailedItems();
            forgetExif();
            // Let our parent know that we have been closed.
            onClose();
        });

        // Add our custom UI elements to inside the PhotoSwipe dialog.
        //
        // API docs for registerElement:
        // https://photoswipe.com/adding-ui-elements/#uiregisterelement-api
        //
        // The "order" prop is used to position items. Some landmarks:
        // - counter: 5
        // - preloader: 7
        // - zoom: 10
        // - close: 20
        pswp.on("uiRegister", () => {
            pswp.ui.registerElement({
                name: "error",
                order: 6,
                // TODO(PS): Change color?
                html: createPSRegisterElementIconHTML("error"),
                onInit: (errorElement, pswp) => {
                    pswp.on("change", () => {
                        const { fetchFailed, isContentLoading } =
                            pswp.currSlide.content.data;
                        errorElement.classList.toggle(
                            "pswp__error--active",
                            !!fetchFailed && !isContentLoading,
                        );
                    });
                },
            });
            pswp.ui.registerElement({
                name: "info",
                title: t("info"),
                order: 15,
                isButton: true,
                html: createPSRegisterElementIconHTML("info"),
                onClick: withCurrentFile(onViewInfo),
            });
        });

        // Modify the default UI elements.
        pswp.addFilter("uiElement", (element, data) => {
            if (element.name == "preloader") {
                // TODO(PS): Left as an example. For now, this is customized in
                // the CSS.
            }
            return element;
        });

        // Initializing PhotoSwipe adds it to the DOM as a dialog-like div with
        // the class "pswp".
        pswp.init();

        this.pswp = pswp;

        this.autoHideCheckIntervalId = setInterval(() => {
            this.autoHideIfInactive();
        }, 1000);
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

    private clearAutoHideIntervalIfNeeded() {
        if (this.autoHideCheckIntervalId) {
            clearInterval(this.autoHideCheckIntervalId);
            this.autoHideCheckIntervalId = undefined;
        }
    }

    private onPointerActivity() {
        if (this.lastActivityDate == "already-hidden") return;
        if (this.lastActivityDate == "auto-hidden") this.showUIControls();
        this.lastActivityDate = new Date();
    }

    private autoHideIfInactive() {
        if (this.lastActivityDate == "already-hidden") return;
        if (this.lastActivityDate == "auto-hidden") return;
        if (Date.now() - this.lastActivityDate.getTime() > 5000 /* 5s */) {
            if (this.areUIControlsVisible()) {
                this.hideUIControlsIfNotFocused();
                this.lastActivityDate = "auto-hidden";
            } else {
                this.lastActivityDate = "already-hidden";
            }
        }
    }

    private areUIControlsVisible() {
        return this.pswp.element.classList.contains("pswp--ui-visible");
    }

    private showUIControls() {
        this.pswp.element.classList.add("pswp--ui-visible");
    }

    private hideUIControlsIfNotFocused() {
        // Check if the current keyboard focus is on any of the UI controls.
        //
        // By default, the pswp root element takes up the keyboard focus, so we
        // check if the currently focused element is still the PhotoSwipe dialog
        // (if so, this means we're not focused on a specific control).
        const isDefaultFocus = document
            .querySelector(":focus-visible")
            ?.classList.contains("pswp");
        if (!isDefaultFocus) {
            // The user focused (e.g. via keyboard tabs) to a specific UI
            // element. Skip auto hiding.
            return;
        }

        // TODO(PS): Commented during testing
        // this.pswp.element.classList.remove("pswp--ui-visible");
    }
}

const videoHTML = (url: string, disableDownload: boolean) => `
<video controls ${disableDownload && "controlsList=nodownload"} oncontextmenu="return false;">
  <source src="${url}" />
  Your browser does not support video playback.
</video>
`;

const livePhotoVideoHTML = (videoURL: string) => `
<video autoplay loop muted oncontextmenu="return false;">
  <source src="${videoURL}" />
</video>
`;

const createElementFromHTMLString = (htmlString: string) => {
    const template = document.createElement("template");
    // Excess whitespace causes excess DOM nodes, causing our firstChild to not
    // be what we wanted them to be.
    template.innerHTML = htmlString.trim();
    return template.content.firstChild;
};
