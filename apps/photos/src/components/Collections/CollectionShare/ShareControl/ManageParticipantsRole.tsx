import { Stack, Typography } from '@mui/material';
import React from 'react';
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

interface Iprops {
    open: boolean;
    collection: Collection;
    onClose: () => void;
    onRootClose: () => void;
    selectedEmail: string;
}

export default function ManageParticipantsRole({
    collection,
    open,
    onClose,
    onRootClose,
    selectedEmail,
}: Iprops) {
    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            onRootClose();
        } else {
            onClose();
        }
    };
    console.log('collection Clicked', collection, selectedEmail);
    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleDrawerClose}>
                <Stack spacing={'10px'} py={'12px'}>
                    <Titlebar
                        onClose={onClose}
                        title={t('Manage')}
                        onRootClose={onRootClose}
                        caption={selectedEmail}
                    />
                    <Typography color="text.muted" variant="small" padding={1}>
                        {t('Added as')}
                    </Typography>

                    <MenuItemGroup>
                        <EnteMenuItem
                            //
                            fontWeight="normal"
                            onClick={() => console.log('clicked')}
                            label={'Collaborator'}
                            startIcon={
                                <ModeEditIcon
                                    style={{ fontSize: 20, marginRight: 8 }}
                                />
                            }
                        />
                        <MenuItemDivider />
                        <EnteMenuItem
                            //
                            fontWeight="normal"
                            onClick={() => console.log('clicked')}
                            label={'Viewer'}
                            startIcon={
                                <PhotoIcon
                                    style={{ fontSize: 20, marginRight: 8 }}
                                />
                            }
                        />
                    </MenuItemGroup>

                    <Typography color="text.muted" variant="small" padding={1}>
                        {t(
                            'Collaborators can add photos and videos to the shared album'
                        )}
                    </Typography>

                    <Typography color="text.muted" variant="small" padding={1}>
                        {t('Remove Participant')}
                    </Typography>
                    <EnteMenuItem
                        //
                        color="error"
                        fontWeight="normal"
                        onClick={() => console.log('clicked')}
                        label={'Remove'}
                        startIcon={
                            <BlockIcon
                                style={{ fontSize: 20, marginRight: 8 }}
                            />
                        }
                    />
                </Stack>
            </EnteDrawer>
        </>
    );
}
