import React from 'react';
import { GalleryContext } from 'pages/gallery';
import { useState, useContext, useEffect } from 'react';
import downloadManager from 'services/download';
import { EnteFile } from 'types/file';
import { StaticThumbnail } from 'components/PlaceholderThumbnails';
import { LoadingThumbnail } from 'components/PlaceholderThumbnails';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';

export default function CollectionCard(props: {
    children?: any;
    coverFile: EnteFile;
    onClick: () => void;
    collectionTile: any;
    isScrolling?: boolean;
}) {
    const {
        coverFile: file,
        onClick,
        children,
        collectionTile: CustomCollectionTile,
        isScrolling,
    } = props;

    const [coverImageURL, setCoverImageURL] = useState(null);
    const galleryContext = useContext(GalleryContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext
    );

    const thumbsStore = publicCollectionGalleryContext?.accessedThroughSharedURL
        ? publicCollectionGalleryContext.thumbs
        : galleryContext.thumbs;

    useEffect(() => {
        const main = async () => {
            if (!file) {
                return;
            }
            if (!thumbsStore.has(file.id)) {
                if (isScrolling) {
                    return;
                }
                const url = await downloadManager.getThumbnailForPreview(file);
                thumbsStore.set(file.id, url);
            }
            setCoverImageURL(thumbsStore.get(file.id));
        };
        main();
    }, [file, isScrolling]);

    return (
        <CustomCollectionTile onClick={onClick}>
            {file?.metadata.hasStaticThumbnail ? (
                <StaticThumbnail fileType={file?.metadata.fileType} />
            ) : coverImageURL ? (
                <img src={coverImageURL} />
            ) : (
                <LoadingThumbnail />
            )}
            {children}
        </CustomCollectionTile>
    );
}
