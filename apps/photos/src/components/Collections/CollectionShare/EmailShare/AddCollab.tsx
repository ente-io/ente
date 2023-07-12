import { Stack } from '@mui/material';
import { Collection } from 'types/collection';

import { EnteDrawer } from 'components/EnteDrawer';
import { t } from 'i18next';
import { DialogProps } from '@mui/material';
import Titlebar from 'components/Titlebar';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import WorkspacesIcon from '@mui/icons-material/Workspaces';
import CollabEmailShare from './CollabEmailShare';

interface Iprops {
    collection: Collection;

    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
}

export default function AddCollab({
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

    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleDrawerClose}>
                <Stack spacing={'4px'} py={'12px'}>
                    <Titlebar
                        onClose={onClose}
                        title={t('ADD_COLLABORATORS')}
                        onRootClose={onRootClose}
                        caption={collection.name}
                    />
                    <Stack py={'20px'} px={'8px'} spacing={'8px'}>
                        <MenuSectionTitle
                            title={t('ADD_NEW_EMAIL')}
                            icon={<WorkspacesIcon />}
                        />
                        <CollabEmailShare
                            collection={collection}
                            onClose={onClose}
                        />
                    </Stack>
                </Stack>
            </EnteDrawer>
        </>
    );
}
