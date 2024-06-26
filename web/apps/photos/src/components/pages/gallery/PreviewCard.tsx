import { FILE_TYPE } from "@/media/file-type";
import { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import { Overlay } from "@ente/shared/components/Container";
import { CustomError } from "@ente/shared/error";
import useLongPress from "@ente/shared/hooks/useLongPress";
import AlbumOutlined from "@mui/icons-material/AlbumOutlined";
import PlayCircleOutlineOutlinedIcon from "@mui/icons-material/PlayCircleOutlineOutlined";
import { Tooltip, styled } from "@mui/material";
import {
    LoadingThumbnail,
    StaticThumbnail,
} from "components/PlaceholderThumbnails";
import { TRASH_SECTION } from "constants/collection";
import { GAP_BTW_TILES, IMAGE_CONTAINER_MAX_WIDTH } from "constants/gallery";
import i18n from "i18next";
import { DeduplicateContext } from "pages/deduplicate";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useEffect, useRef, useState } from "react";
import DownloadManager from "services/download";
import { shouldShowAvatar } from "utils/file";
import Avatar from "./Avatar";

interface IProps {
    file: EnteFile;
    updateURL: (id: number, url: string) => void;
    onClick: () => void;
    selectable: boolean;
    selected: boolean;
    onSelect: (checked: boolean) => void;
    onHover: () => void;
    onRangeSelect: () => void;
    isRangeSelectActive: boolean;
    selectOnClick: boolean;
    isInsSelectRange: boolean;
    activeCollectionID: number;
    showPlaceholder: boolean;
}

const Check = styled("input")<{ $active: boolean }>`
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
        content: "";
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
        content: "";
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
        content: "";
        background-color: #51cd7c;
        border-color: #51cd7c;
        color: #fff;
    }
    &:checked::after {
        content: "";
        border-right: 2px solid #ddd;
        border-bottom: 2px solid #ddd;
    }
    ${(props) => props.$active && "opacity: 0.5 "};
    &:checked {
        opacity: 1 !important;
    }
`;

export const HoverOverlay = styled("div")<{ checked: boolean }>`
    opacity: 0;
    left: 0;
    top: 0;
    outline: none;
    height: 40%;
    width: 100%;
    position: absolute;
    ${(props) =>
        !props.checked &&
        "background:linear-gradient(rgba(0, 0, 0, 0.2), rgba(0, 0, 0, 0))"};
`;

export const AvatarOverlay = styled(Overlay)`
    display: flex;
    justify-content: flex-end;
    align-items: flex-start;
    padding-right: 5px;
    padding-top: 5px;
`;

export const InSelectRangeOverLay = styled("div")<{ $active: boolean }>`
    opacity: ${(props) => (!props.$active ? 0 : 1)};
    left: 0;
    top: 0;
    outline: none;
    height: 100%;
    width: 100%;
    position: absolute;
    ${(props) => props.$active && "background:rgba(81, 205, 124, 0.25)"};
`;

export const FileAndCollectionNameOverlay = styled("div")`
    width: 100%;
    bottom: 0;
    left: 0;
    max-height: 40%;
    width: 100%;
    background: linear-gradient(rgba(0, 0, 0, 0), rgba(0, 0, 0, 2));
    & > p {
        max-width: calc(${IMAGE_CONTAINER_MAX_WIDTH}px - 10px);
        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;
        margin: 2px;
        text-align: center;
    }
    padding: 7px;
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    color: #fff;
    position: absolute;
`;

export const SelectedOverlay = styled("div")<{ selected: boolean }>`
    z-index: 5;
    position: absolute;
    left: 0;
    top: 0;
    height: 100%;
    width: 100%;
    ${(props) => props.selected && "border: 5px solid #51cd7c;"}
    border-radius: 4px;
`;

export const FileTypeIndicatorOverlay = styled(Overlay)(
    ({ theme }) => `
    display: flex;
    justify-content: flex-end;
    align-items: flex-end;
    background:${
        theme.palette.mode === "dark"
            ? `linear-gradient(
        315deg,
        rgba(0, 0, 0, 0.14) 0%,
        rgba(0, 0, 0, 0.05) 29.61%,
        rgba(0, 0, 0, 0) 49.86%
    )`
            : `linear-gradient(
        315deg,
        rgba(255, 255, 255, 0.14) 0%,
        rgba(255, 255, 255, 0.05) 29.61%,
        rgba(255, 255, 255, 0) 49.86%
    `
    };
    padding: 8px;
`,
);

const Cont = styled("div")<{ disabled: boolean }>`
    display: flex;
    width: fit-content;
    margin-bottom: ${GAP_BTW_TILES}px;
    min-width: 100%;
    overflow: hidden;
    position: relative;
    flex: 1;
    cursor: ${(props) => (props.disabled ? "not-allowed" : "pointer")};
    user-select: none;
    & > img {
        object-fit: cover;
        max-width: 100%;
        min-height: 100%;
        flex: 1;
        pointer-events: none;
    }

    &:hover {
        input[type="checkbox"] {
            opacity: 0.5;
        }

        .preview-card-hover-overlay {
            opacity: 1;
        }
    }

    border-radius: 4px;
`;

export default function PreviewCard(props: IProps) {
    const galleryContext = useContext(GalleryContext);
    const deduplicateContext = useContext(DeduplicateContext);

    const longPressCallback = () => {
        onSelect(!selected);
    };

    const longPress = useLongPress(longPressCallback, 500);

    const {
        file,
        onClick,
        updateURL,
        selectable,
        selected,
        onSelect,
        selectOnClick,
        onHover,
        onRangeSelect,
        isRangeSelectActive,
        isInsSelectRange,
    } = props;

    const [imgSrc, setImgSrc] = useState<string>(file.msrc);

    const isMounted = useRef(true);

    useEffect(() => {
        return () => {
            isMounted.current = false;
        };
    }, []);

    useEffect(() => {
        const main = async () => {
            try {
                if (file.msrc) {
                    return;
                }
                const url: string =
                    await DownloadManager.getThumbnailForPreview(
                        file,
                        props.showPlaceholder,
                    );

                if (!isMounted.current || !url) {
                    return;
                }
                setImgSrc(url);
                updateURL(file.id, url);
            } catch (e) {
                if (e.message !== CustomError.URL_ALREADY_SET) {
                    log.error("preview card useEffect failed", e);
                }
                // no-op
            }
        };
        main();
    }, [props.showPlaceholder]);

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

    const handleHover = () => {
        if (isRangeSelectActive) {
            onHover();
        }
    };

    const renderFn = () => (
        <Cont
            key={`thumb-${file.id}}`}
            onClick={handleClick}
            onMouseEnter={handleHover}
            disabled={!file?.msrc && !imgSrc}
            {...(selectable ? longPress : {})}
        >
            {selectable && (
                <Check
                    type="checkbox"
                    checked={selected}
                    onChange={handleSelect}
                    $active={isRangeSelectActive && isInsSelectRange}
                    onClick={(e) => e.stopPropagation()}
                />
            )}
            {file.metadata.hasStaticThumbnail ? (
                <StaticThumbnail fileType={file.metadata.fileType} />
            ) : imgSrc ? (
                <img src={imgSrc} />
            ) : (
                <LoadingThumbnail />
            )}
            {file.metadata.fileType === FILE_TYPE.LIVE_PHOTO ? (
                <FileTypeIndicatorOverlay>
                    <AlbumOutlined />
                </FileTypeIndicatorOverlay>
            ) : (
                file.metadata.fileType === FILE_TYPE.VIDEO && (
                    <FileTypeIndicatorOverlay>
                        <PlayCircleOutlineOutlinedIcon />
                    </FileTypeIndicatorOverlay>
                )
            )}
            <SelectedOverlay selected={selected} />
            {shouldShowAvatar(file, galleryContext.user) && (
                <AvatarOverlay>
                    <Avatar file={file} />
                </AvatarOverlay>
            )}

            <HoverOverlay
                className="preview-card-hover-overlay"
                checked={selected}
            />
            <InSelectRangeOverLay
                $active={isRangeSelectActive && isInsSelectRange}
            />
            {deduplicateContext.isOnDeduplicatePage && (
                <FileAndCollectionNameOverlay>
                    <p>{file.metadata.title}</p>
                    <p>
                        {deduplicateContext.collectionNameMap.get(
                            file.collectionID,
                        )}
                    </p>
                </FileAndCollectionNameOverlay>
            )}
            {props?.activeCollectionID === TRASH_SECTION && file.isTrashed && (
                <FileAndCollectionNameOverlay>
                    <p>{formatDateRelative(file.deleteBy / 1000)}</p>
                </FileAndCollectionNameOverlay>
            )}
        </Cont>
    );

    if (deduplicateContext.isOnDeduplicatePage) {
        return (
            <Tooltip
                placement="bottom-start"
                enterDelay={300}
                enterNextDelay={100}
                title={`${
                    file.metadata.title
                } - ${deduplicateContext.collectionNameMap.get(
                    file.collectionID,
                )}`}
            >
                {renderFn()}
            </Tooltip>
        );
    } else {
        return renderFn();
    }
}

function formatDateRelative(date: number) {
    const units = {
        year: 24 * 60 * 60 * 1000 * 365,
        month: (24 * 60 * 60 * 1000 * 365) / 12,
        day: 24 * 60 * 60 * 1000,
        hour: 60 * 60 * 1000,
        minute: 60 * 1000,
        second: 1000,
    };
    const relativeDateFormat = new Intl.RelativeTimeFormat(i18n.language, {
        localeMatcher: "best fit",
        numeric: "always",
        style: "long",
    });
    const elapsed = date - Date.now(); // "Math.abs" accounts for both "past" & "future" scenarios

    for (const u in units)
        if (Math.abs(elapsed) > units[u] || u === "second")
            return relativeDateFormat.format(
                Math.round(elapsed / units[u]),
                u as Intl.RelativeTimeFormatUnit,
            );
}
