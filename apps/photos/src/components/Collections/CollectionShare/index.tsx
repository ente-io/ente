// import EmailShare from './emailShare';
import React from 'react';
import { Collection } from 'types/collection';
import { EnteDrawer } from 'components/EnteDrawer';
import PublicShare from './publicShare';
// import WorkspacesIcon from '@mui/icons-material/Workspaces';
import { t } from 'i18next';
// import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { DialogProps, Stack } from '@mui/material';
import Titlebar from 'components/Titlebar';
import ShareControl from './ShareControl';

interface Props {
    open: boolean;
    onClose: () => void;
    collection: Collection;
}

function CollectionShare(props: Props) {
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

    return (
        <>
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
        </>
    );
}
export default CollectionShare;
