import { Box, Typography } from '@mui/material';

import React, { useEffect, useState } from 'react';
import { t } from 'i18next';
import { Collection } from 'types/collection';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import AvatarCollectionShare from '../AvatarCollectionShare';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import ManageAddCollab from './MangeAddCollab';
import ModeEditIcon from '@mui/icons-material/ModeEdit';

interface Iprops {
    collection: Collection;
    onRootClose: () => void;
}

export function CollaboratorParticipants({ collection, onRootClose }: Iprops) {
    if (!collection.sharees?.length) {
        return <></>;
    }

    const [collaborators, setCollaborators] = useState([]);

    useEffect(() => {
        collection.sharees?.map((sharee) => {
            if (sharee.role === 'COLLABORATOR')
                setCollaborators((prevViewers) => [
                    ...prevViewers,
                    sharee.email,
                ]);
        });
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
                            onClick={() => console.log('clicked')}
                            label={item}
                            startIcon={<AvatarCollectionShare email={item} />}
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
        </Box>
    );
}
