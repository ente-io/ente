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
}

/**
 * A simplified variant of {@link CollectionCard}, meant to be used for
 * representing either collections and files.
 */
export const ItemCard: React.FC<ItemCardProps> = ({
    coverFile,
    TileComponent,
}) => {
    const [coverImageURL, setCoverImageURL] = useState("");

    useEffect(() => {
        const main = async () => {
            const url = await downloadManager.getThumbnailForPreview(coverFile);
            if (url) setCoverImageURL(url);
        };
        void main();
    }, [coverFile]);

    return (
        <TileComponent>
            {coverFile.metadata.hasStaticThumbnail ? (
                <StaticThumbnail fileType={coverFile.metadata.fileType} />
            ) : coverImageURL ? (
                <img src={coverImageURL} />
            ) : (
                <LoadingThumbnail />
            )}
        </TileComponent>
    );
};

/**
 * A verbatim copy of CollectionTile, meant to be used with ItemCards.
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

export const ResultPreviewTile = styled(ItemTile)`
    width: 48px;
    height: 48px;
`;
