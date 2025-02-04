import { Overlay } from "@/base/components/containers";
import { formatDateRelative } from "@/base/i18n-date";
import log from "@/base/log";
import { downloadManager } from "@/gallery/services/download";
import { enteFileDeletionDate } from "@/media/file";
import { FileType } from "@/media/file-type";
import {
    GAP_BTW_TILES,
    IMAGE_CONTAINER_MAX_WIDTH,
} from "@/new/photos/components/PhotoList";
import {
    LoadingThumbnail,
    StaticThumbnail,
} from "@/new/photos/components/PlaceholderThumbnails";
import { TRASH_SECTION } from "@/new/photos/services/collection";
import useLongPress from "@ente/shared/hooks/useLongPress";
import AlbumOutlinedIcon from "@mui/icons-material/AlbumOutlined";
import FavoriteRoundedIcon from "@mui/icons-material/FavoriteRounded";
import PlayCircleOutlineOutlinedIcon from "@mui/icons-material/PlayCircleOutlineOutlined";
import { styled } from "@mui/material";
import type { DisplayFile } from "components/PhotoFrame";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useEffect, useRef, useState } from "react";
import { shouldShowAvatar } from "utils/file";
import Avatar from "./Avatar";

interface IProps {
    file: DisplayFile;
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
    isFav: boolean;
}

const Check = styled("input")<{ $active: boolean }>(
    ({ theme, $active }) => `
    appearance: none;
    position: absolute;
    z-index: 10;
    left: 0;
    outline: none;
    cursor: pointer;
    @media (pointer: coarse) {
        pointer-events: none;
    }

    &::before {
        content: "";
        width: 19px;
        height: 19px;
        background-color: ${theme.vars.palette.fixed.gray.E};
        display: inline-block;
        border-radius: 50%;
        vertical-align: bottom;
        margin: 6px 6px;
        transition: background-color 0.3s ease;
        pointer-events: inherit;

    }
    &::after {
        content: "";
        position: absolute;
        width: 5px;
        height: 11px;
        border-right: 2px solid ${theme.vars.palette.fixed.gray.B};
        border-bottom: 2px solid ${theme.vars.palette.fixed.gray.B};
        transition: transform 0.3s ease;
        pointer-events: inherit;
        transform: translate(-18px, 9px) rotate(45deg);
    }

    /* checkmark background (filled circle) */
    &:checked::before {
        content: "";
        background-color: ${theme.vars.palette.accent.main};
        border-color: ${theme.vars.palette.accent.main};
        color: white;
    }
    /* checkmark foreground (tick) */
    &:checked::after {
        content: "";
        border-right: 2px solid ${theme.vars.palette.fixed.gray.E};
        border-bottom: 2px solid ${theme.vars.palette.fixed.gray.E};
    }
    visibility: hidden;
    ${$active && "visibility: visible; opacity: 0.5;"};
    &:checked {
        visibility: visible;
        opacity: 1 !important;
    }
`,
);

const HoverOverlay = styled("div")<{ checked: boolean }>`
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

const AvatarOverlay = styled(Overlay)`
    display: flex;
    justify-content: flex-end;
    align-items: flex-start;
    padding-right: 5px;
    padding-top: 5px;
`;

const FavOverlay = styled(Overlay)`
    display: flex;
    justify-content: flex-start;
    align-items: flex-end;
    padding-left: 5px;
    padding-bottom: 5px;
    opacity: 0.9;
`;

const InSelectRangeOverlay = styled(Overlay)(
    ({ theme }) => `
    outline: none;
    background: ${theme.vars.palette.accent.main};
    opacity: 0.14;
`,
);

const FileAndCollectionNameOverlay = styled("div")`
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
    color: white;
    position: absolute;
`;

const SelectedOverlay = styled(Overlay)(
    ({ theme }) => `
    z-index: 5;
    border: 2px solid ${theme.vars.palette.accent.main};
    border-radius: 4px;
`,
);

const FileTypeIndicatorOverlay = styled(Overlay)(({ theme }) => ({
    display: "flex",
    justifyContent: "flex-end",
    alignItems: "flex-end",
    padding: "8px",
    // TODO(LM): Ditto the dark one until lm is ready.
    // background:
    // "linear-gradient(315deg, rgba(255, 255, 255, 0.14) 0%, rgba(255, 255,
    // 255, 0.05) 29.61%, rgba(255, 255, 255, 0) 49.86%)",
    background:
        "linear-gradient(315deg, rgba(0, 0, 0, 0.14) 0%, rgba(0, 0, 0, 0.05) 29.61%, rgba(0, 0, 0, 0) 49.86%)",
    ...theme.applyStyles("dark", {
        background:
            "linear-gradient(315deg, rgba(0, 0, 0, 0.14) 0%, rgba(0, 0, 0, 0.05) 29.61%, rgba(0, 0, 0, 0) 49.86%)",
    }),
}));

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
            visibility: visible;
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
                    await downloadManager.renderableThumbnailURL(
                        file,
                        props.showPlaceholder,
                    );

                if (!isMounted.current || !url) {
                    return;
                }
                setImgSrc(url);
                updateURL(file.id, url);
            } catch (e) {
                log.error("preview card useEffect failed", e);
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

    return (
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
            {file.metadata.fileType === FileType.livePhoto ? (
                <FileTypeIndicatorOverlay>
                    <AlbumOutlinedIcon />
                </FileTypeIndicatorOverlay>
            ) : (
                file.metadata.fileType === FileType.video && (
                    <FileTypeIndicatorOverlay>
                        <PlayCircleOutlineOutlinedIcon />
                    </FileTypeIndicatorOverlay>
                )
            )}
            {selected && <SelectedOverlay />}
            {shouldShowAvatar(file, galleryContext.user) && (
                <AvatarOverlay>
                    <Avatar file={file} />
                </AvatarOverlay>
            )}
            {props.isFav && (
                <FavOverlay>
                    <FavoriteRoundedIcon />
                </FavOverlay>
            )}

            <HoverOverlay
                className="preview-card-hover-overlay"
                checked={selected}
            />
            {isRangeSelectActive && isInsSelectRange && (
                <InSelectRangeOverlay />
            )}

            {props?.activeCollectionID === TRASH_SECTION && file.isTrashed && (
                <FileAndCollectionNameOverlay>
                    <p>{formatDateRelative(enteFileDeletionDate(file))}</p>
                </FileAndCollectionNameOverlay>
            )}
        </Cont>
    );
}

/*
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
*/
