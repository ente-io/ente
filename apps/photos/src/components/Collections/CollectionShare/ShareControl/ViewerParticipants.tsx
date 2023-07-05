import { Box } from '@mui/material';
import React from 'react';
import { t } from 'i18next';
import { Collection } from 'types/collection';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';

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

    // const [Viewers, setViewers] = useState([]);

    // useEffect(() => {
    //     collection.sharees?.map((item) => {
    //         if (item.role === 'viewer')
    //             setViewers((prevViewers) => [...prevViewers, item.email]);
    //     });
    // }, [collection.sharees]);

    // console.log(Viewers);

    return (
        <Box mb={3}>
            <MenuSectionTitle title={t('Viewers')} />
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
