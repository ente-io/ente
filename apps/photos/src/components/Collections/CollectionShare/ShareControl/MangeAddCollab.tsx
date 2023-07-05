import { Stack } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { Collection } from 'types/collection';
// import ChevronRightIcon from '@mui/icons-material/ChevronRight';

// import LinkIcon from '@mui/icons-material/Link';
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
                    <MenuItemDivider hasIcon={true} />
                    <EnteMenuItem
                        startIcon={<AddIcon />}
                        onClick={openManageShare}
                        label={t('Add Collaborators')}
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
