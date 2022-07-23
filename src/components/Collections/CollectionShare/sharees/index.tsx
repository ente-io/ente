import { Box, Typography } from '@mui/material';
import { GalleryContext } from 'pages/gallery';
import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import { unshareCollection } from 'services/collectionService';
import { Collection } from 'types/collection';
import constants from 'utils/strings/constants';
import ShareeRow from './row';

interface Iprops {
    collection: Collection;
}

export function CollectionShareSharees({ collection }: Iprops) {
    const appContext = useContext(AppContext);
    const galleryContext = useContext(GalleryContext);

    const collectionUnshare = async (sharee) => {
        try {
            appContext.startLoading();
            await unshareCollection(collection, sharee.email);
            await galleryContext.syncWithRemote(false, true);
        } finally {
            appContext.finishLoading();
        }
    };

    if (!collection.sharees?.length) {
        return <></>;
    }

    return (
        <Box mb={3}>
            <Typography variant="body2" color="text.secondary">
                {constants.SHAREES}
            </Typography>
            {collection.sharees?.map((sharee) => (
                <ShareeRow
                    key={sharee.email}
                    sharee={sharee}
                    collectionUnshare={collectionUnshare}
                />
            ))}
        </Box>
    );
}
