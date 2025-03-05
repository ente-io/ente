/* eslint-disable */
// @ts-nocheck

import { pt } from "@/base/i18n";
import log from "@/base/log";
import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { t } from "i18next";
import {
    fileViewerDidClose,
    fileViewerWillOpen,
    forgetExifForItemData,
    forgetFailedItemDataForFileID,
    itemDataForFile,
    updateFileInfoExifIfNeeded,
} from "./data-source";
import {
    type FileViewerAnnotatedFile,
    type FileViewerFileAnnotation,
} from "./FileViewer";
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
    PhotoSwipe = require("./ps5/dist/photoswipe.esm.js").default;
}

export interface FileViewerPhotoSwipeDelegate {
    /**
     * Called to obtain the latest list of files.
     *
     * [Note: Changes to underlying files when file viewer is open]
     *
     * The list of files shown by the viewer might change while the viewer is
     * open. We do not actively refresh the viewer when this happens since that
     * would result in the user's zoom / pan state being lost.
     *
     * However, we always read the latest list via the delegate, so any
     * subsequent user initiated slide navigation (e.g. moving to the next
     * slide) will use the new list.
     */
    getFiles: () => EnteFile[];
    /**
     * Return `true` if the provided file has been marked as a favorite by the
     * user.
     *
     * The toggle favorite button will not be shown for the file if
     * this callback returns `undefined`. Otherwise the return value determines
     * the toggle state of the toggle favorite button for the file.
     */
    isFavorite: (annotatedFile: FileViewerAnnotatedFile) => boolean | undefined;
    /**
     * Called when the user activates the toggle favorite action on a file.
     *
     * The toggle favorite button will be disabled for the file until the
     * promise returned by this function returns fulfills.
     *
     * > Note: The caller is expected to handle any errors that occur, and
     * > should not reject for foreseeable failures, otherwise the button will
     * > remain in the disabled state (until the file viewer is closed).
     */
    toggleFavorite: (annotatedFile: FileViewerAnnotatedFile) => Promise<void>;
}

type FileViewerPhotoSwipeOptions = Pick<
    FileViewerProps,
    "initialIndex" | "disableDownload"
> & {
    /**
     * `true` if we're running in the context of a logged in user, and so
     * various actions that modify the file should be shown.
     *
     * This is the static variant of various per file annotations that control
     * various modifications. If this is not `true`, then various actions like
     * favorite, delete etc are never shown. If this is `true`, then their
     * visibility depends on the corresponding annotation.
     *
     * For example, the favorite action is shown only if both this and the
     * {@link showFavorite} file annotation are true.
     */
    haveUser: boolean;
    /**
     * Dynamic callbacks.
     *
     * The extra level of indirection allows these to be updated without
     * recreating us.
     */
    delegate: FileViewerPhotoSwipeDelegate;
    /**
     * Called when the file viewer is closed.
     */
    onClose: () => void;
    /**
     * Called whenever the slide is initially displayed or changes, to obtain
     * various derived data for the file that is about to be displayed.
     */
    onAnnotate: (file: EnteFile) => FileViewerFileAnnotation;
    /**
     * Called when the user activates the info action on a file.
     */
    onViewInfo: (annotatedFile: FileViewerAnnotatedFile) => void;
    /**
     * Called when the user activates the download action on a file.
     */
    onDownload: (annotatedFile: FileViewerAnnotatedFile) => void;
    /**
     * Called when the user activates the more action on a file.
     *
     * @param annotatedFile The current (annotated) file.
     *
     * @param imageURL If the current file has an associated non-thumbnail image
     * that is being shown in the viewer, then this is set to the (object) URL
     * of the image being shown. Specifically, this is the same as the
     * {@link imageURL} attribute of the {@link ItemData} associated with the
     * current file.
     *
     * @param buttonElement The more button DOM element.
     */
    onMore: (
        annotatedFile: FileViewerAnnotatedFile,
        imageURL: string | undefined,
        buttonElement: HTMLElement,
    ) => void;
};

/**
 * The ID that is used by the "more" action button (if one is being displayed).
 *
 * @see also {@link moreMenuID}.
 */
export const moreButtonID = "ente-pswp-more-button";

/**
 * The ID this is expected to be used by the more menu that is shown in response
 * to the more action button being activated.
 *
 * @see also {@link moreButtonID}.
 */
export const moreMenuID = "ente-pswp-more-menu";

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
    /**
     * Derived data about the currently displayed file.
     *
     * This is recomputed on-demand (by using the {@link onAnnotate} callback)
     * each time the slide changes, and cached until the next slide change.
     *
     * Instead of accessing this property directly, code should funnel through
     * the `activeFileAnnotation` helper function defined in the constructor
     * scope.
     */
    private activeFileAnnotation: FileViewerFileAnnotation | undefined;
    /**
     * IDs of files for which a there is a favorite update in progress.
     */
    private pendingFavoriteUpdates = new Set<number>();

    constructor({
        initialIndex,
        disableDownload,
        haveUser,
        delegate,
        onClose,
        onAnnotate,
        onViewInfo,
        onDownload,
        onMore,
    }: FileViewerPhotoSwipeOptions) {
        this.opts = { disableDownload };
        this.lastActivityDate = new Date();

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

        this.pswp = pswp;

        // Various helper routines to obtain the file at `currIndex`.

        const currentFile = () => delegate.getFiles()[pswp.currIndex]!;

        const currentAnnotatedFile = () => {
            const file = currentFile();
            let annotation = this.activeFileAnnotation;
            if (annotation?.fileID != file.id) {
                annotation = onAnnotate(file);
                this.activeFileAnnotation = annotation;
            }
            return {
                file,
                // The above condition implies that annotation can never be
                // undefined, but it doesn't seem to be enough to convince
                // TypeScript. Writing the condition in a more unnatural way
                // `(!(annotation && annotation?.fileID == file.id))` works, but
                // instead we use a non-null assertion here.
                annotation: annotation!,
            };
        };

        const currentFileAnnotation = () => currentAnnotatedFile().annotation;

        // Provide data about slides to PhotoSwipe via callbacks
        // https://photoswipe.com/data-sources/#dynamically-generated-data

        pswp.addFilter("numItems", () => delegate.getFiles().length);

        pswp.addFilter("itemData", (_, index) => {
            const files = delegate.getFiles();
            const file = files[index]!;

            let itemData = itemDataForFile(file, () =>
                pswp.refreshSlideContent(index),
            );

            const { videoURL, ...rest } = itemData;
            if (itemData.fileType === FileType.video && videoURL) {
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
            const fileID = e.content?.data?.fileID;
            if (fileID) forgetFailedItemDataForFileID(fileID);

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

        pswp.on("change", (e) => {
            const itemData = this.pswp.currSlide.content.data;
            updateFileInfoExifIfNeeded(itemData);
        });

        pswp.on("contentDestroy", (e) => forgetExifForItemData(e.content.data));

        // State needed to hide the caption when a video is playing.
        let videoElement: HTMLVideoElement | undefined;
        let onVideoPlayback: EventHandler | undefined;
        let captionElementRef: HTMLElement | undefined;

        pswp.on("change", (e) => {
            const itemData = this.pswp.currSlide.content.data;

            // Clear existing listeners, if any.
            if (videoElement && onVideoPlayback) {
                videoElement.removeEventListener("play", onVideoPlayback);
                videoElement.removeEventListener("pause", onVideoPlayback);
                videoElement.removeEventListener("ended", onVideoPlayback);
                videoElement = undefined;
                onVideoPlayback = undefined;
            }

            // Reset.
            showIf(captionElementRef, true);

            // Attach new listeners, if needed.
            if (itemData.fileType == FileType.video) {
                const contentElement = pswp.currSlide.content.element;
                videoElement = contentElement.getElementsByTagName("video")[0];
                if (videoElement) {
                    onVideoPlayback = (e) => {
                        showIf(captionElementRef, !!videoElement?.paused);
                    };
                    videoElement.addEventListener("play", onVideoPlayback);
                    videoElement.addEventListener("pause", onVideoPlayback);
                    videoElement.addEventListener("ended", onVideoPlayback);
                }
            }
        });

        // The PhotoSwipe dialog has being closed and the animations have
        // completed.
        pswp.on("destroy", () => {
            this.clearAutoHideIntervalIfNeeded();
            fileViewerDidClose();
            // Let our parent know that we have been closed.
            onClose();
        });

        const handleViewInfo = () => onViewInfo(currentAnnotatedFile());

        let favoriteButtonElement: HTMLButtonElement | undefined;
        let unfavoriteButtonElement: HTMLButtonElement | undefined;

        const toggleFavorite = async () => {
            const af = currentAnnotatedFile();
            this.pendingFavoriteUpdates.add(af.file.id);
            favoriteButtonElement.disabled = true;
            unfavoriteButtonElement.disabled = true;
            await delegate.toggleFavorite(af);
            this.pendingFavoriteUpdates.delete(af.file.id);
            // TODO: We reload the entire slide instead of just updating
            // the button state. This is because there are two buttons,
            // instead of a single button toggling between two states
            // e.g. like the zoom button.
            //
            // To fix this, a single button can be achieved by moving
            // the fill of the heart as a layer.
            this.refreshCurrentSlideContent();
        };

        const handleToggleFavorite = () => void toggleFavorite();

        const handleDownload = () => onDownload(currentAnnotatedFile());

        const showIf = (element: HTMLElement, condition: boolean) =>
            condition
                ? element.classList.remove("pswp__hidden")
                : element.classList.add("pswp__hidden");

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
            // Move the zoom button to the left so that it is in the same place
            // as the other items like preloader or the error indicator that
            // come and go as files get loaded.
            //
            // We cannot use the PhotoSwipe "uiElement" filter to modify the
            // order since that only allows us to edit the DOM element, not the
            // underlying UI element data.
            pswp.ui.uiElementsData.find((e) => e.name == "zoom").order = 6;

            // Register our custom elements...

            pswp.ui.registerElement({
                name: "error",
                order: 6,
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

            if (haveUser) {
                const showFavoriteIf = (
                    buttonElement: HTMLButtonElement,
                    value: boolean,
                ) => {
                    const af = currentAnnotatedFile();
                    const isFavorite = delegate.isFavorite(af);
                    showIf(
                        buttonElement,
                        af.annotation.showFavorite && isFavorite === value,
                    );
                    buttonElement.disabled = this.pendingFavoriteUpdates.has(
                        af.file.id,
                    );
                };

                // Only one of these two ("favorite" or "unfavorite") will end
                // up being shown, so they can safely share the same order.
                pswp.ui.registerElement({
                    name: "favorite",
                    title: t("favorite"),
                    order: 8,
                    isButton: true,
                    html: createPSRegisterElementIconHTML("favorite"),
                    onClick: handleToggleFavorite,
                    onInit: (buttonElement) =>
                        pswp.on("change", () =>
                            showFavoriteIf(buttonElement, false),
                        ),
                });
                pswp.ui.registerElement({
                    name: "unfavorite",
                    title: t("unfavorite"),
                    order: 8,
                    isButton: true,
                    html: createPSRegisterElementIconHTML("unfavorite"),
                    onClick: handleToggleFavorite,
                    onInit: (buttonElement) =>
                        pswp.on("change", () =>
                            showFavoriteIf(buttonElement, true),
                        ),
                });
            } else {
                // When we don't have a user (i.e. in the context of public
                // albums), the download button is shown (if enabled for that
                // album) instead of the favorite button as the first action.
                //
                // It can thus also use the same order as fav/unfav.
                pswp.ui.registerElement({
                    name: "download",
                    title: t("download"),
                    order: 8,
                    isButton: true,
                    html: createPSRegisterElementIconHTML("download"),
                    onClick: handleDownload,
                    onInit: (buttonElement) =>
                        pswp.on("change", () =>
                            showIf(
                                buttonElement,
                                currentFileAnnotation().showDownload == "bar",
                            ),
                        ),
                });
            }

            pswp.ui.registerElement({
                name: "info",
                title: t("info"),
                order: 9,
                isButton: true,
                html: createPSRegisterElementIconHTML("info"),
                onClick: handleViewInfo,
            });

            pswp.ui.registerElement({
                name: "more",
                // TODO(PS):
                title: pt("More"),
                order: 16,
                isButton: true,
                html: createPSRegisterElementIconHTML("more"),
                onInit: (buttonElement) => {
                    buttonElement.setAttribute("id", moreButtonID);
                    buttonElement.setAttribute("aria-haspopup", "true");
                },
                onClick: (e) => {
                    const buttonElement = e.target;
                    // See also: `resetMoreMenuButtonOnMenuClose`.
                    buttonElement.setAttribute("aria-controls", moreMenuID);
                    buttonElement.setAttribute("aria-expanded", true);
                    onMore(
                        currentAnnotatedFile(),
                        pswp.currSlide.content.data.imageURL,
                        buttonElement,
                    );
                },
            });

            pswp.ui.registerElement({
                name: "caption",
                // Arbitrary order towards the end (it doesn't matter anyways
                // since we're absolutely positioned).
                order: 30,
                appendTo: "root",
                tagName: "p",
                onInit: (captionElement, pswp) => {
                    captionElementRef = captionElement;
                    pswp.on("change", () => {
                        const { fileType, alt } = pswp.currSlide.content.data;
                        captionElement.innerText = alt ?? "";
                        captionElement.style.visibility = alt
                            ? "visible"
                            : "hidden";
                        // Add extra offset for video captions so that they do
                        // not overlap with the video controls. The constant is
                        // an ad-hoc value that looked okay-ish across browsers.
                        captionElement.style.bottom =
                            fileType === FileType.video ? "36px" : "0";
                    });
                },
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

        pswp.on("keydown", (e, z) => {
            const key = e.originalEvent.key ?? "";
            const cb = (() => {
                switch (key.toLowerCase()) {
                    case "l":
                        return handleToggleFavorite;
                    case "d":
                        return handleDownload;
                    case "i":
                        return handleViewInfo;
                }
                return undefined;
            })();
            cb?.();
        });

        // Let our data source know that we're about to open.
        fileViewerWillOpen();

        // Initializing PhotoSwipe adds it to the DOM as a dialog-like div with
        // the class "pswp".
        pswp.init();

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

    /**
     * Reload the current slide, asking the data source for its data afresh.
     */
    refreshCurrentSlideContent() {
        this.pswp.refreshSlideContent(this.pswp.currIndex);
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

/**
 * Update the ARIA attributes for the button that controls the more menu when
 * the menu is closed.
 */
export const resetMoreMenuButtonOnMenuClose = (buttonElement: HTMLElement) => {
    buttonElement.removeAttribute("aria-controls");
    buttonElement.removeAttribute("aria-expanded");
};
