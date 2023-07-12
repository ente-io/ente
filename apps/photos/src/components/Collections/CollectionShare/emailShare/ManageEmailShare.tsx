import { Stack } from '@mui/material';
import { COLLECTION_ROLE, Collection } from 'types/collection';
import { EnteDrawer } from 'components/EnteDrawer';
import { t } from 'i18next';
import { DialogProps } from '@mui/material';
import Titlebar from 'components/Titlebar';
import { useContext, useState } from 'react';
import { AppContext } from 'pages/_app';
import { GalleryContext } from 'pages/gallery';
import { unshareCollection } from 'services/collectionService';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import Avatar from 'components/pages/gallery/Avatar';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';
import ModeEditIcon from '@mui/icons-material/ModeEdit';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import ManageParticipant from './ManageParticipant';
import AddParticipant from './AddParticipant';
import { useRef } from 'react';
import Add from '@mui/icons-material/Add';
import Photo from '@mui/icons-material/Photo';

interface Iprops {
    collection: Collection;
    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
    peopleCount: number;
}

export default function ManageEmailShare({
    open,
    collection,
    onClose,
    onRootClose,
    peopleCount,
}: Iprops) {
    const appContext = useContext(AppContext);
    const galleryContext = useContext(GalleryContext);

    const [addParticipantView, setAddParticipantView] = useState(false);
    const [manageParticipantView, setManageParticipantView] = useState(false);

    const closeAddParticipant = () => setAddParticipantView(false);
    const openAddParticipant = () => setAddParticipantView(true);

    const participantType = useRef<
        COLLECTION_ROLE.COLLABORATOR | COLLECTION_ROLE.VIEWER
    >();

    const selectedParticipant = useRef<string>();

    const openAddCollab = () => {
        participantType.current = COLLECTION_ROLE.COLLABORATOR;
        openAddParticipant();
    };

    const openAddViewer = () => {
        participantType.current = COLLECTION_ROLE.VIEWER;
        openAddParticipant();
    };

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };
    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            handleRootClose();
        } else {
            onClose();
        }
    };

    const collectionUnshare = async (email: string) => {
        try {
            appContext.startLoading();
            await unshareCollection(collection, email);
            await galleryContext.syncWithRemote(false, true);
        } finally {
            appContext.finishLoading();
        }
    };

    const ownerEmail =
        galleryContext.user.id === collection.owner?.id
            ? galleryContext.user.email
            : collection.owner?.email;

    const isOwner = galleryContext.user.id === collection.owner?.id;

    const collaborators = collection.sharees
        ?.filter((sharee) => sharee.role === COLLECTION_ROLE.COLLABORATOR)
        .map((sharee) => sharee.email);

    const viewers =
        collection.sharees
            ?.filter((sharee) => sharee.role === COLLECTION_ROLE.VIEWER)
            .map((sharee) => sharee.email) || [];

    const openManageParticipant = (email) => {
        selectedParticipant.current = email;
        setManageParticipantView(true);
    };
    const closeManageParticipant = () => {
        setManageParticipantView(false);
    };

    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleDrawerClose}>
                <Stack spacing={'4px'} py={'12px'}>
                    <Titlebar
                        onClose={onClose}
                        title={collection.name}
                        onRootClose={handleRootClose}
                        caption={t('participants', {
                            count: peopleCount,
                        })}
                    />
                    <Stack py={'20px'} px={'12px'} spacing={'24px'}>
                        <Stack>
                            <MenuSectionTitle
                                title={t('OWNER')}
                                icon={<AdminPanelSettingsIcon />}
                            />
                            <MenuItemGroup>
                                <EnteMenuItem
                                    fontWeight="normal"
                                    onClick={() => {}}
                                    label={isOwner ? t('YOU') : ownerEmail}
                                    startIcon={<Avatar email={ownerEmail} />}
                                />
                            </MenuItemGroup>
                        </Stack>
                        <Stack>
                            <MenuSectionTitle
                                title={t('COLLABORATORS')}
                                icon={<ModeEditIcon />}
                            />
                            <MenuItemGroup>
                                {collaborators.map((item) => (
                                    <>
                                        <EnteMenuItem
                                            fontWeight={'normal'}
                                            key={item}
                                            onClick={() =>
                                                openManageParticipant(item)
                                            }
                                            label={item}
                                            startIcon={<Avatar email={item} />}
                                            endIcon={<ChevronRightIcon />}
                                        />
                                        <MenuItemDivider hasIcon />
                                    </>
                                ))}

                                <EnteMenuItem
                                    startIcon={<Add />}
                                    onClick={openAddCollab}
                                    label={
                                        collaborators?.length
                                            ? t('ADD_MORE')
                                            : t('ADD_COLLABORATORS')
                                    }
                                />
                            </MenuItemGroup>
                        </Stack>
                        <Stack>
                            <MenuSectionTitle
                                title={t('VIEWERS')}
                                icon={<Photo />}
                            />
                            <MenuItemGroup>
                                {viewers.map((item) => (
                                    <>
                                        <EnteMenuItem
                                            fontWeight={'normal'}
                                            key={item}
                                            onClick={() =>
                                                openManageParticipant(item)
                                            }
                                            label={item}
                                            startIcon={<Avatar email={item} />}
                                            endIcon={<ChevronRightIcon />}
                                        />

                                        <MenuItemDivider hasIcon />
                                    </>
                                ))}
                                <EnteMenuItem
                                    startIcon={<Add />}
                                    fontWeight={'bold'}
                                    onClick={openAddViewer}
                                    label={
                                        viewers?.length
                                            ? t('ADD_MORE')
                                            : t('ADD_VIEWERS')
                                    }
                                />
                            </MenuItemGroup>
                        </Stack>
                    </Stack>
                </Stack>
            </EnteDrawer>
            <ManageParticipant
                collectionUnshare={collectionUnshare}
                open={manageParticipantView}
                collection={collection}
                onRootClose={onRootClose}
                onClose={closeManageParticipant}
                selectedEmail={selectedParticipant.current}
            />
            <AddParticipant
                open={addParticipantView}
                onClose={closeAddParticipant}
                onRootClose={onRootClose}
                collection={collection}
                type={participantType.current}
            />
        </>
    );
}
