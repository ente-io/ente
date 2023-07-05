import { Box } from '@mui/material';

import React from 'react';
import { t } from 'i18next';
import { Collection } from 'types/collection';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
// import AvatarCollectionShare from '../AvatarCollectionShare';
// import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import MenuItemDivider from 'components/Menu/MenuItemDivider';

interface Iprops {
    collection: Collection;
}

export function CollaboratorParticipants({ collection }: Iprops) {
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

    return (
        <Box mb={3}>
            <MenuSectionTitle title={t('Collaborators')} />
            <MenuItemGroup>
                {shareExpireOption.map((item, index) => (
                    <>
                        <EnteMenuItem
                            fontWeight="normal"
                            key={item}
                            onClick={() => console.log('clicked')}
                            label={item}
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
