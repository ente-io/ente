// import EmailShare from './emailShare';
import React from 'react';
import { Collection, CollectionSummary } from 'types/collection';
import { EnteDrawer } from 'components/EnteDrawer';
import PublicShare from './publicShare';
// import WorkspacesIcon from '@mui/icons-material/Workspaces';
import { t } from 'i18next';
// import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { DialogProps, Stack } from '@mui/material';
import Titlebar from 'components/Titlebar';
import ShareControl from './ShareControl';
import { CollectionSummaryType } from 'constants/collection';
// import SharingDetailsViewers from './ShareControl/SharingDetailsViewers';
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
                                collectionSummaryType={type}
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            />
                            <Stack py={'20px'} px={'8px'} spacing={10}></Stack>
                            {/* <MenuSectionTitle
                            title={t('ADD_EMAIL_TITLE')}
                            icon={<WorkspacesIcon />}
                        />
                        <EmailShare collection={props.collection} /> */}
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
                            title={t('Sharing details')}
                            onRootClose={handleRootClose}
                        />
                        <Stack py={'20px'} px={'8px'}>
                            <OwnerParticipant collection={props.collection} />
                            <SharingDetailsViewers
                                collection={props.collection}
                            />

                            {/* <SharingDetailsViewers
                                collectionSummaryType={type}
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            /> */}
                            <Stack py={'20px'} px={'8px'} spacing={10}></Stack>
                            {/* <MenuSectionTitle
                            title={t('ADD_EMAIL_TITLE')}
                            icon={<WorkspacesIcon />}
                        />
                        <EmailShare collection={props.collection} /> */}
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
                            title={t('Sharing details')}
                            onRootClose={handleRootClose}
                        />
                        <Stack py={'20px'} px={'8px'}>
                            <OwnerParticipant collection={props.collection} />
                            <SharingDetailsViewers
                                collection={props.collection}
                            />
                            <ShareDetailsCollab collection={props.collection} />
                            {/* <MenuSectionTitle
                            title={t('ADD_EMAIL_TITLE')}
                            icon={<WorkspacesIcon />}
                        />
                        <EmailShare collection={props.collection} /> */}
                        </Stack>
                    </Stack>
                </EnteDrawer>
            )}
        </>
    );
}
export default CollectionShare;
