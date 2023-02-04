import React, { useContext, useEffect, useRef, useState } from 'react';
import Photoswipe from 'photoswipe';
import PhotoswipeUIDefault from 'photoswipe/dist/photoswipe-ui-default';
import classnames from 'classnames';
import {
    addToFavorites,
    removeFromFavorites,
} from 'services/collectionService';
import { EnteFile } from 'types/file';
import constants from 'utils/strings/constants';
import exifr from 'exifr';
import {
    downloadFile,
    copyFileToClipboard,
    getFileExtension,
} from 'utils/file';
import { livePhotoBtnHTML } from 'components/LivePhotoBtn';
import { logError } from 'utils/sentry';

import { FILE_TYPE } from 'constants/file';
import { isClipboardItemPresent } from 'utils/common';
import { playVideo, pauseVideo } from 'utils/photoFrame';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
import { AppContext } from 'pages/_app';
import { FileInfo } from './FileInfo';
import {
    defaultLivePhotoDefaultOptions,
    photoSwipeV4Events,
} from 'constants/photoViewer';
import { LivePhotoBtn } from './styledComponents/LivePhotoBtn';
import DownloadIcon from '@mui/icons-material/Download';
import InfoIcon from '@mui/icons-material/InfoOutlined';
import FavoriteIcon from '@mui/icons-material/FavoriteRounded';
import FavoriteBorderIcon from '@mui/icons-material/FavoriteBorderRounded';
import ChevronRight from '@mui/icons-material/ChevronRight';
import DeleteIcon from '@mui/icons-material/Delete';
import { trashFiles } from 'services/fileService';
import { getTrashFileMessage } from 'utils/ui';
import { styled } from '@mui/material';
import { addLocalLog } from 'utils/logging';
import ContentCopy from '@mui/icons-material/ContentCopy';
import ChevronLeft from '@mui/icons-material/ChevronLeft';

interface PhotoswipeFullscreenAPI {
    enter: () => void;
    exit: () => void;
    isFullscreen: () => boolean;
}

const CaptionContainer = styled('div')(({ theme }) => ({
    padding: theme.spacing(2),
    wordBreak: 'break-word',
    textAlign: 'right',
    maxWidth: '375px',
    fontSize: '14px',
    lineHeight: '17px',
    backgroundColor: theme.palette.backdrop.light,
    backdropFilter: `blur(${theme.palette.blur.base})`,
}));
interface Iprops {
    isOpen: boolean;
    items: any[];
    currentIndex?: number;
    onClose?: (needUpdate: boolean) => void;
    gettingData: (instance: any, index: number, item: EnteFile) => void;
    id?: string;
    className?: string;
    favItemIds: Set<number>;
    deletedFileIds: Set<number>;
    setDeletedFileIds?: (value: Set<number>) => void;
    isIncomingSharedCollection: boolean;
    isTrashCollection: boolean;
    enableDownload: boolean;
    isSourceLoaded: boolean;
    fileToCollectionsMap: Map<number, number[]>;
    collectionNameMap: Map<number, string>;
}

function PhotoViewer(props: Iprops) {
    const pswpElement = useRef<HTMLDivElement>();
    const [photoSwipe, setPhotoSwipe] =
        useState<Photoswipe<Photoswipe.Options>>();

    const { isOpen, items, isSourceLoaded } = props;
    const [isFav, setIsFav] = useState(false);
    const [showInfo, setShowInfo] = useState(false);
    const [exif, setExif] =
        useState<{ key: string; value: Record<string, any> }>();
    const exifCopy = useRef(null);
    const [livePhotoBtnOptions, setLivePhotoBtnOptions] = useState(
        defaultLivePhotoDefaultOptions
    );
    const needUpdate = useRef(false);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext
    );
    const appContext = useContext(AppContext);

    const exifExtractionInProgress = useRef<string>(null);
    const [shouldShowCopyOption] = useState(isClipboardItemPresent());

    useEffect(() => {
        if (!pswpElement) return;
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
            copyToClipboardHelper(photoSwipe.currItem as EnteFile);
        }

        function handleKeyUp(event: KeyboardEvent) {
            if (!isOpen || showInfo) {
                return;
            }

            addLocalLog(() => 'Event: ' + event.key);

            switch (event.key) {
                case 'i':
                case 'I':
                    setShowInfo(true);
                    break;
                case 'Backspace':
                case 'Delete':
                    confirmTrashFile(photoSwipe?.currItem as EnteFile);
                    break;
                case 'd':
                case 'D':
                    downloadFileHelper(photoSwipe?.currItem as EnteFile);
                    break;
                case 'f':
                case 'F':
                    toggleFullscreen(photoSwipe);
                    break;
                case 'l':
                case 'L':
                    onFavClick(photoSwipe?.currItem as EnteFile);
                    break;
                default:
                    break;
            }
        }

        window.addEventListener('keyup', handleKeyUp);
        if (shouldShowCopyOption) {
            window.addEventListener('copy', handleCopyEvent);
        }
        return () => {
            window.removeEventListener('keyup', handleKeyUp);
            if (shouldShowCopyOption) {
                window.removeEventListener('copy', handleCopyEvent);
            }
        };
    }, [isOpen, photoSwipe, showInfo]);

    useEffect(() => {
        if (photoSwipe) {
            photoSwipe.options.arrowKeys = !showInfo;
            photoSwipe.options.escKey = !showInfo;
        }
    }, [showInfo]);

    useEffect(() => {
        if (!isOpen) return;
        const item = items[photoSwipe?.getCurrentIndex()];
        if (item && item.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
            const getVideoAndImage = () => {
                const video = document.getElementById(
                    `live-photo-video-${item.id}`
                );
                const image = document.getElementById(
                    `live-photo-image-${item.id}`
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

            const downloadLivePhotoBtn = document.getElementById(
                `download-btn-${item.id}`
            ) as HTMLButtonElement;
            if (downloadLivePhotoBtn) {
                const downloadLivePhoto = () => {
                    downloadFileHelper(photoSwipe.currItem);
                };

                downloadLivePhotoBtn.addEventListener(
                    'click',
                    downloadLivePhoto
                );
                return () => {
                    downloadLivePhotoBtn.removeEventListener(
                        'click',
                        downloadLivePhoto
                    );
                    setLivePhotoBtnOptions(defaultLivePhotoDefaultOptions);
                };
            }

            return () => {
                setLivePhotoBtnOptions(defaultLivePhotoDefaultOptions);
            };
        }
    }, [photoSwipe?.currItem, isOpen, isSourceLoaded]);

    useEffect(() => {
        exifCopy.current = exif;
    }, [exif]);

    function updateFavButton(file: EnteFile) {
        setIsFav(isInFav(file));
    }

    const openPhotoSwipe = () => {
        const { items, currentIndex } = props;
        const options = {
            history: false,
            maxSpreadZoom: 5,
            index: currentIndex,
            showHideOpacity: true,
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
                            window.pageYOffset ||
                            document.documentElement.scrollTop;
                        return {
                            x: rect.left,
                            y: rect.top + pageYScroll,
                            w: rect.width,
                        };
                    }
                    return null;
                } catch (e) {
                    return null;
                }
            },
        };
        const photoSwipe = new Photoswipe(
            pswpElement.current,
            PhotoswipeUIDefault,
            items,
            options
        );
        photoSwipeV4Events.forEach((event) => {
            const callback = props[event];
            if (callback || event === 'destroy') {
                photoSwipe.listen(event, function (...args) {
                    if (callback) {
                        args.unshift(photoSwipe);
                        callback(...args);
                    }
                    if (event === 'destroy') {
                        handleClose();
                    }
                    if (event === 'close') {
                        handleClose();
                    }
                });
            }
        });
        photoSwipe.listen('beforeChange', () => {
            if (!photoSwipe?.currItem) return;
            const currItem = photoSwipe.currItem as EnteFile;
            updateFavButton(currItem);
            if (currItem.metadata.fileType !== FILE_TYPE.IMAGE) {
                setExif({ key: currItem.src, value: null });
                return;
            }
            if (
                !currItem ||
                !exifCopy?.current?.value === null ||
                exifCopy?.current?.key === currItem.src
            ) {
                return;
            }
            setExif({ key: currItem.src, value: undefined });
            checkExifAvailable(currItem);
        });
        photoSwipe.listen('resize', () => {
            if (!photoSwipe?.currItem) return;
            const currItem = photoSwipe.currItem as EnteFile;
            if (currItem.metadata.fileType !== FILE_TYPE.IMAGE) {
                setExif({ key: currItem.src, value: null });
                return;
            }
            if (
                !currItem ||
                !exifCopy?.current?.value === null ||
                exifCopy?.current?.key === currItem.src
            ) {
                return;
            }
            setExif({ key: currItem.src, value: undefined });
            checkExifAvailable(currItem);
        });
        photoSwipe.init();
        needUpdate.current = false;
        setPhotoSwipe(photoSwipe);
    };

    const closePhotoSwipe = () => {
        if (photoSwipe) photoSwipe.close();
    };

    const handleClose = () => {
        const { onClose } = props;
        if (typeof onClose === 'function') {
            onClose(needUpdate.current);
        }
        const videoTags = document.getElementsByTagName('video');
        for (const videoTag of videoTags) {
            videoTag.pause();
        }
        handleCloseInfo();
    };
    const isInFav = (file: EnteFile) => {
        const { favItemIds } = props;
        if (favItemIds && file) {
            return favItemIds.has(file.id);
        }
        return false;
    };

    const onFavClick = async (file: EnteFile) => {
        if (!file) return;
        const { favItemIds } = props;
        if (!isInFav(file)) {
            favItemIds.add(file.id);
            addToFavorites(file);
            setIsFav(true);
        } else {
            favItemIds.delete(file.id);
            removeFromFavorites(file);
            setIsFav(false);
        }
        needUpdate.current = true;
    };

    const trashFile = async (file: EnteFile) => {
        const { deletedFileIds, setDeletedFileIds, items: oldItems } = props;
        try {
            deletedFileIds.add(file.id);
            await trashFiles([file]);
            setDeletedFileIds(new Set(deletedFileIds));
            updateItems(props.items.filter((item) => item.id !== file.id));
            needUpdate.current = true;
        } catch (e) {
            logError(e, 'trashFile failed');
            deletedFileIds.delete(file.id);
            setDeletedFileIds(new Set(deletedFileIds));
            updateItems(oldItems);
        }
    };

    const confirmTrashFile = (file: EnteFile) => {
        if (
            !file ||
            props.isIncomingSharedCollection ||
            props.isTrashCollection
        ) {
            return;
        }
        appContext.setDialogMessage(getTrashFileMessage(() => trashFile(file)));
    };

    const updateItems = (items: EnteFile[]) => {
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
            logError(e, 'updateItems failed');
        }
    };

    const refreshPhotoswipe = () => {
        try {
            photoSwipe.invalidateCurrItems();
            if (isOpen) {
                photoSwipe.updateSize(true);
            }
        } catch (e) {
            logError(e, 'refreshPhotoswipe failed');
        }
    };

    const checkExifAvailable = async (file: EnteFile) => {
        try {
            if (exifExtractionInProgress.current === file.src) {
                return;
            }
            try {
                if (file.isSourceLoaded) {
                    exifExtractionInProgress.current = file.src;
                    const imageBlob = await (
                        await fetch(file.originalImageURL)
                    ).blob();
                    const exifData = (await exifr.parse(imageBlob)) as Record<
                        string,
                        any
                    >;
                    if (exifExtractionInProgress.current === file.src) {
                        if (exifData) {
                            setExif({ key: file.src, value: exifData });
                        } else {
                            setExif({ key: file.src, value: null });
                        }
                    }
                }
            } finally {
                exifExtractionInProgress.current = null;
            }
        } catch (e) {
            setExif({ key: file.src, value: null });
            const fileExtension = getFileExtension(file.metadata.title);
            logError(e, 'checkExifAvailable failed', {
                extension: fileExtension,
            });
        }
    };

    const handleCloseInfo = () => {
        setShowInfo(false);
    };
    const handleOpenInfo = () => {
        setShowInfo(true);
    };

    const downloadFileHelper = async (file) => {
        if (file && props.enableDownload) {
            appContext.startLoading();
            await downloadFile(
                file,
                publicCollectionGalleryContext.accessedThroughSharedURL,
                publicCollectionGalleryContext.token,
                publicCollectionGalleryContext.passwordToken
            );
            appContext.finishLoading();
        }
    };

    const copyToClipboardHelper = async (file: EnteFile) => {
        if (file && props.enableDownload && shouldShowCopyOption) {
            appContext.startLoading();
            await copyFileToClipboard(file.src);
            appContext.finishLoading();
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
        } else {
            fullScreenApi.enter();
        }
    };
    const scheduleUpdate = () => (needUpdate.current = true);
    const { id } = props;
    let { className } = props;
    className = classnames(['pswp', className]).trim();
    return (
        <>
            <div
                id={id}
                className={className}
                tabIndex={Number('-1')}
                role="dialog"
                aria-hidden="true"
                ref={pswpElement}>
                <div className="pswp__bg" />
                <div className="pswp__scroll-wrap">
                    {livePhotoBtnOptions.visible && (
                        <LivePhotoBtn
                            onClick={livePhotoBtnOptions.click}
                            onMouseEnter={livePhotoBtnOptions.show}
                            onMouseLeave={livePhotoBtnOptions.hide}
                            disabled={livePhotoBtnOptions.loading}>
                            {livePhotoBtnHTML} {constants.LIVE}
                        </LivePhotoBtn>
                    )}
                    <div className="pswp__container">
                        <div className="pswp__item" />
                        <div className="pswp__item" />
                        <div className="pswp__item" />
                    </div>
                    <div className="pswp__ui pswp__ui--hidden">
                        <div className="pswp__top-bar">
                            <div className="pswp__counter" />

                            <button
                                className="pswp__button pswp__button--close"
                                title={constants.CLOSE_OPTION}
                            />

                            {props.enableDownload && (
                                <button
                                    className="pswp__button pswp__button--custom"
                                    title={constants.DOWNLOAD_OPTION}
                                    onClick={() =>
                                        downloadFileHelper(photoSwipe.currItem)
                                    }>
                                    <DownloadIcon fontSize="small" />
                                </button>
                            )}
                            {props.enableDownload && shouldShowCopyOption && (
                                <button
                                    className="pswp__button pswp__button--custom"
                                    title={constants.COPY_OPTION}
                                    onClick={() =>
                                        copyToClipboardHelper(
                                            photoSwipe.currItem as EnteFile
                                        )
                                    }>
                                    <ContentCopy fontSize="small" />
                                </button>
                            )}
                            {!props.isIncomingSharedCollection &&
                                !props.isTrashCollection && (
                                    <button
                                        className="pswp__button pswp__button--custom"
                                        title={constants.DELETE_OPTION}
                                        onClick={() => {
                                            confirmTrashFile(
                                                photoSwipe?.currItem as EnteFile
                                            );
                                        }}>
                                        <DeleteIcon fontSize="small" />
                                    </button>
                                )}
                            <button
                                className="pswp__button pswp__button--zoom"
                                title={constants.ZOOM_IN_OUT}
                            />
                            <button
                                className="pswp__button pswp__button--fs"
                                title={constants.TOGGLE_FULLSCREEN}
                            />

                            {!props.isIncomingSharedCollection && (
                                <button
                                    className="pswp__button pswp__button--custom"
                                    title={constants.INFO_OPTION}
                                    onClick={handleOpenInfo}>
                                    <InfoIcon fontSize="small" />
                                </button>
                            )}
                            {!props.isIncomingSharedCollection &&
                                !props.isTrashCollection && (
                                    <button
                                        title={
                                            isFav
                                                ? constants.UNFAVORITE_OPTION
                                                : constants.FAVORITE_OPTION
                                        }
                                        className="pswp__button pswp__button--custom"
                                        onClick={() => {
                                            onFavClick(
                                                photoSwipe?.currItem as EnteFile
                                            );
                                        }}>
                                        {isFav ? (
                                            <FavoriteIcon fontSize="small" />
                                        ) : (
                                            <FavoriteBorderIcon fontSize="small" />
                                        )}
                                    </button>
                                )}

                            <div className="pswp__preloader">
                                <div className="pswp__preloader__icn">
                                    <div className="pswp__preloader__cut">
                                        <div className="pswp__preloader__donut" />
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="pswp__share-modal pswp__share-modal--hidden pswp__single-tap">
                            <div className="pswp__share-tooltip" />
                        </div>
                        <button
                            className="pswp__button pswp__button--arrow--left"
                            title={constants.PREVIOUS}>
                            <ChevronLeft sx={{ pointerEvents: 'none' }} />
                        </button>
                        <button
                            className="pswp__button pswp__button--arrow--right"
                            title={constants.NEXT}>
                            <ChevronRight sx={{ pointerEvents: 'none' }} />
                        </button>
                        <div className="pswp__caption pswp-custom-caption-container">
                            <CaptionContainer />
                        </div>
                    </div>
                </div>
            </div>
            <FileInfo
                isTrashCollection={props.isTrashCollection}
                shouldDisableEdits={props.isIncomingSharedCollection}
                showInfo={showInfo}
                handleCloseInfo={handleCloseInfo}
                file={photoSwipe?.currItem as EnteFile}
                exif={exif?.value}
                scheduleUpdate={scheduleUpdate}
                refreshPhotoswipe={refreshPhotoswipe}
                fileToCollectionsMap={props.fileToCollectionsMap}
                collectionNameMap={props.collectionNameMap}
            />
        </>
    );
}

export default PhotoViewer;
