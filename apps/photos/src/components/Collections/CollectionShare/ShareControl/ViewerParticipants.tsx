import { Box } from '@mui/material';
import React, { useEffect, useState } from 'react';
import { t } from 'i18next';
import { Collection } from 'types/collection';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import AvatarCollectionShare from '../AvatarCollectionShare';

interface Iprops {
    collection: Collection;
}

export function ViewerParticipants({ collection }: Iprops) {
    if (!collection.sharees?.length) {
        return <></>;
    }
    const shareExpireOption = [
        'Never',
        '1 day',
        '1 week',
        '1 month',
        '1 year',
        'Custom',
    ];

    const [Viewers, setViewers] = useState([]);

    useEffect(() => {
        collection.sharees?.map((sharee) => {
            if (sharee.role === 'VIEWER')
                setViewers((prevViewers) => [...prevViewers, sharee.email]);
        });
    }, [collection.sharees]);

    return (
        <Box mb={3}>
            <MenuSectionTitle title={t('Viewers')} />
            <MenuItemGroup>
                {Viewers.map((item, index) => (
                    <>
                        <EnteMenuItem
                            fontWeight="normal"
                            key={item}
                            onClick={() => console.log('clicked')}
                            label={item}
                            startIcon={<AvatarCollectionShare email={item} />}
                        />
                        {index !== shareExpireOption.length - 1 && (
                            <MenuItemDivider />
                        )}
                    </>
                ))}
            </MenuItemGroup>
        </Box>
    );
}
