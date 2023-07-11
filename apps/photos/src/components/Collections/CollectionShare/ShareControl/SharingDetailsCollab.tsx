import { Box, Typography } from '@mui/material';
import React, { useEffect, useState } from 'react';
import { t } from 'i18next';
import { Collection } from 'types/collection';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import AvatarCollectionShare from '../AvatarCollectionShare';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import ModeEditIcon from '@mui/icons-material/ModeEdit';
import { LS_KEYS, getData } from 'utils/storage/localStorage';
import { User } from 'types/user';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';

interface Iprops {
    collection: Collection;
}

export function ShareDetailsCollab({ collection }: Iprops) {
    if (!collection.sharees?.length) {
        return <></>;
    }

    const [collaborators, setCollaborators] = useState([]);

    useEffect(() => {
        const collaboratorEmails =
            collection.sharees
                ?.filter((sharee) => sharee.role === 'COLLABORATOR')
                .map((sharee) => sharee.email) || [];
        setCollaborators(collaboratorEmails);
    }, [collection.sharees]);

    if (!collaborators.length) {
        return <></>;
    }
    const user: User = getData(LS_KEYS.USER);

    return (
        <Box mb={3}>
            <Typography color="text.muted" variant="small" padding={1}>
                <ModeEditIcon style={{ fontSize: 20, marginRight: 8 }} />
                {t('COLLABORATORS')}
            </Typography>

            <MenuItemGroup>
                {collaborators.map((item, index) => (
                    <>
                        <EnteMenuItem
                            fontWeight="normal"
                            key={item}
                            onClick={() => console.log('collaborator')}
                            label={user.email === item ? 'You' : item}
                            startIcon={<AvatarCollectionShare email={item} />}
                        />
                        {index !== collaborators.length - 1 && (
                            <MenuItemDivider />
                        )}
                    </>
                ))}
            </MenuItemGroup>
            <MenuSectionTitle title={t('COLLABORATOR_RIGHTS')} />
        </Box>
    );
}
