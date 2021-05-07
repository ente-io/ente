import React, { useEffect, useRef, useState } from 'react';
import Photoswipe from 'photoswipe';
import PhotoswipeUIDefault from 'photoswipe/dist/photoswipe-ui-default';
import classnames from 'classnames';
import events from './events';
import FavButton from 'components/FavButton';
import {
    addToFavorites,
    removeFromFavorites,
} from 'services/collectionService';
import { File } from 'services/fileService';
import constants from 'utils/strings/constants';
import DownloadManger from 'services/downloadManager';

interface Iprops {
    isOpen: boolean;
    items: any[];
    currentIndex?: number;
    onClose?: (needUpdate: boolean) => void;
    gettingData: (instance: any, index: number, item: File) => void;
    id?: string;
    className?: string;
    favItemIds: Set<number>;
    loadingBar: any;
}

function PhotoSwipe(props: Iprops) {
    let pswpElement;
    const [photoSwipe, setPhotoSwipe] = useState<Photoswipe<any>>();

    const { isOpen } = props;
    const [isFav, setIsFav] = useState(false);
    const needUpdate = useRef(false);

    useEffect(() => {
        if (!pswpElement) {
            return;
        }
        if (isOpen) {
            openPhotoSwipe();
        }
    }, [pswpElement]);

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

    function updateFavButton() {
        setIsFav(isInFav(this?.currItem));
    }

    const openPhotoSwipe = () => {
        const { items, currentIndex } = props;
        const options = {
            history: false,
            maxSpreadZoom: 5,
            index: currentIndex,
            showHideOpacity: true,
        };
        let photoSwipe = new Photoswipe(
            pswpElement,
            PhotoswipeUIDefault,
            items,
            options
        );
        events.forEach((event) => {
            const callback = props[event];
            if (callback || event === 'destroy') {
                photoSwipe.listen(event, function (...args) {
                    if (callback) {
                        args.unshift(this);
                        callback(...args);
                    }
                    if (event === 'destroy') {
                        handleClose();
                    }
                });
            }
        });
        photoSwipe.listen('beforeChange', updateFavButton);
        photoSwipe.init();
        needUpdate.current = false;
        setPhotoSwipe(photoSwipe);
    };

    const updateItems = (items = []) => {
        photoSwipe.items = [];
        items.forEach((item) => {
            photoSwipe.items.push(item);
        });
        photoSwipe.invalidateCurrItems();
        photoSwipe.updateSize(true);
    };

    const closePhotoSwipe = () => {
        if (photoSwipe) photoSwipe.close();
    };

    const handleClose = () => {
        const { onClose } = props;
        if (typeof onClose === 'function') {
            onClose(needUpdate.current);
        }
        var videoTags = document.getElementsByTagName('video');
        for (var videoTag of videoTags) {
            videoTag.pause();
        }
    };
    const isInFav = (file) => {
        const { favItemIds } = props;
        if (favItemIds && file) {
            return favItemIds.has(file.id);
        } else return false;
    };

    const onFavClick = async (file) => {
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
    const downloadFile = async (file) => {
        const { loadingBar } = props;
        const a = document.createElement('a');
        a.style.display = 'none';
        loadingBar.current.continuousStart();
        a.href = await DownloadManger.getFile(file);
        loadingBar.current.complete();
        a.download = file.metadata['title'];
        document.body.appendChild(a);
        a.click();
        a.remove();
    };
    const { id } = props;
    let { className } = props;
    className = classnames(['pswp', className]).trim();
    return (
        <div
            id={id}
            className={className}
            tabIndex={Number('-1')}
            role="dialog"
            aria-hidden="true"
            ref={(node) => {
                pswpElement = node;
            }}
        >
            <div className="pswp__bg" />
            <div className="pswp__scroll-wrap">
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
                            title={constants.CLOSE}
                        />

                        <button
                            className="download-btn"
                            title={constants.DOWNLOAD}
                            onClick={() => downloadFile(photoSwipe.currItem)}
                        />

                        <button
                            className="pswp__button pswp__button--fs"
                            title={constants.TOGGLE_FULLSCREEN}
                        />
                        <button
                            className="pswp__button pswp__button--zoom"
                            title={constants.ZOOM_IN_OUT}
                        />
                        <FavButton
                            size={44}
                            isClick={isFav}
                            onClick={() => {
                                onFavClick(photoSwipe?.currItem);
                            }}
                        />
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
                        title={constants.PREVIOUS}
                    />
                    <button
                        className="pswp__button pswp__button--arrow--right"
                        title={constants.NEXT}
                    />
                    <div className="pswp__caption">
                        <div className="pswp__caption__center" />
                    </div>
                </div>
            </div>
        </div>
    );
}

export default PhotoSwipe;
