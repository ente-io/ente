import { Box, Typography } from '@mui/material';
import React from 'react';
import { t } from 'i18next';
import { Collection } from 'types/collection';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import Avatar from 'components/pages/gallery/Avatar';
import { User } from 'types/user';
import { LS_KEYS, getData } from 'utils/storage/localStorage';

import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';
interface Iprops {
    collection: Collection;
}

export function OwnerParticipant({ collection }: Iprops) {
    if (!collection.sharees?.length) {
        return <></>;
    }
    const user: User = getData(LS_KEYS.USER);

    const ownerEmail =
        user.id === collection.owner?.id ? t('YOU') : collection.owner?.email;

    return (
        <Box mb={3}>
            <Typography color="text.muted" variant="small" padding={1}>
                <AdminPanelSettingsIcon
                    style={{ fontSize: 20, marginRight: 8 }}
                />
                {t('OWNER')}
            </Typography>

            <MenuItemGroup>
                <>
                    <EnteMenuItem
                        //
                        fontWeight="normal"
                        onClick={() => console.log('clicked', ownerEmail)}
                        label={ownerEmail}
                        startIcon={
                            <Avatar
                                email={
                                    user.id === collection.owner?.id
                                        ? user.email
                                        : collection.owner?.email
                                }
                            />
                        }
                    />
                </>
            </MenuItemGroup>
        </Box>
    );
}
