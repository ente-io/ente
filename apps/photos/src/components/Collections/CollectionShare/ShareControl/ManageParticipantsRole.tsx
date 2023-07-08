import { Stack, Typography } from '@mui/material';
import React, { useContext, useEffect, useState } from 'react';
import { Collection } from 'types/collection';
import { EnteDrawer } from 'components/EnteDrawer';
import { t } from 'i18next';
import { DialogProps } from '@mui/material';
import Titlebar from 'components/Titlebar';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import ModeEditIcon from '@mui/icons-material/ModeEdit';
import PhotoIcon from '@mui/icons-material/Photo';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import BlockIcon from '@mui/icons-material/Block';
import DoneIcon from '@mui/icons-material/Done';
import { handleSharingErrors } from 'utils/error/ui';
import { logError } from 'utils/sentry';
import { shareCollection } from 'services/collectionService';
import { GalleryContext } from 'pages/gallery';

interface Iprops {
    open: boolean;
    collection: Collection;
    onClose: () => void;
    onRootClose: () => void;
    selectedEmail: string;
    collectionUnshare: (email: string) => Promise<void>;
}

export default function ManageParticipantsRole({
    collection,
    open,
    onClose,
    onRootClose,
    selectedEmail,
    collectionUnshare,
}: Iprops) {
    const [selectedRole, setSelectedRole] = useState('');
    const galleryContext = useContext(GalleryContext);

    useEffect(() => {
        setSelectedRole(
            collection.sharees?.find((sharee) => sharee.email === selectedEmail)
                ?.role
        );
    }, [open]);

    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            onRootClose();
        } else {
            onClose();
        }
    };

    const handleClick = () => {
        collectionUnshare(selectedEmail);
        onClose();
    };

    const handleRoleChange = (role: string) => {
        setSelectedRole(role);
        updateCollectionRole(selectedEmail, role);
    };

    const updateCollectionRole = async (selectedEmail, role) => {
        try {
            console.log('collection Clicked', collection, selectedEmail);
            await shareCollection(collection, selectedEmail, role);
            await galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            logError(e, errorMessage);
        }
    };

    console.log('collection Clicked', collection, selectedEmail);
    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleDrawerClose}>
                <Stack spacing={'4px'} py={'12px'}>
                    <Titlebar
                        onClose={onClose}
                        title={t('Manage')}
                        onRootClose={onRootClose}
                        caption={selectedEmail}
                    />

                    <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                        <Stack>
                            <Typography
                                color="text.muted"
                                variant="small"
                                padding={1}>
                                {t('Added as')}
                            </Typography>

                            <MenuItemGroup>
                                <EnteMenuItem
                                    //
                                    fontWeight="normal"
                                    onClick={() =>
                                        handleRoleChange('COLLABORATOR')
                                    }
                                    label={'Collaborator'}
                                    startIcon={
                                        <ModeEditIcon
                                            style={{
                                                fontSize: 20,
                                                marginRight: 8,
                                            }}
                                        />
                                    }
                                    endIcon={
                                        selectedRole === 'COLLABORATOR' && (
                                            <DoneIcon />
                                        )
                                    }
                                />
                                <MenuItemDivider />

                                <EnteMenuItem
                                    //
                                    fontWeight="normal"
                                    onClick={() => handleRoleChange('VIEWER')}
                                    label={'Viewer'}
                                    startIcon={
                                        <PhotoIcon
                                            style={{
                                                fontSize: 20,
                                                marginRight: 8,
                                            }}
                                        />
                                    }
                                    endIcon={
                                        selectedRole === 'VIEWER' && (
                                            <DoneIcon />
                                        )
                                    }
                                />
                            </MenuItemGroup>

                            <Typography
                                color="text.muted"
                                variant="small"
                                padding={1}>
                                {t(
                                    'Collaborators can add photos and videos to the shared album'
                                )}
                            </Typography>

                            <Stack py={'30px'}>
                                <Typography
                                    color="text.muted"
                                    variant="small"
                                    padding={1}>
                                    {t('Remove Participant')}
                                </Typography>

                                <EnteMenuItem
                                    //
                                    color="error"
                                    fontWeight="normal"
                                    onClick={handleClick}
                                    label={'Remove'}
                                    startIcon={
                                        <BlockIcon
                                            style={{
                                                fontSize: 20,
                                                marginRight: 8,
                                            }}
                                        />
                                    }
                                />
                            </Stack>
                        </Stack>
                    </Stack>
                </Stack>
            </EnteDrawer>
        </>
    );
}
