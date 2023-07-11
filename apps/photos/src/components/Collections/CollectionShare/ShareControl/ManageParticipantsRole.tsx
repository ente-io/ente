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
import { AppContext } from 'pages/_app';

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

    const appContext = useContext(AppContext);

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
        if (role !== selectedRole) {
            changeRolePermission(selectedEmail, role);
        }
    };

    const updateCollectionRole = async (selectedEmail, role) => {
        try {
            await shareCollection(collection, selectedEmail, role);

            await galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            logError(e, errorMessage);
        }
    };

    const changeRolePermission = (selectedEmail, role) => {
        let contentText;
        let buttonText;

        if (role === 'VIEWER' && selectedRole === 'COLLABORATOR') {
            contentText = t(
                `{{selectedEmail}} will not be able to add more photos to the album, they will still be able to remove photos added by them`,
                { selectedEmail: selectedEmail }
            );
            buttonText = t('Yes, convert to viewer');
        } else if (role === 'COLLABORATOR' && selectedRole === 'VIEWER') {
            contentText = t(
                `{{selectedEmail}} will be able to add photos to the album`,
                { selectedEmail: selectedEmail }
            );
            buttonText = t('Yes, convert to collaborator');
        }

        appContext.setDialogMessage({
            title: t('Change Permission?'),
            content: contentText,
            close: { text: t('CANCEL') },
            proceed: {
                text: buttonText,
                action: () => {
                    updateCollectionRole(selectedEmail, role),
                        setSelectedRole(role);
                },
                variant: 'critical',
            },
        });
    };

    const removeParticipant = () => {
        appContext.setDialogMessage({
            title: t('Remove?'),
            content: t(
                ` {{selectedEmail}} will be removed removed from the album, Any photos added by them will be removed from the album.`,
                { selectedEmail: selectedEmail }
            ),
            close: { text: t('CANCEL') },
            proceed: {
                text: t('Yes, remove'),
                action: () => {
                    handleClick();
                },
                variant: 'critical',
            },
        });
    };

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
                                    color="error"
                                    fontWeight="normal"
                                    onClick={removeParticipant}
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
