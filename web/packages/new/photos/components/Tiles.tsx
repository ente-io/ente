import { downloadManager } from "@/gallery/services/download";
import { type EnteFile } from "@/media/file";
import {
    LoadingThumbnail,
    StaticThumbnail,
} from "@/new/photos/components/PlaceholderThumbnails";
import { styled } from "@mui/material";
import React, { useEffect, useState } from "react";
import { faceCrop } from "../services/ml";
import { UnstyledButton } from "./UnstyledButton";

interface ItemCardProps {
    /**
     * One of the *Tile components to use as the top level element.
     */
    TileComponent: React.FC<React.PropsWithChildren>;
    /**
     * Optional file whose thumbnail (if any) should be should be shown.
     */
    coverFile?: EnteFile | undefined;
    /**
     * Optional ID of a specific face within {@link coverFile} to show.
     *
     * Precondition: {@link faceID} must be an ID of a face that belongs to the
     * given {@link coverFile}.
     */
    coverFaceID?: string | undefined;
    /**
     * Optional boolean indicating if the user is currently scrolling.
     *
     * This is used as a hint by the file downloader to prioritize downloads.
     */
    isScrolling?: boolean;
    /**
     * Optional click handler.
     */
    onClick?: () => void;
}

/**
 * A generic card that can be be used to represent collections, files, people -
 * anything that (usually) has an associated "cover photo".
 *
 * Usually, we provide it a {@link coverFile} prop to set the file whose
 * thumbnail should be shown in the card. However, an additional
 * {@link coverFaceID} prop can be used to show the face crop for that specific
 * face within the cover file.
 *
 * Note that while the common use case is to use this with a cover photo (and an
 * additional cover faceID), both of these are optional and the item card can
 * also be used as a static component without an associated cover image by
 * covering it with an opaque overlay.
 */
export const ItemCard: React.FC<React.PropsWithChildren<ItemCardProps>> = ({
    TileComponent,
    coverFile,
    coverFaceID,
    isScrolling,
    onClick,
    children,
}) => {
    const [coverImageURL, setCoverImageURL] = useState<string | undefined>();

    useEffect(() => {
        if (!coverFile) return;

        let didCancel = false;

        if (coverFaceID) {
            void faceCrop(coverFaceID, coverFile).then(
                (url) => !didCancel && setCoverImageURL(url),
            );
        } else {
            void downloadManager
                .renderableThumbnailURL(coverFile, isScrolling)
                .then((url) => !didCancel && setCoverImageURL(url));
        }

        return () => {
            didCancel = true;
        };
    }, [coverFile, coverFaceID, isScrolling]);

    return (
        <TileComponent {...{ onClick }}>
            {coverFile?.metadata.hasStaticThumbnail ? (
                <StaticThumbnail fileType={coverFile.metadata.fileType} />
            ) : coverImageURL ? (
                <img src={coverImageURL} />
            ) : (
                <LoadingThumbnail />
            )}
            {children}
        </TileComponent>
    );
};

/**
 * A generic "base" tile, meant to be used (after setting dimensions) as the
 * {@link TileComponent} provided to an {@link ItemCard}.
 *
 * Use {@link ItemTileOverlay} (usually via one of its presets) to overlay
 * content on top of the tile.
 */
const BaseTile = styled("div")`
    display: flex;
    /* Act as container for the absolutely positioned ItemTileOverlays. */
    position: relative;
    border-radius: 4px;
    overflow: hidden;
    cursor: pointer;
    & > img {
        object-fit: cover;
        width: 100%;
        height: 100%;
        pointer-events: none;
    }
    user-select: none;
`;

/**
 * A 48x48 TileComponent used in search result dropdown's preview files and
 * other places.
 */
export const PreviewItemTile = styled(BaseTile)`
    width: 48px;
    height: 48px;
`;

/**
 * A rectangular, TV-ish tile used in the gallery bar.
 */
export const BarItemTile = styled(BaseTile)`
    width: 90px;
    height: 64px;
`;

/**
 * A square tile used on the duplicates listing.
 */
export const DuplicateItemTile = styled(BaseTile)`
    /* The thumbnails are not interactable, reset the pointer */
    cursor: initial;
`;

/**
 * A variant of {@link BaseTile} meant for use when the tile is interactable.
 */
export const BaseTileButton = styled(UnstyledButton)`
    /* Buttons reset this to the special token buttontext */
    color: inherit;
    /* Buttons reset this to center */
    text-align: inherit;

    /* Rest of this is mostly verbatim from BaseTile ... */

    display: flex;
    /* Act as container for the absolutely positioned ItemTileOverlays. */
    position: relative;
    border-radius: 4px;
    overflow: hidden;
    & > img {
        object-fit: cover;
        width: 100%;
        height: 100%;
        pointer-events: none;
    }
`;

/**
 * A large 150x150 TileComponent used when, for example, when showing the list
 * of collections in the all collections view and in the collection selector.
 */
export const LargeTileButton = styled(BaseTileButton)`
    width: 150px;
    height: 150px;
`;

/**
 * An empty overlay on top of the nearest relative positioned ancestor.
 *
 * This is meant to be used in tandem with a derivate of {@link BaseTile} or
 * {@link BaseTileButton}.
 */
export const ItemTileOverlay = styled("div")`
    position: absolute;
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
`;

/**
 * An {@link ItemTileOverlay} suitable for hosting textual content at the top
 * left of small and medium sized tiles.
 */
export const TileTextOverlay = styled(ItemTileOverlay)`
    padding: 4px;
    background: linear-gradient(
        0deg,
        rgba(0, 0, 0, 0.1) 0%,
        rgba(0, 0, 0, 0.5) 86.46%
    );
`;

/**
 * A variation of {@link TileTextOverlay} for use with larger tiles like the
 * {@link CollectionTile}.
 */
export const LargeTileTextOverlay = styled(ItemTileOverlay)`
    padding: 8px;
    background: linear-gradient(
        0deg,
        rgba(0, 0, 0, 0.1) 0%,
        rgba(0, 0, 0, 0.5) 86.46%
    );
`;

/**
 * A container for "+", suitable for use with a {@link LargeTileTextOverlay}.
 */
export const LargeTilePlusOverlay = styled(ItemTileOverlay)(
    ({ theme }) => `
    display: flex;
    justify-content: center;
    align-items: center;
    font-size: 42px;
    color: ${theme.vars.palette.stroke.muted};
`,
);

/**
 * An {@link ItemTileOverlay} suitable for holding the collection name shown
 * atop the tiles in the duplicates listing.
 */
export const DuplicateTileTextOverlay = styled(ItemTileOverlay)`
    display: flex;
    justify-content: center;
    align-items: flex-end;
    padding: 4px;
    background: linear-gradient(transparent 50%, rgba(0, 0, 0, 0.7));
`;
