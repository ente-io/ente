import React, { useContext, useLayoutEffect, useRef, useState } from 'react';
import { EnteFile } from 'types/file';
import styled from 'styled-components';
import PlayCircleOutline from 'components/icons/PlayCircleOutline';
import DownloadManager from 'services/downloadManager';
import useLongPress from 'utils/common/useLongPress';
import { GalleryContext } from 'pages/gallery';
import { GAP_BTW_TILES } from 'constants/gallery';
import {
    defaultPublicCollectionGalleryContext,
    PublicCollectionGalleryContext,
} from 'utils/publicCollectionGallery';
import PublicCollectionDownloadManager from 'services/publicCollectionDownloadManager';
import LivePhotoIndicatorOverlay from 'components/icons/LivePhotoIndicatorOverlay';
import { isLivePhoto } from 'utils/file';

interface IProps {
    file: EnteFile;
    updateURL: (url: string) => void;
    onClick?: () => void;
    forcedEnable?: boolean;
    selectable?: boolean;
    selected?: boolean;
    onSelect: (checked: boolean) => void;
    onHover?: () => void;
    onRangeSelect?: () => void;
    isRangeSelectActive?: boolean;
    selectOnClick?: boolean;
    isInsSelectRange?: boolean;
}

const Check = styled.input<{ active: boolean }>`
    appearance: none;
    position: absolute;
    z-index: 10;
    left: 0;
    opacity: 0;
    outline: none;
    cursor: pointer;
    @media (pointer: coarse) {
        pointer-events: none;
    }

    &::before {
        content: '';
        width: 16px;
        height: 16px;
        border: 2px solid #fff;
        background-color: #ddd;
        display: inline-block;
        border-radius: 50%;
        vertical-align: bottom;
        margin: 8px 8px;
        text-align: center;
        line-height: 16px;
        transition: background-color 0.3s ease;
        pointer-events: inherit;
        color: #aaa;
    }
    &::after {
        content: '';
        width: 5px;
        height: 10px;
        border-right: 2px solid #333;
        border-bottom: 2px solid #333;
        transform: translate(-18px, 8px);
        transition: transform 0.3s ease;
        position: absolute;
        pointer-events: inherit;
        transform: translate(-18px, 10px) rotate(45deg);
    }

    /** checked */
    &:checked::before {
        content: '';
        background-color: #51cd7c;
        border-color: #51cd7c;
        color: #fff;
    }
    &:checked::after {
        content: '';
        border-right: 2px solid #ddd;
        border-bottom: 2px solid #ddd;
    }
    ${(props) => props.active && 'opacity: 0.5 '};
    &:checked {
        opacity: 1 !important;
    }
`;

export const HoverOverlay = styled.div<{ checked: boolean }>`
    opacity: 0;
    left: 0;
    top: 0;
    outline: none;
    height: 40%;
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    font-weight: 900;
    position: absolute;
    ${(props) =>
        !props.checked &&
        'background:linear-gradient(rgba(0, 0, 0, 0.2), rgba(0, 0, 0, 0))'};
`;

export const InSelectRangeOverLay = styled.div<{ active: boolean }>`
    opacity: ${(props) => (!props.active ? 0 : 1)});
    left: 0;
    top: 0;
    outline: none;
    height: 100%;
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    font-weight: 900;
    position: absolute;
    ${(props) => props.active && 'background:rgba(81, 205, 124, 0.25)'};
`;

const Cont = styled.div<{ disabled: boolean; selected: boolean }>`
    background: #222;
    display: flex;
    width: fit-content;
    margin-bottom: ${GAP_BTW_TILES}px;
    min-width: 100%;
    overflow: hidden;
    position: relative;
    flex: 1;
    cursor: ${(props) => (props.disabled ? 'not-allowed' : 'pointer')};

    & > img {
        object-fit: cover;
        max-width: 100%;
        min-height: 100%;
        flex: 1;
        ${(props) => props.selected && 'border: 5px solid #51cd7c;'}
        pointer-events: none;
    }

    & > svg {
        position: absolute;
        color: white;
        width: 50px;
        height: 50px;
        margin-left: 50%;
        margin-top: 50%;
        top: -25px;
        left: -25px;
        filter: drop-shadow(3px 3px 2px rgba(0, 0, 0, 0.7));
    }

    &:hover ${Check} {
        opacity: 0.5;
    }
    &:hover ${HoverOverlay} {
        opacity: 1;
    }
`;

export default function PreviewCard(props: IProps) {
    const [imgSrc, setImgSrc] = useState<string>();
    const { thumbs } = useContext(GalleryContext);
    const {
        file,
        onClick,
        updateURL,
        forcedEnable,
        selectable,
        selected,
        onSelect,
        selectOnClick,
        onHover,
        onRangeSelect,
        isRangeSelectActive,
        isInsSelectRange,
    } = props;
    const isMounted = useRef(true);
    const publicCollectionGalleryContext =
        useContext(PublicCollectionGalleryContext) ??
        defaultPublicCollectionGalleryContext;
    useLayoutEffect(() => {
        if (file && !file.msrc) {
            const main = async () => {
                try {
                    let url;
                    if (
                        publicCollectionGalleryContext.accessedThroughSharedURL
                    ) {
                        url =
                            await PublicCollectionDownloadManager.getThumbnail(
                                file,
                                publicCollectionGalleryContext.token,
                                publicCollectionGalleryContext.passwordToken
                            );
                    } else {
                        url = await DownloadManager.getThumbnail(file);
                    }
                    if (isMounted.current) {
                        setImgSrc(url);
                        thumbs.set(file.id, url);
                        updateURL(url);
                    }
                } catch (e) {
                    // no-op
                }
            };

            if (thumbs.has(file.id)) {
                const thumbImgSrc = thumbs.get(file.id);
                setImgSrc(thumbImgSrc);
                file.msrc = thumbImgSrc;
            } else {
                main();
            }
        }
        return () => {
            // cool cool cool
            isMounted.current = false;
        };
    }, [file]);

    const handleClick = () => {
        if (selectOnClick) {
            if (isRangeSelectActive) {
                onRangeSelect();
            } else {
                onSelect(!selected);
            }
        } else if (file?.msrc || imgSrc) {
            onClick?.();
        }
    };

    const handleSelect: React.ChangeEventHandler<HTMLInputElement> = (e) => {
        if (isRangeSelectActive) {
            onRangeSelect?.();
        } else {
            onSelect(e.target.checked);
        }
    };

    const longPressCallback = () => {
        onSelect(!selected);
    };
    const handleHover = () => {
        if (isRangeSelectActive) {
            onHover();
        }
    };
    return (
        <Cont
            id={`thumb-${file?.id}`}
            onClick={handleClick}
            onMouseEnter={handleHover}
            disabled={!forcedEnable && !file?.msrc && !imgSrc}
            selected={selected}
            {...(selectable ? useLongPress(longPressCallback, 500) : {})}>
            {selectable && (
                <Check
                    type="checkbox"
                    checked={selected}
                    onChange={handleSelect}
                    active={isRangeSelectActive && isInsSelectRange}
                    onClick={(e) => e.stopPropagation()}
                />
            )}
            {(file?.msrc || imgSrc) && <img src={file?.msrc || imgSrc} />}
            {file?.metadata.fileType === 1 && <PlayCircleOutline />}
            <HoverOverlay checked={selected} />
            <InSelectRangeOverLay
                active={isRangeSelectActive && isInsSelectRange}
            />
            {isLivePhoto(file) && <LivePhotoIndicatorOverlay />}
        </Cont>
    );
}
