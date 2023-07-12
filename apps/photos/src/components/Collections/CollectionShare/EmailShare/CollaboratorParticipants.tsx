import { Box, Typography } from '@mui/material';

import React, { useEffect, useState } from 'react';
import { t } from 'i18next';
import { Collection } from 'types/collection';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import Avatar from 'components/pages/gallery/Avatar';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import ManageAddCollab from './MangeAddCollab';
import ModeEditIcon from '@mui/icons-material/ModeEdit';
import ManageParticipantsRole from './ManageParticipantsRole';

interface Iprops {
    collection: Collection;
    onRootClose: () => void;
    collectionUnshare: (email: string) => Promise<void>;
}

export function CollaboratorParticipants({
    collection,
    onRootClose,
    collectionUnshare,
}: Iprops) {
    if (!collection.sharees?.length) {
        return <></>;
    }

    const [collaborators, setCollaborators] = useState([]);
    const [participantRoleView, setParticipantRoleView] = useState(false);
    const [selectedEmail, setSelectedEmail] = useState('');

    const openParticipantRoleView = (email) => {
        setParticipantRoleView(true);
        setSelectedEmail(email);
    };
    const closeParticipantRoleView = () => {
        setParticipantRoleView(false);
    };

    useEffect(() => {
        const collaboratorEmails =
            collection.sharees
                ?.filter((sharee) => sharee.role === 'COLLABORATOR')
                .map((sharee) => sharee.email) || [];
        setCollaborators(collaboratorEmails);
    }, [collection.sharees]);

    return (
        <Box mb={3}>
            <Typography color="text.muted" variant="small" padding={1}>
                <ModeEditIcon style={{ fontSize: 20, marginRight: 8 }} />
                {t('Collaborators')}
            </Typography>

            <MenuItemGroup>
                {collaborators.map((item, index) => (
                    <>
                        <EnteMenuItem
                            fontWeight="normal"
                            key={item}
                            onClick={() => openParticipantRoleView(item)}
                            label={item}
                            startIcon={<Avatar email={item} />}
                            endIcon={<ChevronRightIcon />}
                        />
                        {index !== collaborators.length - 1 && (
                            <MenuItemDivider />
                        )}
                    </>
                ))}
                <ManageAddCollab
                    collection={collection}
                    onRootClose={onRootClose}
                />
            </MenuItemGroup>
            <ManageParticipantsRole
                collectionUnshare={collectionUnshare}
                open={participantRoleView}
                collection={collection}
                onRootClose={onRootClose}
                onClose={closeParticipantRoleView}
                selectedEmail={selectedEmail} // Pass the selected email to ManageParticipantsRole
            />
        </Box>
    );
}
