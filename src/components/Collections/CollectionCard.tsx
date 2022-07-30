import React from 'react';
import { GalleryContext } from 'pages/gallery';
import { useState, useContext, useEffect } from 'react';
import downloadManager from 'services/downloadManager';
import { EnteFile } from 'types/file';

export default function CollectionCard(props: {
    children?: any;
    latestFile: EnteFile;
    onClick: () => void;
    collectionTile: any;
}) {
    const {
        latestFile: file,
        onClick,
        children,
        collectionTile: CustomCollectionTile,
    } = props;

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

    return (
        <CustomCollectionTile onClick={onClick}>
            {coverImageURL && <img src={coverImageURL} />}
            {children}
        </CustomCollectionTile>
    );
}
