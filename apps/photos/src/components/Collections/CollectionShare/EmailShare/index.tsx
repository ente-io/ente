import React, { useState } from 'react';
import { Collection } from 'types/collection';

import ManageParticipants from './ManageParticipants';
import { Stack } from '@mui/material';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { t } from 'i18next';
import Workspaces from '@mui/icons-material/Workspaces';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import AddIcon from '@mui/icons-material/Add';
import AddViewer from './AddViewer';
import AddCollab from './AddCollab';

export default function EmailShare({
    collection,
    onRootClose,
}: {
    collection: Collection;
    onRootClose: () => void;
}) {
    const [addViewerView, setAddViewerView] = useState(false);
    const [addCollabView, setAddCollabView] = useState(false);

    const closeAddViewer = () => setAddViewerView(false);
    const openAddViewer = () => setAddViewerView(true);

    const closeAddCollab = () => setAddCollabView(false);
    const openAddCollab = () => setAddCollabView(true);

    return (
        <Stack>
            <MenuSectionTitle
                title={t('SHARE_WITH_PEOPLE')}
                icon={<Workspaces />}
            />
            <MenuItemGroup>
                {collection.sharees.length > 0 ? (
                    <ManageParticipants
                        collection={collection}
                        onRootClose={onRootClose}
                    />
                ) : null}
                <EnteMenuItem
                    startIcon={<AddIcon />}
                    onClick={openAddViewer}
                    label={t('ADD_VIEWERS')}
                />
                <MenuItemDivider hasIcon />
                <EnteMenuItem
                    startIcon={<AddIcon />}
                    onClick={openAddCollab}
                    label={t('ADD_COLLABORATORS')}
                />
            </MenuItemGroup>
            <AddViewer
                open={addViewerView}
                onClose={closeAddCollab}
                onRootClose={onRootClose}
                collection={collection}
            />
            <AddCollab
                open={addCollabView}
                onClose={closeAddViewer}
                onRootClose={onRootClose}
                collection={collection}
            />
        </Stack>
    );
}
