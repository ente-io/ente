import React, { useRef, useState } from 'react';
import { COLLECTION_ROLE, Collection } from 'types/collection';

import { Stack } from '@mui/material';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { t } from 'i18next';
import Workspaces from '@mui/icons-material/Workspaces';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import AddIcon from '@mui/icons-material/Add';
import AddParticipant from './AddParticipant';
import ManageParticipants from './ManageParticipants';
import AvatarGroup from 'components/pages/gallery/AvatarGroup';
import ChevronRight from '@mui/icons-material/ChevronRight';

export default function EmailShare({
    collection,
    onRootClose,
}: {
    collection: Collection;
    onRootClose: () => void;
}) {
    const [addParticipantView, setAddParticipantView] = useState(false);
    const [manageParticipantView, setManageParticipantView] = useState(false);

    const closeAddParticipant = () => setAddParticipantView(false);
    const openAddParticipant = () => setAddParticipantView(true);

    const closeManageParticipant = () => setManageParticipantView(false);
    const openManageParticipant = () => setManageParticipantView(true);

    const participantType = useRef<
        COLLECTION_ROLE.COLLABORATOR | COLLECTION_ROLE.VIEWER
    >();

    const openAddCollab = () => {
        participantType.current = COLLECTION_ROLE.COLLABORATOR;
        openAddParticipant();
    };

    const openAddViewer = () => {
        participantType.current = COLLECTION_ROLE.VIEWER;
        openAddParticipant();
    };

    return (
        <>
            <Stack>
                <MenuSectionTitle
                    title={t('shared_with_people', {
                        count: collection.sharees?.length ?? 0,
                    })}
                    icon={<Workspaces />}
                />
                <MenuItemGroup>
                    {collection.sharees.length > 0 ? (
                        <>
                            <EnteMenuItem
                                fontWeight={'normal'}
                                startIcon={
                                    <AvatarGroup sharees={collection.sharees} />
                                }
                                onClick={openManageParticipant}
                                label={
                                    collection.sharees.length === 1
                                        ? t(collection.sharees[0]?.email)
                                        : null
                                }
                                endIcon={<ChevronRight />}
                            />
                            <MenuItemDivider hasIcon />
                        </>
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
            </Stack>
            <AddParticipant
                open={addParticipantView}
                onClose={closeAddParticipant}
                onRootClose={onRootClose}
                collection={collection}
                type={participantType.current}
            />
            <ManageParticipants
                peopleCount={collection.sharees.length}
                open={manageParticipantView}
                onClose={closeManageParticipant}
                onRootClose={onRootClose}
                collection={collection}
            />
        </>
    );
}
