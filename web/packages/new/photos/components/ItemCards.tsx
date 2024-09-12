import {
    LoadingThumbnail,
    StaticThumbnail,
} from "@/new/photos/components/PlaceholderThumbnails";
import downloadManager from "@/new/photos/services/download";
import { type EnteFile } from "@/new/photos/types/file";
import React, { useEffect, useState } from "react";

interface ItemCardProps {
    coverFile: EnteFile;
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
