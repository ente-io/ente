import { Stack } from '@mui/material';
// import { GalleryContext } from 'pages/gallery';
// import React, { useContext, useState } from 'react';
// import {
//     deleteShareableURL,
//     updateShareableURL,
// } from 'services/collectionService';
import { Collection, PublicURL } from 'types/collection';
import { SetPublicShareProp } from 'types/publicCollection';
import { EnteDrawer } from 'components/EnteDrawer';
import { t } from 'i18next';
import { DialogProps } from '@mui/material';
import Titlebar from 'components/Titlebar';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
// import EmailShare from '../emailShare';
import WorkspacesIcon from '@mui/icons-material/Workspaces';
import CollabEmailShare from './CollabEmailShare';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
    publicShareUrl: string;
}

export default function ManageAddCollabOptions({
    // publicShareProp,
    // setPublicShareProp,
    open,
    collection,
    onClose,
    onRootClose,
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

    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleDrawerClose}>
                <Stack spacing={'4px'} py={'12px'}>
                    <Titlebar
                        onClose={onClose}
                        title={t('Add Collaborator')}
                        onRootClose={onRootClose}
                    />
                    <Stack py={'20px'} px={'8px'} spacing={'8px'}>
                        <MenuSectionTitle
                            title={t('Add a new email')}
                            icon={<WorkspacesIcon />}
                        />
                        <CollabEmailShare collection={collection} />
                    </Stack>
                </Stack>
            </EnteDrawer>
        </>
    );
}
