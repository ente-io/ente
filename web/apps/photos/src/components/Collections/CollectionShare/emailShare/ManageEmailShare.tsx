import Add from "@mui/icons-material/Add";
import AdminPanelSettingsIcon from "@mui/icons-material/AdminPanelSettings";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import ModeEditIcon from "@mui/icons-material/ModeEdit";
import Photo from "@mui/icons-material/Photo";
import { DialogProps, Stack } from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import MenuItemDivider from "components/Menu/MenuItemDivider";
import { MenuItemGroup } from "components/Menu/MenuItemGroup";
import MenuSectionTitle from "components/Menu/MenuSectionTitle";
import Titlebar from "components/Titlebar";
import Avatar from "components/pages/gallery/Avatar";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import { useContext, useRef, useState } from "react";
import { unshareCollection } from "services/collectionService";
import { COLLECTION_ROLE, Collection, CollectionUser } from "types/collection";
import AddParticipant from "./AddParticipant";
import ManageParticipant from "./ManageParticipant";

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

    const selectedParticipant = useRef<CollectionUser>();

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
    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
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
        selectedParticipant.current = collection.sharees.find(
            (sharee) => sharee.email === email,
        );
        setManageParticipantView(true);
    };
    const closeManageParticipant = () => {
        setManageParticipantView(false);
    };

    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleDrawerClose}>
                <Stack spacing={"4px"} py={"12px"}>
                    <Titlebar
                        onClose={onClose}
                        title={collection.name}
                        onRootClose={handleRootClose}
                        caption={t("participants", {
                            count: peopleCount,
                        })}
                    />
                    <Stack py={"20px"} px={"12px"} spacing={"24px"}>
                        <Stack>
                            <MenuSectionTitle
                                title={t("OWNER")}
                                icon={<AdminPanelSettingsIcon />}
                            />
                            <MenuItemGroup>
                                <EnteMenuItem
                                    fontWeight="normal"
                                    onClick={() => {}}
                                    label={isOwner ? t("YOU") : ownerEmail}
                                    startIcon={<Avatar email={ownerEmail} />}
                                />
                            </MenuItemGroup>
                        </Stack>
                        <Stack>
                            <MenuSectionTitle
                                title={t("COLLABORATORS")}
                                icon={<ModeEditIcon />}
                            />
                            <MenuItemGroup>
                                {collaborators.map((item) => (
                                    <>
                                        <EnteMenuItem
                                            fontWeight={"normal"}
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
                                            ? t("ADD_MORE")
                                            : t("ADD_COLLABORATORS")
                                    }
                                />
                            </MenuItemGroup>
                        </Stack>
                        <Stack>
                            <MenuSectionTitle
                                title={t("VIEWERS")}
                                icon={<Photo />}
                            />
                            <MenuItemGroup>
                                {viewers.map((item) => (
                                    <>
                                        <EnteMenuItem
                                            fontWeight={"normal"}
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
                                    fontWeight={"bold"}
                                    onClick={openAddViewer}
                                    label={
                                        viewers?.length
                                            ? t("ADD_MORE")
                                            : t("ADD_VIEWERS")
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
                selectedParticipant={selectedParticipant.current}
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
