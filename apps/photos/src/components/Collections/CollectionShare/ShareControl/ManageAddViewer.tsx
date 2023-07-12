import { Stack, Typography } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { Collection } from 'types/collection';
import AddIcon from '@mui/icons-material/Add';
import { useState } from 'react';
import { t } from 'i18next';
import ManageAddViewerOptions from './ManageAddViewerOptions';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import Workspaces from '@mui/icons-material/Workspaces';

interface Iprops {
    collection: Collection;

    onRootClose: () => void;
}
export default function ManageAddViewer({ collection, onRootClose }: Iprops) {
    const [manageAddViewer, setManageAddViewer] = useState(false);
    const closeManageAddViewer = () => setManageAddViewer(false);
    const openManageAddViewer = () => setManageAddViewer(true);
    return (
        <>
            <Stack>
                {collection.sharees.length === 0 && (
                    <Typography color="text.muted" variant="small" padding={1}>
                        <Workspaces style={{ fontSize: 17, marginRight: 8 }} />
                        {t('SHARE_WITH_PEOPLE')}
                    </Typography>
                )}

                <MenuItemGroup>
                    <EnteMenuItem
                        startIcon={<AddIcon />}
                        onClick={openManageAddViewer}
                        label={t('ADD_VIEWERS')}
                    />
                    <MenuItemDivider hasIcon={true} />
                </MenuItemGroup>
            </Stack>
            <ManageAddViewerOptions
                open={manageAddViewer}
                onClose={closeManageAddViewer}
                onRootClose={onRootClose}
                collection={collection}
            />
        </>
    );
}
