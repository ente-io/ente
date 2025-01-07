import { isDesktop } from "@/base/app";
import { assertionFailed } from "@/base/assert";
import { FilledIconButton, type ButtonishProps } from "@/base/components/mui";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { Overlay } from "@/base/components/mui/Container";
import { type ModalVisibilityProps } from "@/base/components/utils/modal";
import { lowercaseExtension } from "@/base/file-name";
import log from "@/base/log";
import { downloadManager } from "@/gallery/services/download";
import { fileLogID, type EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { isHEICExtension, needsJPEGConversion } from "@/media/formats";
import { moveToTrash } from "@/new/photos/services/collection";
import { extractRawExif, parseExif } from "@/new/photos/services/exif";
import { AppContext } from "@/new/photos/types/context";
import { FlexWrapper } from "@ente/shared/components/Container";
import AlbumOutlinedIcon from "@mui/icons-material/AlbumOutlined";
import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import CloseIcon from "@mui/icons-material/Close";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import FavoriteBorderIcon from "@mui/icons-material/FavoriteBorderRounded";
import FavoriteRoundedIcon from "@mui/icons-material/FavoriteRounded";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import FullscreenExitOutlinedIcon from "@mui/icons-material/FullscreenExitOutlined";
import FullscreenOutlinedIcon from "@mui/icons-material/FullscreenOutlined";
import InfoIcon from "@mui/icons-material/InfoOutlined";
import ReplayIcon from "@mui/icons-material/Replay";
import ZoomInOutlinedIcon from "@mui/icons-material/ZoomInOutlined";
import {
    Box,
    Button,
    CircularProgress,
    Paper,
    Snackbar,
    styled,
    Typography,
    type ButtonProps,
    type CircularProgressProps,
} from "@mui/material";
import type { DisplayFile, PhotoFrameProps } from "components/PhotoFrame";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import Photoswipe from "photoswipe";
import PhotoswipeUIDefault from "photoswipe/dist/photoswipe-ui-default";
import React, {
    useContext,
    useEffect,
    useMemo,
    useRef,
    useState,
    useSyncExternalStore,
} from "react";
import {
    addToFavorites,
    removeFromFavorites,
} from "services/collectionService";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";
import {
    copyFileToClipboard,
    downloadSingleFile,
    getFileFromURL,
} from "utils/file";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";
import { FileInfo, type FileInfoExif, type FileInfoProps } from "./FileInfo";
import { ImageEditorOverlay } from "./ImageEditorOverlay";

export type PhotoViewerProps = Pick<
    PhotoFrameProps,
    "favoriteFileIDs" | "markUnsyncedFavoriteUpdate" | "markTempDeleted"
> & {
    /**
     * The PhotoViewer is shown when this is `true`.
     */
    isOpen: boolean;
    /**
     * The list of files that we are showing in the current context.
     *
     * These are the (ordered) siblings of the file that is currently being
     * shown in the PhotoViewer. The meaning of siblings depends on the context:
     * for example, when viewing a collection, this will be set to the list of
     * files present in the collection.
     */
    items: any[];
    currentIndex?: number;
    /**
     * Callback fired when the PhotoViewer requests to be closed.
     */
    onClose?: (needUpdate: boolean) => void;
    gettingData: (instance: any, index: number, item: EnteFile) => void;
    forceConvertItem: (instance: any, index: number, item: EnteFile) => void;
    isTrashCollection: boolean;
    isInHiddenSection: boolean;
    enableDownload: boolean;
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator;
    fileToCollectionsMap: Map<number, number[]>;
    collectionNameMap: Map<number, string>;
    onSelectPerson?: FileInfoProps["onSelectPerson"];
};

/**
 * TODO: Rename me to FileViewer.
 *
 * A wrapper over PhotoSwipe.
 *
 * This is the component we use for showing files (images, videos, and their
 * combinations like live photos). It shows each item, taking up the full
 * dimensions of the window, and also surfaces some file specific commands (e.g.
 * favorite a file, delete it) and controls (e.g. zooming). Further, it also
 * allows the user to cycle through the sibling files in the current context
 * (e.g. if opened from within the list of files for an album, then the arrows
 * will cycle through the files within that album).
 *
 * The underlying library that we use is called PhotoSwipe.
 */
export const PhotoViewer: React.FC<PhotoViewerProps> = ({
    isOpen,
    items,
    currentIndex,
    onClose,
    gettingData,
    forceConvertItem,
    favoriteFileIDs,
    markUnsyncedFavoriteUpdate,
    markTempDeleted,
    isTrashCollection,
    isInHiddenSection,
    enableDownload,
    setFilesDownloadProgressAttributesCreator,
    fileToCollectionsMap,
    collectionNameMap,
    onSelectPerson,
}) => {
    const galleryContext = useContext(GalleryContext);
    const { showLoadingBar, hideLoadingBar, showMiniDialog } =
        useContext(AppContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext,
    );

    const pswpElement = useRef<HTMLDivElement | undefined>(undefined);
    const [photoSwipe, setPhotoSwipe] =
        useState<Photoswipe<Photoswipe.Options>>();
    const [showInfo, setShowInfo] = useState(false);
    const [exif, setExif] = useState<
        | {
              key: string;
              value: FileInfoExif | undefined;
          }
        | undefined
    >();
    const exifCopy = useRef(null);
    const [livePhotoBtnOptions, setLivePhotoBtnOptions] = useState(
        defaultLivePhotoDefaultOptions,
    );
    const [isOwnFile, setIsOwnFile] = useState(false);
    const [showConvertButton, setShowConvertButton] = useState(false);
    const [isSourceLoaded, setIsSourceLoaded] = useState(false);
    const [isInFullScreenMode, setIsInFullScreenMode] = useState(false);

    const needUpdate = useRef(false);
    const exifExtractionInProgress = useRef<string>(null);
    const shouldShowCopyOption = useMemo(
        () => typeof ClipboardItem != "undefined",
        [],
    );

    const [showImageEditorOverlay, setShowImageEditorOverlay] = useState(false);

    const [
        conversionFailedNotificationOpen,
        setConversionFailedNotificationOpen,
    ] = useState(false);

    const [showEditButton, setShowEditButton] = useState(false);

    const [showZoomButton, setShowZoomButton] = useState(false);

    const fileDownloadProgress = useSyncExternalStore(
        (onChange) => downloadManager.fileDownloadProgressSubscribe(onChange),
        () => downloadManager.fileDownloadProgressSnapshot(),
    );

    useEffect(() => {
        if (!pswpElement.current) return;
        if (isOpen) {
            openPhotoSwipe();
        }
        if (!isOpen) {
            closePhotoSwipe();
        }
        return () => {
            closePhotoSwipe();
        };
    }, [isOpen]);

    useEffect(() => {
        if (!photoSwipe) return;
        function handleCopyEvent() {
            if (!isOpen || showInfo) {
                return;
            }
            copyToClipboardHelper(photoSwipe.currItem as EnteFile);
        }

        function handleKeyUp(event: KeyboardEvent) {
            if (!isOpen || showInfo) {
                return;
            }

            log.debug(() => "Event: " + event.key);

            switch (event.key) {
                case "i":
                case "I":
                    // Enhancement: This should be calling handleOpenInfo, but
                    // that handling the case where a keybinding triggers an
                    // exit from fullscreen and opening the info drawer is not
                    // currently working (the info drawer opens, but the exit
                    // from fullscreen doesn't happen).
                    //
                    // So for now, let the keybinding only work when not in
                    // fullscreen instead of doing a mish-mash.
                    setShowInfo(true);
                    break;
                case "Backspace":
                case "Delete":
                    confirmTrashFile(photoSwipe?.currItem as EnteFile);
                    break;
                case "d":
                case "D":
                    downloadFileHelper(photoSwipe?.currItem as EnteFile);
                    break;
                case "f":
                case "F":
                    toggleFullscreen(photoSwipe);
                    break;
                case "l":
                case "L":
                    handleFavoriteClick();
                    break;
                case "ArrowLeft":
                    handleArrowClick(event, "left");
                    break;
                case "ArrowRight":
                    handleArrowClick(event, "right");
                    break;
                default:
                    break;
            }
        }

        window.addEventListener("keyup", handleKeyUp);
        if (shouldShowCopyOption) {
            window.addEventListener("copy", handleCopyEvent);
        }
        return () => {
            window.removeEventListener("keyup", handleKeyUp);
            if (shouldShowCopyOption) {
                window.removeEventListener("copy", handleCopyEvent);
            }
        };
    }, [isOpen, photoSwipe, showInfo, favoriteFileIDs]);

    useEffect(() => {
        if (photoSwipe) {
            photoSwipe.options.escKey = !showInfo;
        }
    }, [showInfo]);

    useEffect(() => {
        if (!isOpen) return;
        const item = items[photoSwipe?.getCurrentIndex()];
        if (!item) return;
        if (item.metadata.fileType === FileType.livePhoto) {
            const getVideoAndImage = () => {
                const video = document.getElementById(
                    `live-photo-video-${item.id}`,
                );
                const image = document.getElementById(
                    `live-photo-image-${item.id}`,
                );
                return { video, image };
            };

            const { video, image } = getVideoAndImage();

            if (video && image) {
                setLivePhotoBtnOptions({
                    click: async () => {
                        await playVideo(video, image);
                    },
                    hide: async () => {
                        await pauseVideo(video, image);
                    },
                    show: async () => {
                        await playVideo(video, image);
                    },
                    visible: true,
                    loading: false,
                });
            } else {
                setLivePhotoBtnOptions({
                    ...defaultLivePhotoDefaultOptions,
                    visible: true,
                    loading: true,
                });
            }
        }

        const downloadLivePhotoBtn = document.getElementById(
            `download-btn-${item.id}`,
        ) as HTMLButtonElement;
        const downloadFile = () => {
            downloadFileHelper(photoSwipe.currItem as unknown as EnteFile);
        };

        if (downloadLivePhotoBtn) {
            downloadLivePhotoBtn.addEventListener("click", downloadFile);
        }

        return () => {
            if (downloadLivePhotoBtn) {
                downloadLivePhotoBtn.removeEventListener("click", downloadFile);
            }
            setLivePhotoBtnOptions(defaultLivePhotoDefaultOptions);
        };
    }, [photoSwipe?.currItem, isOpen, isSourceLoaded]);

    useEffect(() => {
        exifCopy.current = exif;
    }, [exif]);

    function updateIsOwnFile(file: EnteFile) {
        const isOwnFile =
            !publicCollectionGalleryContext.credentials &&
            galleryContext.user?.id === file.ownerID;
        setIsOwnFile(isOwnFile);
    }

    function updateExif(file: DisplayFile) {
        if (file.metadata.fileType === FileType.video) {
            setExif({
                key: file.src,
                value: { tags: undefined, parsed: undefined },
            });
            return;
        }
        if (!file || !file.isSourceLoaded || file.conversionFailed) {
            return;
        }

        const key = file.associatedImageURL;
        if (exifCopy?.current?.key === key) return;

        setExif({ key, value: undefined });
        checkExifAvailable(file);
    }

    function updateShowConvertBtn(file: DisplayFile) {
        setShowConvertButton(!!file.canForceConvert);
    }

    function updateConversionFailedNotification(file: DisplayFile) {
        setConversionFailedNotificationOpen(file.conversionFailed);
    }

    function updateIsSourceLoaded(file: DisplayFile) {
        setIsSourceLoaded(file.isSourceLoaded);
    }

    function updateShowEditButton(file: EnteFile) {
        const extension = lowercaseExtension(file.metadata.title);
        // Assume it is supported.
        let isSupported = true;
        if (needsJPEGConversion(extension)) {
            // See if the file is on the whitelist of extensions that we know
            // will not be directly renderable.
            if (!isDesktop) {
                // On the web, we only support HEIC conversion.
                isSupported = isHEICExtension(extension);
            }
        }
        setShowEditButton(
            file.metadata.fileType === FileType.image && isSupported,
        );
    }

    function updateShowZoomButton(file: EnteFile) {
        setShowZoomButton(file.metadata.fileType === FileType.image);
    }

    const openPhotoSwipe = () => {
        const options = {
            history: false,
            maxSpreadZoom: 5,
            index: currentIndex,
            showHideOpacity: true,
            arrowKeys: false,
            getDoubleTapZoom(isMouseClick, item) {
                if (isMouseClick) {
                    return 2.5;
                }
                // zoom to original if initial zoom is less than 0.7x,
                // otherwise to 1.5x, to make sure that double-tap gesture always zooms image
                return item.initialZoomLevel < 0.7 ? 1 : 1.5;
            },
            getThumbBoundsFn: (index) => {
                try {
                    const file = items[index];
                    const ele = document.getElementById(`thumb-${file.id}`);
                    if (ele) {
                        const rect = ele.getBoundingClientRect();
                        const pageYScroll =
                            // eslint-disable-next-line @typescript-eslint/no-deprecated
                            window.pageYOffset ||
                            document.documentElement.scrollTop;
                        return {
                            x: rect.left,
                            y: rect.top + pageYScroll,
                            w: rect.width,
                        };
                    }
                    return null;
                } catch {
                    return null;
                }
            },
        };
        const photoSwipe = new Photoswipe(
            pswpElement.current,
            PhotoswipeUIDefault,
            items,
            options,
        );

        photoSwipe.listen("destroy", handleClose);
        photoSwipe.listen("gettingData", (index, item) =>
            gettingData(photoSwipe, index, item as EnteFile),
        );
        photoSwipe.listen("beforeChange", () => {
            if (!photoSwipe?.currItem) return;
            const currItem = photoSwipe.currItem as EnteFile;
            const videoTags = document.getElementsByTagName("video");
            for (const videoTag of videoTags) {
                videoTag.pause();
            }
            updateIsOwnFile(currItem);
            updateConversionFailedNotification(currItem);
            updateExif(currItem);
            updateShowConvertBtn(currItem);
            updateIsSourceLoaded(currItem);
            updateShowEditButton(currItem);
            updateShowZoomButton(currItem);
        });
        photoSwipe.listen("resize", () => {
            if (!photoSwipe?.currItem) return;
            const currItem = photoSwipe.currItem as EnteFile;
            updateExif(currItem);
            updateConversionFailedNotification(currItem);
            updateShowConvertBtn(currItem);
            updateIsSourceLoaded(currItem);
        });
        photoSwipe.init();
        needUpdate.current = false;
        setIsInFullScreenMode(false);
        setPhotoSwipe(photoSwipe);
    };

    const closePhotoSwipe = () => {
        if (photoSwipe) photoSwipe.close();
    };

    const handleClose = () => {
        if (typeof onClose === "function") {
            onClose(needUpdate.current);
        }
        const videoTags = document.getElementsByTagName("video");
        for (const videoTag of videoTags) {
            videoTag.pause();
        }
        handleCloseInfo();
    };

    const handleFavoriteClick = () => {
        const file = photoSwipe?.currItem as EnteFile;
        if (!file || isTrashCollection || !isOwnFile || isInHiddenSection) {
            assertionFailed();
            return;
        }

        // Whe get here when we're showing the favorites scaffolding, and so
        // we can assert the presence of the favoriteFileIDs.
        const isFavorite = favoriteFileIDs!.has(file.id);

        if (!isFavorite) {
            markUnsyncedFavoriteUpdate(file.id, true);
            void addToFavorites(file).catch((e: unknown) => {
                log.error("Failed to add favorite", e);
                markUnsyncedFavoriteUpdate(file.id, undefined);
            });
        } else {
            markUnsyncedFavoriteUpdate(file.id, false);
            void removeFromFavorites(file).catch((e: unknown) => {
                log.error("Failed to remove favorite", e);
                markUnsyncedFavoriteUpdate(file.id, undefined);
            });
        }

        needUpdate.current = true;
    };

    const trashFile = async (file: DisplayFile) => {
        try {
            showLoadingBar();
            try {
                await moveToTrash([file]);
            } finally {
                hideLoadingBar();
            }
            markTempDeleted?.([file]);
            updateItems(items.filter((item) => item.id !== file.id));
            needUpdate.current = true;
        } catch (e) {
            log.error("trashFile failed", e);
        }
    };

    const confirmTrashFile = (file: EnteFile) => {
        if (!file || !isOwnFile || isTrashCollection) {
            return;
        }
        showMiniDialog({
            title: t("trash_file_title"),
            message: t("trash_file_message"),
            continue: {
                text: t("move_to_trash"),
                color: "critical",
                action: () => trashFile(file),
                autoFocus: true,
            },
        });
    };

    const handleArrowClick = (
        e: KeyboardEvent,
        direction: "left" | "right",
    ) => {
        // ignore arrow clicks if the user is typing in a text field
        if (
            e.target instanceof HTMLInputElement ||
            e.target instanceof HTMLTextAreaElement
        ) {
            return;
        }
        if (direction === "left") {
            photoSwipe.prev();
        } else {
            photoSwipe.next();
        }
    };

    const updateItems = (items: DisplayFile[]) => {
        try {
            if (photoSwipe) {
                if (items.length === 0) {
                    photoSwipe.close();
                }
                photoSwipe.items.length = 0;
                items.forEach((item) => {
                    photoSwipe.items.push(item);
                });

                photoSwipe.invalidateCurrItems();
                if (isOpen) {
                    photoSwipe.updateSize(true);
                    if (
                        photoSwipe.getCurrentIndex() >= photoSwipe.items.length
                    ) {
                        photoSwipe.goTo(0);
                    }
                }
            }
        } catch (e) {
            log.error("updateItems failed", e);
        }
    };

    const refreshPhotoswipe = () => {
        try {
            photoSwipe.invalidateCurrItems();
            if (isOpen) {
                photoSwipe.updateSize(true);
            }
        } catch (e) {
            log.error("refreshPhotoswipe failed", e);
        }
    };

    const checkExifAvailable = async (enteFile: DisplayFile) => {
        if (exifExtractionInProgress.current === enteFile.src) return;

        const associatedImageURL = enteFile.associatedImageURL;
        if (!associatedImageURL) {
            assertionFailed();
            return;
        }

        try {
            exifExtractionInProgress.current = enteFile.src;
            const file = await getFileFromURL(
                associatedImageURL,
                enteFile.metadata.title,
            );
            const tags = await extractRawExif(file);
            const parsed = parseExif(tags);
            if (exifExtractionInProgress.current === enteFile.src) {
                setExif({ key: enteFile.src, value: { tags, parsed } });
            }
        } catch (e) {
            log.error(`Failed to extract Exif from ${fileLogID(enteFile)}`, e);
            setExif({
                key: enteFile.src,
                value: { tags: undefined, parsed: undefined },
            });
        } finally {
            exifExtractionInProgress.current = null;
        }
    };

    const handleCloseInfo = () => {
        setShowInfo(false);
    };

    const handleOpenInfo = (photoSwipe: any) => {
        // Get out of full screen mode if needed first to be able to show info
        if (isInFullScreenMode) {
            const fullScreenApi: PhotoswipeFullscreenAPI =
                photoSwipe?.ui?.getFullscreenAPI();
            if (fullScreenApi?.isFullscreen()) {
                fullScreenApi.exit();
                setIsInFullScreenMode(false);
            }
        }

        setShowInfo(true);
    };

    const handleOpenEditor = () => {
        setShowImageEditorOverlay(true);
    };

    const handleCloseEditor = () => {
        setShowImageEditorOverlay(false);
    };

    const downloadFileHelper = async (file: EnteFile) => {
        if (
            file &&
            enableDownload &&
            setFilesDownloadProgressAttributesCreator
        ) {
            try {
                const setSingleFileDownloadProgress =
                    setFilesDownloadProgressAttributesCreator(
                        file.metadata.title,
                    );
                await downloadSingleFile(file, setSingleFileDownloadProgress);
            } catch {
                // do nothing
            }
        }
    };

    const copyToClipboardHelper = async (file: DisplayFile) => {
        if (file && enableDownload && shouldShowCopyOption) {
            showLoadingBar();
            await copyFileToClipboard(file.src);
            hideLoadingBar();
        }
    };

    const toggleFullscreen = (photoSwipe) => {
        const fullScreenApi: PhotoswipeFullscreenAPI =
            photoSwipe?.ui?.getFullscreenAPI();
        if (!fullScreenApi) {
            return;
        }
        if (fullScreenApi.isFullscreen()) {
            fullScreenApi.exit();
            setIsInFullScreenMode(false);
        } else {
            fullScreenApi.enter();
            setIsInFullScreenMode(true);
        }
    };

    const toggleZoomInAndOut = () => {
        if (!photoSwipe) {
            return;
        }
        const initialZoomLevel = photoSwipe.currItem.initialZoomLevel;
        if (photoSwipe.getZoomLevel() !== initialZoomLevel) {
            photoSwipe.zoomTo(
                initialZoomLevel,
                {
                    x: photoSwipe.viewportSize.x / 2,
                    y: photoSwipe.viewportSize.y / 2,
                },
                333,
            );
        } else {
            photoSwipe.zoomTo(
                photoSwipe.options.getDoubleTapZoom(true, photoSwipe.currItem),
                {
                    x: photoSwipe.viewportSize.x / 2,
                    y: photoSwipe.viewportSize.y / 2,
                },
                333,
            );
        }
    };

    const handleForceConvert = () =>
        forceConvertItem(
            photoSwipe,
            photoSwipe.getCurrentIndex(),
            photoSwipe.currItem as EnteFile,
        );

    const scheduleUpdate = () => (needUpdate.current = true);

    const isFav =
        !!photoSwipe?.currItem &&
        !!favoriteFileIDs?.has((photoSwipe.currItem as EnteFile).id);

    return (
        <>
            <div
                className={"pswp"}
                tabIndex={Number("-1")}
                role="dialog"
                aria-hidden="true"
                ref={pswpElement}
            >
                <div className="pswp__bg" />
                <div className="pswp__scroll-wrap">
                    {livePhotoBtnOptions.visible && (
                        <LivePhotoBtnContainer>
                            <Button
                                color="secondary"
                                onClick={livePhotoBtnOptions.click}
                                onMouseEnter={livePhotoBtnOptions.show}
                                onMouseLeave={livePhotoBtnOptions.hide}
                                disabled={livePhotoBtnOptions.loading}
                            >
                                <FlexWrapper gap={"4px"}>
                                    {<AlbumOutlinedIcon />}{" "}
                                    {t("live_photo_indicator")}
                                </FlexWrapper>
                            </Button>
                        </LivePhotoBtnContainer>
                    )}
                    <ConversionFailedNotification
                        open={conversionFailedNotificationOpen}
                        onClose={() =>
                            setConversionFailedNotificationOpen(false)
                        }
                        onClick={() =>
                            downloadFileHelper(photoSwipe.currItem as EnteFile)
                        }
                    />

                    <Box
                        sx={{
                            position: "absolute",
                            top: "10vh",
                            right: "2vh",
                            zIndex: 10,
                        }}
                    >
                        {fileDownloadProgress.has(
                            (photoSwipe?.currItem as EnteFile)?.id,
                        ) ? (
                            <CircularProgressWithLabel
                                value={fileDownloadProgress.get(
                                    (photoSwipe.currItem as EnteFile)?.id,
                                )}
                            />
                        ) : (
                            !isSourceLoaded && <ActivityIndicator />
                        )}
                    </Box>

                    <div className="pswp__container">
                        <div className="pswp__item" />
                        <div className="pswp__item" />
                        <div className="pswp__item" />
                    </div>
                    <div className="pswp__ui pswp__ui--hidden">
                        <div className="pswp__top-bar">
                            <div className="pswp__counter" />

                            <button
                                className="pswp__button pswp__button--custom"
                                title={t("close_key")}
                                onClick={handleClose}
                            >
                                <CloseIcon />
                            </button>

                            {enableDownload && (
                                <button
                                    className="pswp__button pswp__button--custom"
                                    title={t("download_key")}
                                    onClick={() =>
                                        downloadFileHelper(
                                            photoSwipe.currItem as EnteFile,
                                        )
                                    }
                                >
                                    <FileDownloadOutlinedIcon />
                                </button>
                            )}
                            {enableDownload && shouldShowCopyOption && (
                                <button
                                    className="pswp__button pswp__button--custom"
                                    title={t("copy_key")}
                                    onClick={() =>
                                        copyToClipboardHelper(
                                            photoSwipe.currItem as EnteFile,
                                        )
                                    }
                                >
                                    <ContentCopyIcon fontSize="small" />
                                </button>
                            )}
                            {isOwnFile && !isTrashCollection && (
                                <button
                                    className="pswp__button pswp__button--custom"
                                    title={t("delete_key")}
                                    onClick={() => {
                                        confirmTrashFile(
                                            photoSwipe?.currItem as EnteFile,
                                        );
                                    }}
                                >
                                    <DeleteIcon />
                                </button>
                            )}
                            {showZoomButton && (
                                <button
                                    className="pswp__button pswp__button--custom"
                                    onClick={toggleZoomInAndOut}
                                    title={t("zoom_in_out_key")}
                                >
                                    <ZoomInOutlinedIcon />
                                </button>
                            )}
                            <button
                                className="pswp__button pswp__button--custom"
                                onClick={() => {
                                    toggleFullscreen(photoSwipe);
                                }}
                                title={t("toggle_fullscreen_key")}
                            >
                                {!isInFullScreenMode ? (
                                    <FullscreenOutlinedIcon
                                        sx={{ fontSize: 32 }}
                                    />
                                ) : (
                                    <FullscreenExitOutlinedIcon
                                        sx={{ fontSize: 32 }}
                                    />
                                )}
                            </button>

                            <button
                                className="pswp__button pswp__button--custom"
                                title={t("info_key")}
                                onClick={() => handleOpenInfo(photoSwipe)}
                            >
                                <InfoIcon />
                            </button>
                            {isOwnFile &&
                                !isTrashCollection &&
                                !isInHiddenSection && (
                                    <>
                                        {showEditButton && (
                                            <button
                                                className="pswp__button pswp__button--custom"
                                                onClick={handleOpenEditor}
                                            >
                                                <EditIcon />
                                            </button>
                                        )}
                                        <button
                                            title={
                                                isFav
                                                    ? t("unfavorite_key")
                                                    : t("favorite_key")
                                            }
                                            className="pswp__button pswp__button--custom"
                                            onClick={handleFavoriteClick}
                                        >
                                            {isFav ? (
                                                <FavoriteRoundedIcon />
                                            ) : (
                                                <FavoriteBorderIcon />
                                            )}
                                        </button>
                                    </>
                                )}
                            {showConvertButton && (
                                <button
                                    title={t("convert")}
                                    className="pswp__button pswp__button--custom"
                                    onClick={handleForceConvert}
                                >
                                    <ReplayIcon fontSize="small" />
                                </button>
                            )}
                            <div className="pswp__preloader" />
                        </div>
                        <button
                            className="pswp__button pswp__button--arrow--left"
                            title={t("previous_key")}
                        >
                            <ChevronLeftIcon sx={{ pointerEvents: "none" }} />
                        </button>
                        <button
                            className="pswp__button pswp__button--arrow--right"
                            title={t("next_key")}
                        >
                            <ChevronRightIcon sx={{ pointerEvents: "none" }} />
                        </button>
                        <div className="pswp__caption pswp-custom-caption-container">
                            <CaptionContainer />
                        </div>
                    </div>
                </div>
            </div>
            <FileInfo
                showInfo={showInfo}
                handleCloseInfo={handleCloseInfo}
                closePhotoViewer={handleClose}
                file={photoSwipe?.currItem as EnteFile}
                exif={exif?.value}
                shouldDisableEdits={!isOwnFile}
                showCollectionChips={
                    !isTrashCollection && isOwnFile && !isInHiddenSection
                }
                scheduleUpdate={scheduleUpdate}
                refreshPhotoswipe={refreshPhotoswipe}
                fileToCollectionsMap={fileToCollectionsMap}
                collectionNameMap={collectionNameMap}
                onSelectPerson={onSelectPerson}
            />
            <ImageEditorOverlay
                show={showImageEditorOverlay}
                file={photoSwipe?.currItem as EnteFile}
                onClose={handleCloseEditor}
                closePhotoViewer={handleClose}
            />
        </>
    );
};

interface PhotoswipeFullscreenAPI {
    enter: () => void;
    exit: () => void;
    isFullscreen: () => boolean;
}

const defaultLivePhotoDefaultOptions = {
    click: () => {},
    hide: () => {},
    show: () => {},
    loading: false,
    visible: false,
};

const CaptionContainer = styled("div")(({ theme }) => ({
    padding: theme.spacing(2),
    wordBreak: "break-word",
    textAlign: "right",
    maxWidth: "375px",
    fontSize: "14px",
    lineHeight: "17px",
    backgroundColor: theme.colors.backdrop.faint,
    backdropFilter: "blur(96px)",
}));

const CircularProgressWithLabel: React.FC<
    Pick<CircularProgressProps, "value">
> = ({ value }) => (
    <>
        <CircularProgress value={value} variant="determinate" color="accent" />
        <Overlay
            sx={{
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                height: "40px",
            }}
        >
            <Typography
                variant="mini"
                component="div"
                sx={{ color: "text.secondary" }}
            >{`${Math.round(value)}%`}</Typography>
        </Overlay>
    </>
);

type ConversionFailedNotificationProps = ModalVisibilityProps & ButtonishProps;

const ConversionFailedNotification: React.FC<
    ConversionFailedNotificationProps
> = ({ open, onClose, onClick }) => {
    const handleClick = () => {
        onClick();
        onClose();
    };

    const handleClose: ButtonProps["onClick"] = (event) => {
        onClose();
        event.stopPropagation();
    };

    return (
        <Snackbar
            open={open}
            anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
        >
            <Paper sx={{ width: "320px" }}>
                <Button
                    color={"secondary"}
                    onClick={handleClick}
                    sx={{
                        borderRadius: "8px",
                        flex: 1,
                        display: "flex",
                        alignItems: "center",
                        gap: "16px",
                    }}
                >
                    <InfoIcon />
                    <Typography
                        variant="small"
                        sx={{ flex: 1, textAlign: "left" }}
                    >
                        {t("unpreviewable_file_notification")}
                    </Typography>
                    <FilledIconButton onClick={handleClose}>
                        <CloseIcon />
                    </FilledIconButton>
                </Button>
            </Paper>
        </Snackbar>
    );
};

const LivePhotoBtnContainer = styled(Paper)`
    border-radius: 4px;
    position: absolute;
    bottom: 10vh;
    right: 6vh;
    z-index: 10;
`;

export async function playVideo(livePhotoVideo, livePhotoImage) {
    const videoPlaying = !livePhotoVideo.paused;
    if (videoPlaying) return;
    livePhotoVideo.style.opacity = 1;
    livePhotoImage.style.opacity = 0;
    livePhotoVideo.load();
    livePhotoVideo.play().catch(() => {
        pauseVideo(livePhotoVideo, livePhotoImage);
    });
}

export async function pauseVideo(livePhotoVideo, livePhotoImage) {
    const videoPlaying = !livePhotoVideo.paused;
    if (!videoPlaying) return;
    livePhotoVideo.pause();
    livePhotoVideo.style.opacity = 0;
    livePhotoImage.style.opacity = 1;
}
