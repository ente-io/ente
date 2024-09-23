import {
    LoadingThumbnail,
    StaticThumbnail,
} from "@/new/photos/components/PlaceholderThumbnails";
import downloadManager from "@/new/photos/services/download";
import { type EnteFile } from "@/new/photos/types/file";
import { styled } from "@mui/material";
import React, { useEffect, useState } from "react";

interface ItemCardProps {
    /** The file whose thumbnail (if any) should be should be shown. */
    coverFile: EnteFile;
    /** One of the *Tile components to use as the top level element. */
    TileComponent: React.FC<React.PropsWithChildren>;
    /** Optional click handler. */
    onClick?: () => void;
}
/**
 * A generic card that can be be used to represent collections,  files, people -
 * anything that has an associated "cover photo".
 *
 * This is a simplified variant / almost-duplicate of {@link CollectionCard}.
 */
export const ItemCard: React.FC<React.PropsWithChildren<ItemCardProps>> = ({
    coverFile,
    TileComponent,
    onClick,
    children,
}) => {
    const [coverImageURL, setCoverImageURL] = useState("");

    useEffect(() => {
        void downloadManager
            .getThumbnailForPreview(coverFile)
            .then((url) => url && setCoverImageURL(url));
    }, [coverFile]);

    return (
        <TileComponent {...{ onClick }}>
            {coverFile.metadata.hasStaticThumbnail ? (
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
 * A generic "base" tile, meant to be used as the {@link TileComponent} provided
 * to an {@link ItemCard}.
 *
 * Currently a verbatim copy of {@link CollectionTile}.
 */
export const ItemTile = styled("div")`
    display: flex;
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
 * A TileComponent for use in search result dropdown's preview files.
 */
export const ResultPreviewTile = styled(ItemTile)`
    width: 48px;
    height: 48px;
`;
