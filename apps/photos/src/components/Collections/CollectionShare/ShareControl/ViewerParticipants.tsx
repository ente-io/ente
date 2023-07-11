import { Box, Stack, Typography } from '@mui/material';
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
import ManageParticipantsRole from './ManageParticipantsRole';

interface Iprops {
    collection: Collection;
    onRootClose: () => void;
    collectionUnshare: (email: string) => Promise<void>;
}

export function ViewerParticipants({
    collection,
    onRootClose,
    collectionUnshare,
}: Iprops) {
    if (!collection.sharees?.length) {
        return <></>;
    }

    const [Viewers, setViewers] = useState([]);
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
        const viewersEmails =
            collection.sharees
                ?.filter((sharee) => sharee.role === 'VIEWER')
                .map((sharee) => sharee.email) || [];
        setViewers(viewersEmails);
    }, [collection.sharees]);

    return (
        <>
            <Stack>
                <Box mb={3}>
                    <Typography color="text.muted" variant="small" padding={1}>
                        <PhotoIcon style={{ fontSize: 20, marginRight: 8 }} />
                        {t('VIEWERS')}
                    </Typography>
                    <MenuItemGroup>
                        <>
                            {Viewers.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        fontWeight="normal"
                                        key={item}
                                        onClick={() =>
                                            openParticipantRoleView(item)
                                        }
                                        label={item}
                                        startIcon={
                                            <AvatarCollectionShare
                                                email={item}
                                            />
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
            </Stack>
            <ManageParticipantsRole
                collectionUnshare={collectionUnshare}
                open={participantRoleView}
                collection={collection}
                onRootClose={onRootClose}
                onClose={closeParticipantRoleView}
                selectedEmail={selectedEmail} // Pass the selected email to ManageParticipantsRole
            />
        </>
    );
}
