import React from 'react';
import { GalleryContext } from 'pages/gallery';
import { useState, useContext, useEffect } from 'react';
import downloadManager from 'services/downloadManager';
import { EnteFile } from 'types/file';
import { CollectionTile, LargerCollectionTile } from './styledComponents';

export default function CollectionCard(props: {
    children?: any;
    latestFile: EnteFile;
    onClick: () => void;
    large?: boolean;
}) {
    const { latestFile: file, onClick, children, large } = props;

    const [coverImageURL, setCoverImageURL] = useState(null);
    const galleryContext = useContext(GalleryContext);
    useEffect(() => {
        const main = async () => {
            if (!file) {
                return;
            }
            if (!galleryContext.thumbs.has(file.id)) {
                const url = await downloadManager.getThumbnail(file);
                galleryContext.thumbs.set(file.id, url);
            }
            setCoverImageURL(galleryContext.thumbs.get(file.id));
        };
        main();
    }, [file]);
    const UsedCollectionTile = large ? LargerCollectionTile : CollectionTile;
    return (
        <UsedCollectionTile coverImgURL={coverImageURL} onClick={onClick}>
            {children}
        </UsedCollectionTile>
    );
}
