import React from 'react';
import { Collection, CollectionSummary } from 'types/collection';
import { EnteDrawer } from 'components/EnteDrawer';
import PublicShare from './publicShare';
import { t } from 'i18next';
import { DialogProps, Stack } from '@mui/material';
import Titlebar from 'components/Titlebar';
import ShareControl from './ShareControl';
import { CollectionSummaryType } from 'constants/collection';
import { OwnerParticipant } from './ShareControl/OwnerParticipant';
import { SharingDetailsViewers } from './ShareControl/SharingDetailsViewers';
import { ShareDetailsCollab } from './ShareControl/SharingDetailsCollab';

interface Props {
    open: boolean;
    onClose: () => void;
    collection: Collection;
    collectionSummary: CollectionSummary;
}

function CollectionShare({ collectionSummary, ...props }: Props) {
    const handleRootClose = () => {
        props.onClose();
    };
    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            handleRootClose();
        } else {
            props.onClose();
        }
    };
    if (!props.collection) {
        return <></>;
    }
    const { type } = collectionSummary;

    return (
        <>
            {type === CollectionSummaryType.album && (
                <EnteDrawer
                    anchor="right"
                    open={props.open}
                    onClose={handleDrawerClose}
                    BackdropProps={{
                        sx: { '&&&': { backgroundColor: 'transparent' } },
                    }}>
                    <Stack spacing={'4px'} py={'12px'}>
                        <Titlebar
                            onClose={props.onClose}
                            title={t('SHARE_COLLECTION')}
                            onRootClose={handleRootClose}
                        />
                        <Stack py={'20px'} px={'8px'}>
                            <ShareControl
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            />
                            <Stack py={'20px'} px={'8px'} spacing={10}></Stack>
                            <PublicShare
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            />
                        </Stack>
                    </Stack>
                </EnteDrawer>
            )}

            {type === CollectionSummaryType.outgoingShare && (
                <EnteDrawer
                    anchor="right"
                    open={props.open}
                    onClose={handleDrawerClose}
                    BackdropProps={{
                        sx: { '&&&': { backgroundColor: 'transparent' } },
                    }}>
                    <Stack spacing={'4px'} py={'12px'}>
                        <Titlebar
                            onClose={props.onClose}
                            title={t('SHARE_COLLECTION')}
                            onRootClose={handleRootClose}
                        />
                        <Stack py={'20px'} px={'8px'}>
                            <ShareControl
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            />
                            <Stack py={'20px'} px={'8px'} spacing={10}></Stack>
                            <PublicShare
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            />
                        </Stack>
                    </Stack>
                </EnteDrawer>
            )}

            {type === CollectionSummaryType.incomingShareViewer && (
                <EnteDrawer
                    anchor="right"
                    open={props.open}
                    onClose={handleDrawerClose}
                    BackdropProps={{
                        sx: { '&&&': { backgroundColor: 'transparent' } },
                    }}>
                    <Stack spacing={'4px'} py={'12px'}>
                        <Titlebar
                            onClose={props.onClose}
                            title={t('SHARING_DETAILS')}
                            onRootClose={handleRootClose}
                            caption={props.collection.name}
                        />
                        <Stack py={'20px'} px={'8px'}>
                            <OwnerParticipant collection={props.collection} />
                            <SharingDetailsViewers
                                collection={props.collection}
                            />

                            <Stack py={'20px'} px={'8px'} spacing={10}></Stack>
                        </Stack>
                    </Stack>
                </EnteDrawer>
            )}

            {type === CollectionSummaryType.incomingShareCollaborator && (
                <EnteDrawer
                    anchor="right"
                    open={props.open}
                    onClose={handleDrawerClose}
                    BackdropProps={{
                        sx: { '&&&': { backgroundColor: 'transparent' } },
                    }}>
                    <Stack spacing={'4px'} py={'12px'}>
                        <Titlebar
                            onClose={props.onClose}
                            title={t('SHARING_DETAILS')}
                            onRootClose={handleRootClose}
                            caption={props.collection.name}
                        />
                        <Stack py={'20px'} px={'8px'}>
                            <OwnerParticipant collection={props.collection} />
                            <SharingDetailsViewers
                                collection={props.collection}
                            />
                            <ShareDetailsCollab collection={props.collection} />
                        </Stack>
                    </Stack>
                </EnteDrawer>
            )}
        </>
    );
}
export default CollectionShare;
