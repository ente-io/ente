import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import "hls-video-element";
import { t } from "i18next";
import "media-chrome";
import PhotoSwipe, { type SlideData } from "photoswipe";
import {
    fileViewerDidClose,
    fileViewerWillOpen,
    forgetExifForItemData,
    forgetFailedItemDataForFileID,
    itemDataForFile,
    updateFileInfoExifIfNeeded,
    type ItemData,
} from "./data-source";
import {
    type FileViewerAnnotatedFile,
    type FileViewerProps,
} from "./FileViewer";
import { createPSRegisterElementIconHTML } from "./icons";

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
     * this callback returns `undefined`. Otherwise the return value determines
     * the toggle state of the toggle favorite button for the file.
     */
    isFavorite: (annotatedFile: FileViewerAnnotatedFile) => boolean | undefined;
    /**
     * Return `true` if there is an inflight request to update the favorite
     * status of the file.
     */
    isFavoritePending: (annotatedFile: FileViewerAnnotatedFile) => boolean;
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
    /**
     * Called when there is a keydown event, and our PhotoSwipe instance wants
     * to know if it should ignore it or handle it.
     *
     * The delegate should return true when, e.g., the file info dialog is
     * being displayed.
     */
    shouldIgnoreKeyboardEvent: () => boolean;
    /**
     * Called when the user triggers a potential action using a keyboard
     * shortcut.
     *
     * The caller does not check if the action is valid in the current context,
     * so the delegate must validate and only then perform the action if it is
     * appropriate.
     */
    performKeyAction: (
        action:
            | "delete"
            | "toggle-archive"
            | "copy"
            | "toggle-fullscreen"
            | "help",
    ) => void;
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
     *
     * @param file The current {@link EnteFile}. This is the same value as the
     * corresponding value in the current index of {@link getFiles} returned by
     * the delegate.
     *
     * @param itemData This is the best currently available {@link ItemData}
     * corresponding to the current file.
     */
    onAnnotate: (file: EnteFile, itemData: ItemData) => FileViewerAnnotatedFile;
    /**
     * Called when the user activates the info action on a file.
     */
    onViewInfo: (annotatedFile: FileViewerAnnotatedFile) => void;
    /**
     * Called when the user activates the download action on a file.
     */
    onDownload: (annotatedFile: FileViewerAnnotatedFile) => void;
    /**
     * Called when the user activates the more action.
     *
     * @param buttonElement The more button DOM element.
     */
    onMore: (buttonElement: HTMLElement) => void;
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
            // Use "pswp-ente" as the main class name. Note that this is not
            // necessary, we could've target the "pswp" class too in our CSS
            // since we only have a single PhotoSwipe instance.
            mainClass: "pswp-ente",
            closeTitle: t("close"),
            zoomTitle: t("zoom"),
            arrowPrevTitle: t("previous"),
            arrowNextTitle: t("next"),
            errorMsg: t("unpreviewable_file_message"),
        });

        this.pswp = pswp;

        // Various helper routines to obtain the file at `currIndex`.

        /**
         * Derived data about the currently displayed file.
         *
         * This is recomputed on-demand (by using the {@link onAnnotate}
         * callback) each time the slide changes, and cached until the next
         * slide change.
         *
         * Instead of accessing this property directly, code should funnel
         * through the `currentAnnotatedFile` helper function.
         */
        let _currentAnnotatedFile: FileViewerAnnotatedFile | undefined;

        /**
         * Non-null assert and casted the given {@link SlideData} as
         * {@link ItemData}.
         *
         * PhotoSwipe types specify currSlide.data to be of type `SlideData`,
         * but in our case these are {@link ItemData} instances which the type
         * doesn't reflect. So this is a method to consolidate the cast and
         * non-null assertion (the PhotoSwipe dialog shouldn't be visible if
         * there are no slides left).
         */
        const asItemData = (slideData: SlideData | undefined) =>
            slideData! as ItemData;

        const currSlideData = () => asItemData(pswp.currSlide?.data);

        const currentFile = () => delegate.getFiles()[pswp.currIndex]!;

        const currentAnnotatedFile = () => {
            const file = currentFile();
            let annotatedFile = _currentAnnotatedFile;
            if (!annotatedFile || annotatedFile.file.id != file.id) {
                annotatedFile = onAnnotate(file, currSlideData());
                _currentAnnotatedFile = annotatedFile;
            }
            return annotatedFile;
        };

        const currentFileAnnotation = () => currentAnnotatedFile().annotation;

        // Provide data about slides to PhotoSwipe via callbacks
        // https://photoswipe.com/data-sources/#dynamically-generated-data

        pswp.addFilter("numItems", () => delegate.getFiles().length);

        pswp.addFilter("itemData", (_, index) => {
            const files = delegate.getFiles();
            const file = files[index]!;

            const itemData = itemDataForFile(file, () =>
                pswp.refreshSlideContent(index),
            );

            if (itemData.fileType === FileType.video) {
                const { videoURL, videoPlaylistURL } = itemData;
                if (videoPlaylistURL) {
                    const mcID = `ente-mc-${file.id}`;
                    return {
                        ...itemData,
                        html: hlsVideoHTML(videoPlaylistURL, mcID),
                        mediaControllerID: mcID,
                    };
                } else if (videoURL) {
                    return {
                        ...itemData,
                        html: videoHTML(videoURL, !!disableDownload),
                    };
                }
            }

            return itemData;
        });

        pswp.addFilter("isContentLoading", (isLoading, content) => {
            return asItemData(content.data).isContentLoading ?? isLoading;
        });

        pswp.addFilter("isContentZoomable", (isZoomable, content) => {
            return asItemData(content.data).isContentZoomable ?? isZoomable;
        });

        /**
         * Last state of the live photo playback toggle.
         */
        let livePhotoPlay = true;

        /**
         * Last state of the live photo muted toggle.
         */
        let livePhotoMute = true;

        /**
         * The live photo playback toggle DOM button element.
         */
        let livePhotoPlayButtonElement: HTMLElement | undefined;

        /**
         * The live photo muted toggle DOM button element.
         */
        let livePhotoMuteButtonElement: HTMLElement | undefined;

        /**
         * Update the state of the given {@link videoElement} and the
         * {@link livePhotoPlayButtonElement} to reflect {@link livePhotoPlay}.
         */
        const livePhotoUpdatePlay = (video: HTMLVideoElement) => {
            const button = livePhotoPlayButtonElement;
            if (button) showIf(button, true);

            if (livePhotoPlay) {
                button?.classList.remove("pswp-ente-off");
                void abortablePlayVideo(video);
                video.style.display = "initial";
            } else {
                button?.classList.add("pswp-ente-off");
                video.pause();
                video.style.display = "none";
            }
        };

        /**
         * A wrapper over video.play that prevents Chrome from spamming the
         * console with errors about interrupted plays when scrolling through
         * files fast by keeping arrow keys pressed.
         */
        const abortablePlayVideo = async (videoElement: HTMLVideoElement) => {
            try {
                await videoElement.play();
            } catch (e) {
                if (
                    e instanceof Error &&
                    e.name == "AbortError" &&
                    e.message.startsWith(
                        "The play() request was interrupted by a call to pause().",
                    )
                ) {
                    // Ignore.
                } else {
                    throw e;
                }
            }
        };

        /**
         * Update the state of the given {@link videoElement} and the
         * {@link livePhotoMuteButtonElement} to reflect {@link livePhotoMute}.
         */
        const livePhotoUpdateMute = (video: HTMLVideoElement) => {
            const button = livePhotoMuteButtonElement;
            if (button) showIf(button, true);

            if (livePhotoMute) {
                button?.classList.add("pswp-ente-off");
                video.muted = true;
            } else {
                button?.classList.remove("pswp-ente-off");
                video.muted = false;
            }
        };

        /**
         * Toggle the playback, if possible, of a live photo that's being shown
         * on the current slide.
         */
        const livePhotoTogglePlayIfPossible = () => {
            const buttonElement = livePhotoPlayButtonElement;
            const video = livePhotoVideoOnSlide(pswp.currSlide);
            if (!buttonElement || !video) return;

            livePhotoPlay = !livePhotoPlay;
            livePhotoUpdatePlay(video);
        };

        /**
         * Toggle the muted status, if possible, of a live photo that's being shown
         * on the current slide.
         */
        const livePhotoToggleMuteIfPossible = () => {
            const buttonElement = livePhotoMuteButtonElement;
            const video = livePhotoVideoOnSlide(pswp.currSlide);
            if (!buttonElement || !video) return;

            livePhotoMute = !livePhotoMute;
            livePhotoUpdateMute(video);
        };

        /**
         * The DOM element housing the media-control-bar and friends.
         */
        let mediaControlsContainerElement: HTMLElement | undefined;

        /**
         * If a {@link mediaControllerID} is provided, then make the
         * media controls visible and link the media-control-bar to the given
         * controller. Otherwise hide the media controls.
         */
        const updateMediaControls = (mediaControllerID: string | undefined) => {
            const controlBars =
                mediaControlsContainerElement?.querySelectorAll(
                    "media-control-bar",
                ) ?? [];
            for (const bar of controlBars) {
                if (mediaControllerID) {
                    bar.setAttribute("mediacontroller", mediaControllerID);
                } else {
                    bar.removeAttribute("mediacontroller");
                }
            }
        };

        pswp.on("contentAppend", (e) => {
            const { fileID, fileType, videoURL, mediaControllerID } =
                asItemData(e.content.data);

            // For the initial slide, "contentAppend" will get called after
            // "change", so we need to wire up the controls (or hide them) for
            // the initial slide here also (in addition to in "change").
            if (currSlideData().fileID == fileID) {
                // For reasons possibily related to the 1 tick waits in the
                // hls-video implementation (`await Promise.resolve()`), the
                // association between media-controller and media-control-bar
                // doesn't get established on the first slide if we reopen the
                // file viewer.
                //
                // See also: https://github.com/muxinc/media-chrome/issues/940
                //
                // As a workaround, defer the association to the next tick.
                //
                setTimeout(() => updateMediaControls(mediaControllerID), 0);
            }

            // Rest of this function deals with live photos.
            if (fileType != FileType.livePhoto) return;
            if (!videoURL) return;

            // This slide is displaying a live photo. Append a video element to
            // show its video part.

            const img = e.content.element!;
            const video = createElementFromHTMLString(
                livePhotoVideoHTML(videoURL),
            ) as HTMLVideoElement;
            const container = e.content.slide!.container;
            container.style = "position: relative";
            container.appendChild(video);
            // Set z-index to 1 to keep it on top, and set pointer-events to
            // none to pass the clicks through.
            video.style =
                "position: absolute; top: 0; left: 0; z-index: 1; pointer-events: none;";

            // Size it to the underlying image.
            video.style.width = img.style.width;
            video.style.height = img.style.height;

            // "contentAppend" can get called both before, or after, "change",
            // and we need to handle both potential sequences for the initial
            // display of the video. Here we handle the case where "change" has
            // already been called, but now "contentAppend" is happening.

            if (currSlideData().fileID == fileID) {
                livePhotoUpdatePlay(video);
                livePhotoUpdateMute(video);
            }
        });

        /**
         * Helper function to extract the video element from a slide that is
         * showing a live photo.
         */
        const livePhotoVideoOnSlide = (slide: typeof pswp.currSlide) =>
            asItemData(slide?.data).fileType == FileType.livePhoto
                ? slide?.container.getElementsByTagName("video")[0]
                : undefined;

        pswp.on("imageSizeChange", ({ content, width, height }) => {
            const video = livePhotoVideoOnSlide(content.slide);
            if (!video) {
                // We might have been called before "contentAppend".
                return;
            }

            // This slide is displaying a live photo. Resize the size of the
            // video element to match that of the image.

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
            const fileID = asItemData(e.content.data).fileID;
            if (fileID) forgetFailedItemDataForFileID(fileID);

            // Pause the video element, if any, when we move away from the
            // slide.
            const video =
                e.content.slide?.container.getElementsByTagName("video")[0];
            video?.pause();
        });

        pswp.on("loadComplete", (e) =>
            updateFileInfoExifIfNeeded(asItemData(e.content.data)),
        );

        pswp.on(
            "change",
            () => void updateFileInfoExifIfNeeded(currSlideData()),
        );

        pswp.on("contentDestroy", (e) =>
            forgetExifForItemData(asItemData(e.content.data)),
        );

        /**
         * If the current slide is showing a video, then the DOM video element
         * showing that video.
         */
        let videoVideoEl: HTMLVideoElement | undefined;

        /**
         * Callback attached to video playback events when showing video files.
         *
         * These are needed to hide the caption when a video is playing on a
         * file of type video.
         */
        let onVideoPlayback: (() => void) | undefined;

        /**
         * The DOM element showing the caption for the current file.
         */
        let captionElement: HTMLElement | undefined;

        pswp.on("change", () => {
            const itemData = currSlideData();

            // For each slide ("item holder"), mirror the "aria-hidden" state
            // into the "inert" property so that keyboard navigation via tabs
            // does not cycle through to the hidden slides (e.g. if the hidden
            // slide is a video element with browser provided controls).

            pswp.mainScroll.itemHolders.forEach(({ el }) => {
                if (el.getAttribute("aria-hidden") == "true") {
                    el.setAttribute("inert", "");
                } else {
                    el.removeAttribute("inert");
                }
            });

            // Clear existing listeners, if any.
            if (videoVideoEl && onVideoPlayback) {
                videoVideoEl.removeEventListener("play", onVideoPlayback);
                videoVideoEl.removeEventListener("pause", onVideoPlayback);
                videoVideoEl.removeEventListener("ended", onVideoPlayback);
                videoVideoEl = undefined;
                onVideoPlayback = undefined;
            }

            // Reset.
            showIf(captionElement!, true);

            // Attach new listeners, if needed.
            if (itemData.fileType == FileType.video) {
                // We use content.element instead of container here because
                // pswp.currSlide.container.getElementsByTagName("video") does
                // not work for the first slide when we reach here during the
                // initial "change".
                //
                // It works subsequently, which is why, e.g., we can use it to
                // pause the video in "contentDeactivate".
                const contentElement = pswp.currSlide?.content.element;
                videoVideoEl = contentElement?.getElementsByTagName("video")[0];

                if (videoVideoEl) {
                    onVideoPlayback = () =>
                        showIf(captionElement!, !!videoVideoEl?.paused);

                    videoVideoEl.addEventListener("play", onVideoPlayback);
                    videoVideoEl.addEventListener("pause", onVideoPlayback);
                    videoVideoEl.addEventListener("ended", onVideoPlayback);
                }
            }
        });

        /**
         * Toggle the playback, if possible, of the video that's being shown on
         * the current slide.
         */
        const videoTogglePlayIfPossible = () => {
            const video = videoVideoEl;
            if (!video) return;

            if (video.paused || video.ended) {
                void video.play();
            } else {
                video.pause();
            }
        };

        /**
         * Toggle the muted status, if possible, of the video that's being shown on
         * the current slide.
         */
        const videoToggleMuteIfPossible = () => {
            const video = videoVideoEl;
            if (!video) return;

            video.muted = !video.muted;
        };

        // The PhotoSwipe dialog has being closed and the animations have
        // completed.
        pswp.on("destroy", () => {
            fileViewerDidClose();
            // Let our parent know that we have been closed.
            onClose();
        });

        const handleViewInfo = () => onViewInfo(currentAnnotatedFile());

        let favoriteButtonElement: HTMLButtonElement | undefined;

        const toggleFavorite = () =>
            delegate.toggleFavorite(currentAnnotatedFile());

        const updateFavoriteButtonIfNeeded = () => {
            const favoriteIconFill = document.getElementById(
                "pswp__icn-favorite-fill",
            );
            if (!favoriteIconFill) {
                // Early return if we're not currently being shown, to implement
                // the "IfNeeded" semantics.
                return;
            }

            const button = favoriteButtonElement!;

            const af = currentAnnotatedFile();
            const showFavorite = af.annotation.showFavorite;
            showIf(button, showFavorite);

            if (!showFavorite) {
                // Nothing more to do.
                return;
            }

            // Update the button interactivity based on pending requests.
            button.disabled = delegate.isFavoritePending(af);

            // Update the fill visibility based on the favorite status.
            showIf(favoriteIconFill, !!delegate.isFavorite(af));
        };

        this.refreshCurrentSlideFavoriteButtonIfNeeded =
            updateFavoriteButtonIfNeeded;

        const handleToggleFavorite = () => void toggleFavorite();

        const handleToggleFavoriteIfEnabled = () => {
            if (
                haveUser &&
                !delegate.isFavoritePending(currentAnnotatedFile())
            ) {
                handleToggleFavorite();
            }
        };

        const handleDownload = () => onDownload(currentAnnotatedFile());

        const handleDownloadIfEnabled = () => {
            if (currentFileAnnotation().showDownload) handleDownload();
        };

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
        // - zoom: 6 (default is 10)
        // - preloader: 10 (default is 7)
        // - close: 20
        pswp.on("uiRegister", () => {
            const ui = pswp.ui!;

            // Move the zoom button to the left so that it is in the same place
            // as the other items like preloader or the error indicator that
            // come and go as files get loaded. Also modify the default orders
            // so that there is more space for the error / live indicators.
            //
            // We cannot use the PhotoSwipe "uiElement" filter to modify the
            // order since that only allows us to edit the DOM element, not the
            // underlying UI element data.
            ui.uiElementsData.find((e) => e.name == "zoom")!.order = 6;
            ui.uiElementsData.find((e) => e.name == "preloader")!.order = 10;

            // Register our custom elements...

            ui.registerElement({
                name: "live",
                title: t("live"),
                order: 7,
                isButton: true,
                html: createPSRegisterElementIconHTML("live"),
                onInit: (buttonElement) => {
                    livePhotoPlayButtonElement = buttonElement;
                    pswp.on("change", () => {
                        const video = livePhotoVideoOnSlide(pswp.currSlide);
                        if (video) {
                            livePhotoUpdatePlay(video);
                        } else {
                            // Not a live photo, or its video hasn't loaded yet.
                            showIf(buttonElement, false);
                        }
                    });
                },
                onClick: livePhotoTogglePlayIfPossible,
            });

            ui.registerElement({
                name: "vol",
                title: t("audio"),
                order: 8,
                isButton: true,
                html: createPSRegisterElementIconHTML("vol"),
                onInit: (buttonElement) => {
                    livePhotoMuteButtonElement = buttonElement;
                    pswp.on("change", () => {
                        const video = livePhotoVideoOnSlide(pswp.currSlide);
                        if (video) {
                            livePhotoUpdateMute(video);
                        } else {
                            // Not a live photo, or its video hasn't loaded yet.
                            showIf(buttonElement, false);
                        }
                    });
                },
                onClick: livePhotoToggleMuteIfPossible,
            });

            ui.registerElement({
                name: "error",
                order: 9,
                html: createPSRegisterElementIconHTML("error"),
                onInit: (errorElement, pswp) => {
                    pswp.on("change", () => {
                        const { fetchFailed, isContentLoading } =
                            currSlideData();
                        errorElement.classList.toggle(
                            "pswp__error--active",
                            !!fetchFailed && !isContentLoading,
                        );
                    });
                },
            });

            // Only one of these two ("favorite" and "download") will end
            // up being shown, so they can safely share the same order.
            if (haveUser) {
                ui.registerElement({
                    name: "favorite",
                    title: t("favorite"),
                    order: 11,
                    isButton: true,
                    html: createPSRegisterElementIconHTML("favorite"),
                    onInit: (buttonElement) => {
                        favoriteButtonElement =
                            // The cast should be safe (unless there is a
                            // PhotoSwipe bug) since we set isButton to true.
                            buttonElement as HTMLButtonElement;
                        pswp.on("change", updateFavoriteButtonIfNeeded);
                    },
                    onClick: handleToggleFavorite,
                });
            } else {
                // When we don't have a user (i.e. in the context of public
                // albums), the download button is shown (if enabled for that
                // album) instead of the favorite button as the first action.
                ui.registerElement({
                    name: "download",
                    title: t("download"),
                    order: 11,
                    isButton: true,
                    html: createPSRegisterElementIconHTML("download"),
                    onInit: (buttonElement) =>
                        pswp.on("change", () =>
                            showIf(
                                buttonElement,
                                currentFileAnnotation().showDownload == "bar",
                            ),
                        ),
                    onClick: handleDownload,
                });
            }

            ui.registerElement({
                name: "info",
                title: t("info"),
                order: 13,
                isButton: true,
                html: createPSRegisterElementIconHTML("info"),
                onClick: handleViewInfo,
            });

            ui.registerElement({
                name: "more",
                title: t("more"),
                order: 16,
                isButton: true,
                html: createPSRegisterElementIconHTML("more"),
                onInit: (buttonElement) => {
                    buttonElement.setAttribute("id", moreButtonID);
                    buttonElement.setAttribute("aria-haspopup", "true");
                },
                onClick: (_, buttonElement) => {
                    // See also: `resetMoreMenuButtonOnMenuClose`.
                    buttonElement.setAttribute("aria-controls", moreMenuID);
                    buttonElement.setAttribute("aria-expanded", "true");
                    onMore(buttonElement);
                },
            });

            ui.registerElement({
                name: "caption",
                // Arbitrary order towards the end (it doesn't matter anyways
                // since we're absolutely positioned).
                order: 30,
                appendTo: "root",
                tagName: "p",
                onInit: (element, pswp) => {
                    captionElement = element;
                    pswp.on("change", () => {
                        const { fileType, alt } = currSlideData();
                        element.innerText = alt ?? "";
                        element.style.visibility = alt ? "visible" : "hidden";
                        // Add extra offset for video captions so that they do
                        // not overlap with the video controls. The constant is
                        // an ad-hoc value that looked okay-ish across browsers.
                        element.style.bottom =
                            fileType === FileType.video ? "36px" : "0";
                    });
                },
            });

            ui.registerElement({
                name: "media-controls",
                order: 31,
                appendTo: "root",
                html: hlsVideoControlsHTML(),
                onInit: (element, pswp) => {
                    mediaControlsContainerElement = element;
                    pswp.on("change", () => {
                        const { mediaControllerID } = currSlideData();
                        updateMediaControls(mediaControllerID);
                    });
                },
            });
        });

        // Pan action handlers

        const panner = (key: "w" | "a" | "s" | "d") => () => {
            const slide = pswp.currSlide!;
            const d = 80;
            switch (key) {
                case "w":
                    slide.pan.y += d;
                    break;
                case "a":
                    slide.pan.x += d;
                    break;
                case "s":
                    slide.pan.y -= d;
                    break;
                case "d":
                    slide.pan.x -= d;
                    break;
            }
            slide.panTo(slide.pan.x, slide.pan.y);
        };

        // Actions we handle ourselves.

        const handleTogglePlayIfPossible = () => {
            switch (currentAnnotatedFile().itemData.fileType) {
                case FileType.video:
                    videoTogglePlayIfPossible();
                    return;
                case FileType.livePhoto:
                    livePhotoTogglePlayIfPossible();
                    return;
            }
        };

        const handleToggleMuteIfPossible = () => {
            switch (currentAnnotatedFile().itemData.fileType) {
                case FileType.video:
                    videoToggleMuteIfPossible();
                    return;
                case FileType.livePhoto:
                    livePhotoToggleMuteIfPossible();
                    return;
            }
        };

        // Toggle controls infrastructure

        const handleToggleUIControls = () =>
            pswp.element!.classList.toggle("pswp--ui-visible");

        // Return true if the current keyboard focus is on any of the UI
        // controls (e.g. as a result of user tabbing through them).
        const isFocusedOnUIControl = () => {
            const fv = document.querySelector(":focus-visible");
            if (fv && !fv.classList.contains("pswp")) {
                return true;
            }
            return false;
        };

        // Some actions routed via the delegate

        const handleDelete = () => delegate.performKeyAction("delete");

        const handleToggleArchive = () =>
            delegate.performKeyAction("toggle-archive");

        const handleCopy = () => delegate.performKeyAction("copy");

        const handleToggleFullscreen = () =>
            delegate.performKeyAction("toggle-fullscreen");

        const handleHelp = () => delegate.performKeyAction("help");

        pswp.on("keydown", (pswpEvent) => {
            // Ignore keyboard events when we do not have "focus".
            if (delegate.shouldIgnoreKeyboardEvent()) {
                pswpEvent.preventDefault();
                return;
            }

            const e: KeyboardEvent = pswpEvent.originalEvent;

            const key = e.key;
            // Even though we ignore shift, Caps lock might still be on.
            const lkey = e.key.toLowerCase();

            // Keep the keybindings such that they don't use modifiers, because
            // these are more likely to interfere with browser shortcuts.
            //
            // For example, Cmd-D adds a bookmark, which is why we don't use it
            // for download.
            //
            // An exception is Ctrl/Cmd-C, which we intercept to copy the image
            // since that should match the user's expectation.

            let cb: (() => void) | undefined;
            if (e.shiftKey) {
                // Ignore except "?" for help.
                if (key == "?") cb = handleHelp;
            } else if (e.altKey) {
                // Ignore.
            } else if (e.metaKey || e.ctrlKey) {
                // Ignore except Ctrl/Cmd-C for copy
                if (lkey == "c") cb = handleCopy;
            } else {
                switch (key) {
                    case " ":
                        // Space activates controls when they're focused, so
                        // only act on it if no specific control is focused.
                        if (!isFocusedOnUIControl()) {
                            cb = handleTogglePlayIfPossible;
                        }
                        break;
                    case "Backspace":
                    case "Delete":
                        cb = handleDelete;
                        break;
                    // We check for "?"" both with an without shift, since some
                    // keyboards might have it emittable without shift.
                    case "?":
                        cb = handleHelp;
                        break;
                }
                switch (lkey) {
                    case "w":
                    case "a":
                    case "s":
                    case "d":
                        cb = panner(lkey);
                        break;
                    case "h":
                        cb = handleToggleUIControls;
                        break;
                    case "m":
                        cb = handleToggleMuteIfPossible;
                        break;
                    case "l":
                        cb = handleToggleFavoriteIfEnabled;
                        break;
                    case "i":
                        cb = handleViewInfo;
                        break;
                    case "k":
                        cb = handleDownloadIfEnabled;
                        break;
                    case "x":
                        cb = handleToggleArchive;
                        break;
                    case "f":
                        cb = handleToggleFullscreen;
                        break;
                }
            }

            cb?.();
        });

        // Let our data source know that we're about to open.
        fileViewerWillOpen();

        // Initializing PhotoSwipe adds it to the DOM as a dialog-like div with
        // the class "pswp".
        pswp.init();
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
     *
     * @param expectedFileCount The count of files that we expect to show after
     * the refresh. If provided, this is used to (circle) go back to the first
     * slide when the slide which we were at previously is not available anymore
     * (e.g. when deleting the last file in a sequence).
     */
    refreshCurrentSlideContent(expectedFileCount?: number) {
        if (expectedFileCount && this.pswp.currIndex >= expectedFileCount) {
            this.pswp.goTo(0);
        } else {
            this.pswp.refreshSlideContent(this.pswp.currIndex);
        }
    }

    /**
     * Refresh the favorite button (if indeed it is visible at all) on the
     * current slide, asking the delegate for the latest state.
     *
     * We do this piecemeal update instead of a full refresh because a full
     * refresh would cause, e.g., the pan and zoom to be reset.
     */
    refreshCurrentSlideFavoriteButtonIfNeeded: () => void;
}

const videoHTML = (url: string, disableDownload: boolean) => `
<video controls ${disableDownload && "controlsList=nodownload"} oncontextmenu="return false;">
  <source src="${url}" />
  Your browser does not support video playback.
</video>
`;

// Requires the following imports to register the Web components we use:
//
//     import "hls-video-element";
//     import "media-chrome";
//
// TODO(HLS): Update code above that searches for the video element
const hlsVideoHTML = (url: string, mediaControllerID: string) => `
<media-controller id="${mediaControllerID}">
  <hls-video playsinline slot="media" src="${url}"></hls-video>
</media-controller>
`;

/**
 * HTML for controls associated with {@link hlsVideoHTML}.
 *
 * To make these functional, the `media-control-bar` requires the
 * `mediacontroller="${mediaControllerID}"` attribute.
 *
 * Notes:
 *
 * - Examples: https://media-chrome.mux.dev/examples/vanilla/
 *
 * - When PiP is active and the video moves out, the browser displays some
 *   indicator (browser specific) in the in-page video element.
 */
const hlsVideoControlsHTML = () => `
<div>
  <media-control-bar>
    <media-loading-indicator noautohide></media-loading-indicator>
  </media-control-bar>
  <media-control-bar>
    <media-time-range></media-time-range>
  </media-control-bar>
  <media-control-bar>
    <media-play-button></media-play-button>
    <media-mute-button></media-mute-button>
    <media-time-display showduration notoggle></media-time-display>
    <media-text-display></media-text-display>
    <media-pip-button></media-pip-button>
    <media-airplay-button></media-airplay-button>
    <media-fullscreen-button></media-fullscreen-button>
  </media-control-bar>
</div>
`;

// playsinline will play the video inline on mobile browsers (where the default
// is to open a full screen player).
const livePhotoVideoHTML = (videoURL: string) => `
<video loop muted playsinline oncontextmenu="return false;">
  <source src="${videoURL}" />
</video>
`;

const createElementFromHTMLString = (htmlString: string) => {
    const template = document.createElement("template");
    // Excess whitespace causes excess DOM nodes, causing our firstChild to not
    // be what we wanted them to be.
    template.innerHTML = htmlString.trim();
    return template.content.firstChild!;
};

/**
 * Update the ARIA attributes for the button that controls the more menu when
 * the menu is closed.
 */
export const resetMoreMenuButtonOnMenuClose = (buttonElement: HTMLElement) => {
    buttonElement.removeAttribute("aria-controls");
    buttonElement.removeAttribute("aria-expanded");
};
