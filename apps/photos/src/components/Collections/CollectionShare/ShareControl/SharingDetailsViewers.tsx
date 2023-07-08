import { Box, Stack, Typography } from '@mui/material';
import React, { useEffect, useState } from 'react';
import { t } from 'i18next';
import { Collection } from 'types/collection';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import AvatarCollectionShare from '../AvatarCollectionShare';

import PhotoIcon from '@mui/icons-material/Photo';
import { LS_KEYS, getData } from 'utils/storage/localStorage';
import { User } from 'types/user';

interface Iprops {
    collection: Collection;
}

export function SharingDetailsViewers({ collection }: Iprops) {
    if (!collection.sharees?.length) {
        return <></>;
    }

    const [Viewers, setViewers] = useState([]);

    useEffect(() => {
        const viewersEmails =
            collection.sharees
                ?.filter((sharee) => sharee.role === 'VIEWER')
                .map((sharee) => sharee.email) || [];
        setViewers(viewersEmails);
    }, [collection.sharees]);

    if (!Viewers.length) {
        return <></>;
    }
    const user: User = getData(LS_KEYS.USER);

    return (
        <>
            <Stack>
                <Box mb={3}>
                    <Typography color="text.muted" variant="small" padding={1}>
                        <PhotoIcon style={{ fontSize: 20, marginRight: 8 }} />
                        {t('Viewers')}
                    </Typography>

                    <MenuItemGroup>
                        <>
                            {Viewers.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        fontWeight="normal"
                                        key={item}
                                        onClick={() =>
                                            console.log('click', item)
                                        }
                                        label={
                                            user.email === item ? 'You' : item
                                        }
                                        startIcon={
                                            <AvatarCollectionShare
                                                email={item}
                                            />
                                        }
                                    />
                                    {index !== Viewers.length - 1 && (
                                        <MenuItemDivider />
                                    )}
                                </>
                            ))}
                        </>
                    </MenuItemGroup>
                </Box>
            </Stack>
        </>
    );
}
