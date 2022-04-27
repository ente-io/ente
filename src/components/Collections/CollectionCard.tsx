import React from 'react';
import { GalleryContext } from 'pages/gallery';
import { useState, useContext, useEffect } from 'react';
import downloadManager from 'services/downloadManager';
import { EnteFile } from 'types/file';
import { CollectionTile } from './styledComponents';

export default function CollectionCard(props: {
    children?: any;
    latestFile: EnteFile;
    onClick: () => void;
    customCollectionTile?: any;
}) {
    const { latestFile: file, onClick, children, customCollectionTile } = props;

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
    const UsedCollectionTile = customCollectionTile ?? CollectionTile;
    return (
        <UsedCollectionTile coverImgURL={coverImageURL} onClick={onClick}>
            {children}
        </UsedCollectionTile>
    );
}
