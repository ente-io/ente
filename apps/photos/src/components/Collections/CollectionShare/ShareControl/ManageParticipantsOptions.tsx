import { Stack } from '@mui/material';
// import { GalleryContext } from 'pages/gallery';
// import React, { useContext, useState } from 'react';
// import {
//     deleteShareableURL,
//     updateShareableURL,
// } from 'services/collectionService';
import { Collection } from 'types/collection';

import { EnteDrawer } from 'components/EnteDrawer';
import { t } from 'i18next';
import { DialogProps } from '@mui/material';
import Titlebar from 'components/Titlebar';
// import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
// import EmailShare from '../emailShare';
// import WorkspacesIcon from '@mui/icons-material/Workspaces';
// import ViewerEmailShare from './ViewerEmailShare';
// import { CollectionShareSharees } from '../sharees';
import { ManageParticipantsList } from './ManageParticipantsList';

interface Iprops {
    collection: Collection;

    open: boolean;
    onClose: () => void;
    onRootClose: () => void;

    peopleCount: number;
}

export default function ManageParticipantsOptions({
    // publicShareProp,
    // setPublicShareProp,
    open,
    collection,
    onClose,
    onRootClose,
    peopleCount,
}: Iprops) {
    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            onRootClose();
        } else {
            onClose();
        }
    };
    // const galleryContext = useContext(GalleryContext);

    // const [sharableLinkError, setSharableLinkError] = useState(null);

    // Adding key-value pairs to the map

    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleDrawerClose}>
                <Stack spacing={'4px'} py={'12px'}>
                    <Titlebar
                        onClose={onClose}
                        title={collection.name}
                        onRootClose={onRootClose}
                        caption={`${peopleCount}${t(' Participants')} `}
                    />
                    <Stack py={'20px'} px={'8px'} spacing={'8px'}>
                        <ManageParticipantsList
                            collection={collection}
                            onRootClose={onRootClose}
                        />
                    </Stack>
                </Stack>
            </EnteDrawer>
        </>
    );
}
