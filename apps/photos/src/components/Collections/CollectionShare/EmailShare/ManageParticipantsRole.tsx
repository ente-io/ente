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
import { Trans } from 'react-i18next';

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
            contentText = (
                <Trans
                    i18nKey="CHANGE_PERMISSIONS_TO_VIEWER"
                    values={{
                        selectedEmail: `${selectedEmail}`,
                    }}
                />
            );

            buttonText = t('CONVERT_TO_VIEWER');
        } else if (role === 'COLLABORATOR' && selectedRole === 'VIEWER') {
            contentText = t(`CHANGE_PERMISSIONS_TO_COLLABORATOR`, {
                selectedEmail: selectedEmail,
            });
            buttonText = t('CONVERT_TO_COLLABORATOR');
        }

        appContext.setDialogMessage({
            title: t('CHANGE_PERMISSION'),
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
            title: t('REMOVE_PARTICIPANT'),
            content: (
                <Trans
                    i18nKey="REMOVE_PARTICIPANT_MESSAGE"
                    values={{
                        selectedEmail: `${selectedEmail}`,
                    }}
                />
            ),
            close: { text: t('CANCEL') },
            proceed: {
                text: t('CONFIRM_REMOVE'),
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
                        title={t('MANAGE')}
                        onRootClose={onRootClose}
                        caption={selectedEmail}
                    />

                    <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                        <Stack>
                            <Typography
                                color="text.muted"
                                variant="small"
                                padding={1}>
                                {t('ADDED_AS')}
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
                                {t('COLLABORATOR_RIGHTS')}
                            </Typography>

                            <Stack py={'30px'}>
                                <Typography
                                    color="text.muted"
                                    variant="small"
                                    padding={1}>
                                    {t('REMOVE_PARTICIPANT_HEAD')}
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
