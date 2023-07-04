import { Stack, Typography, styled } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { Collection, PublicURL } from 'types/collection';
import PublicIcon from '@mui/icons-material/Public';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import { SetPublicShareProp } from 'types/publicCollection';
import { useState } from 'react';
import { t } from 'i18next';
import ManageAddViewerOptions from './ManageAddViewerOptions';
// import { CollectionShareSharees } from '../sharees';
import AvatarCollectionShare from '../AvatarCollectionShare';
import ManageAddViewer from './ManageAddViewer';
import MenuItemDivider from 'components/Menu/MenuItemDivider';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
    onRootClose: () => void;
    publicShareUrl: string;
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

export default function ManageParticipants({
    publicShareProp,
    setPublicShareProp,
    collection,
    onRootClose,
    publicShareUrl,
}: Iprops) {
    const [manageAddViewer, setManageAddViewer] = useState(false);
    const closeManageAddViewer = () => setManageAddViewer(false);
    const openManageAddViewer = () => setManageAddViewer(true);
    const peopleCount = collection.sharees.length;
    // console.log('Lenght for sharee list', collection.sharees[0].email);
    return (
        <>
            <Stack>
                <Typography color="text.muted" variant="small" padding={1}>
                    <PublicIcon style={{ fontSize: 17, marginRight: 8 }} />
                    {t(`Shared with ${peopleCount}  people`)}
                </Typography>
                <MenuItemGroup>
                    <EnteMenuItem
                        startIcon={
                            <AvatarContainerOuter>
                                {collection.sharees?.map((sharee) => (
                                    <AvatarContainer key={sharee.email}>
                                        <AvatarCollectionShare
                                            key={sharee.email}
                                            email={sharee.email}
                                        />
                                    </AvatarContainer>
                                ))}
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
                </MenuItemGroup>
                <MenuItemDivider />
                <ManageAddViewer
                    publicShareProp={publicShareProp}
                    setPublicShareProp={setPublicShareProp}
                    collection={collection}
                    publicShareUrl={publicShareUrl}
                    onRootClose={onRootClose}
                />
            </Stack>
            {/* <CollectionShareSharees collection={collection} /> */}
            <ManageAddViewerOptions
                open={manageAddViewer}
                onClose={closeManageAddViewer}
                onRootClose={onRootClose}
                publicShareProp={publicShareProp}
                collection={collection}
                setPublicShareProp={setPublicShareProp}
                publicShareUrl={publicShareUrl}
            />
        </>
    );
}
