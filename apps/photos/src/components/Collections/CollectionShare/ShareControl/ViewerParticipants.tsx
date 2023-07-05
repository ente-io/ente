import { Box, Typography } from '@mui/material';
import React, { useEffect, useState } from 'react';
import { t } from 'i18next';
import { Collection } from 'types/collection';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import AvatarCollectionShare from '../AvatarCollectionShare';
import ManageAddViewer from './ManageAddViewer';
import PhotoIcon from '@mui/icons-material/Photo';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';

interface Iprops {
    collection: Collection;
    onRootClose: () => void;
}

export function ViewerParticipants({ collection, onRootClose }: Iprops) {
    if (!collection.sharees?.length) {
        return <></>;
    }

    const [Viewers, setViewers] = useState([]);
    // const [participantRoleView, setParticipantRoleView] = useState(false);

    useEffect(() => {
        collection.sharees?.map((sharee) => {
            if (sharee.role === 'VIEWER')
                setViewers((prevViewers) => [...prevViewers, sharee.email]);
        });
    }, [collection.sharees]);

    return (
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
                                onClick={() => console.log('clicked')}
                                label={item}
                                startIcon={
                                    <AvatarCollectionShare email={item} />
                                }
                                endIcon={<ChevronRightIcon />}
                            />
                            {index !== Viewers.length - 1 && (
                                <MenuItemDivider />
                            )}
                        </>
                    ))}
                    <ManageAddViewer
                        collection={collection}
                        onRootClose={onRootClose}
                    />
                </>
            </MenuItemGroup>
        </Box>
    );
}
