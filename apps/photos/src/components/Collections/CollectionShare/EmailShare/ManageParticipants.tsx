import { Stack, Typography, styled } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { Collection } from 'types/collection';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import { useState } from 'react';
import { t } from 'i18next';
import Avatar from 'components/pages/gallery/Avatar';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import NumberAvatar from '@mui/material/Avatar';
import ManageParticipantsOptions from './ManageParticipantsOptions';
import Workspaces from '@mui/icons-material/Workspaces';

interface Iprops {
    collection: Collection;
    onRootClose: () => void;
}

const AvatarContainer = styled('div')({
    position: 'relative',
    display: 'flex',
    alignItems: 'center',
    marginLeft: -5,
});

const AvatarContainerOuter = styled('div')({
    position: 'relative',
    display: 'flex',
    alignItems: 'center',
    marginLeft: 8,
});
const AvatarCounter = styled(NumberAvatar)({
    height: 20,
    width: 20,
    fontSize: 10,
    color: '#fff',
});

export default function ManageParticipants({
    collection,
    onRootClose,
}: Iprops) {
    const [manageAddViewer, setManageAddViewer] = useState(false);
    const closeManageAddViewer = () => setManageAddViewer(false);
    const openManageAddViewer = () => setManageAddViewer(true);
    const peopleCount = collection.sharees.length;

    const shareeCount = collection.sharees?.length || 0;
    const extraShareeCount = Math.max(0, shareeCount - 6);
    return (
        <>
            <Stack>
                <Typography color="text.muted" variant="small" padding={1}>
                    <Workspaces style={{ fontSize: 17, marginRight: 8 }} />
                    {t(`Shared with ${peopleCount}  people`)}
                </Typography>
                <MenuItemGroup>
                    <EnteMenuItem
                        startIcon={
                            <AvatarContainerOuter>
                                {collection.sharees
                                    ?.slice(0, 6)
                                    .map((sharee) => (
                                        <AvatarContainer key={sharee.email}>
                                            <Avatar
                                                key={sharee.email}
                                                email={sharee.email}
                                            />
                                        </AvatarContainer>
                                    ))}
                                {extraShareeCount > 0 && (
                                    <AvatarContainer key="extra-count">
                                        <AvatarCounter>
                                            +{extraShareeCount}
                                        </AvatarCounter>
                                    </AvatarContainer>
                                )}
                            </AvatarContainerOuter>
                        }
                        onClick={openManageAddViewer}
                        label={
                            collection.sharees.length === 1
                                ? t(collection.sharees[0]?.email)
                                : null
                        }
                        endIcon={<ChevronRightIcon />}
                    />
                    <MenuItemDivider hasIcon={true} />
                </MenuItemGroup>
            </Stack>

            <ManageParticipantsOptions
                peopleCount={peopleCount}
                open={manageAddViewer}
                onClose={closeManageAddViewer}
                onRootClose={onRootClose}
                collection={collection}
            />
        </>
    );
}
