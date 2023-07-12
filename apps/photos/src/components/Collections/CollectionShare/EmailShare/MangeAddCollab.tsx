import { Stack } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { Collection } from 'types/collection';
import AddIcon from '@mui/icons-material/Add';
import { useState } from 'react';
import { t } from 'i18next';
import ManageAddCollabOptions from './ManageAddCollabOptions';

interface Iprops {
    collection: Collection;

    onRootClose: () => void;
}
export default function ManageAddCollab({ collection, onRootClose }: Iprops) {
    const [manageShareView, setManageShareView] = useState(false);
    const closeManageShare = () => setManageShareView(false);
    const openManageShare = () => setManageShareView(true);
    return (
        <>
            <Stack>
                <MenuItemGroup>
                    <EnteMenuItem
                        startIcon={<AddIcon />}
                        onClick={openManageShare}
                        label={t('ADD_COLLABORATORS')}
                    />
                </MenuItemGroup>
            </Stack>
            <ManageAddCollabOptions
                open={manageShareView}
                onClose={closeManageShare}
                onRootClose={onRootClose}
                collection={collection}
            />
        </>
    );
}
