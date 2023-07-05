import { Box } from '@mui/material';
import React, { useContext } from 'react';
// import { t } from 'i18next';
import { Collection } from 'types/collection';
import { OwnerParticipant } from './OwnerParticipant';
import { ViewerParticipants } from './ViewerParticipants';
import { CollaboratorParticipants } from './CollaboratorParticipants';
import { unshareCollection } from 'services/collectionService';
import { AppContext } from 'pages/_app';
import { GalleryContext } from 'pages/gallery';

interface Iprops {
    collection: Collection;
    onRootClose: () => void;
}

export function ManageParticipantsList({ collection, onRootClose }: Iprops) {
    if (!collection.sharees?.length) {
        return <></>;
    }
    const appContext = useContext(AppContext);
    const galleryContext = useContext(GalleryContext);

    const collectionUnshare = async (email: string) => {
        try {
            appContext.startLoading();
            await unshareCollection(collection, email);
            await galleryContext.syncWithRemote(false, true);
        } finally {
            appContext.finishLoading();
        }
    };

    return (
        <Box mb={3}>
            <OwnerParticipant collection={collection}></OwnerParticipant>
            <CollaboratorParticipants
                collection={collection}
                onRootClose={onRootClose}
                collectionUnshare={
                    collectionUnshare
                }></CollaboratorParticipants>
            <ViewerParticipants
                collection={collection}
                onRootClose={onRootClose}
                collectionUnshare={collectionUnshare}></ViewerParticipants>
        </Box>
    );
}
