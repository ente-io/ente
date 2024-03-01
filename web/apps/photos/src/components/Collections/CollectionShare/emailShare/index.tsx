import { useRef, useState } from "react";
import { COLLECTION_ROLE, Collection } from "types/collection";

import AddIcon from "@mui/icons-material/Add";
import ChevronRight from "@mui/icons-material/ChevronRight";
import Workspaces from "@mui/icons-material/Workspaces";
import { Stack } from "@mui/material";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import MenuItemDivider from "components/Menu/MenuItemDivider";
import { MenuItemGroup } from "components/Menu/MenuItemGroup";
import MenuSectionTitle from "components/Menu/MenuSectionTitle";
import AvatarGroup from "components/pages/gallery/AvatarGroup";
import { t } from "i18next";
import AddParticipant from "./AddParticipant";
import ManageEmailShare from "./ManageEmailShare";

export default function EmailShare({
    collection,
    onRootClose,
}: {
    collection: Collection;
    onRootClose: () => void;
}) {
    const [addParticipantView, setAddParticipantView] = useState(false);
    const [manageEmailShareView, setManageEmailShareView] = useState(false);

    const closeAddParticipant = () => setAddParticipantView(false);
    const openAddParticipant = () => setAddParticipantView(true);

    const closeManageEmailShare = () => setManageEmailShareView(false);
    const openManageEmailShare = () => setManageEmailShareView(true);

    const participantType = useRef<
        COLLECTION_ROLE.COLLABORATOR | COLLECTION_ROLE.VIEWER
    >();

    const openAddCollab = () => {
        participantType.current = COLLECTION_ROLE.COLLABORATOR;
        openAddParticipant();
    };

    const openAddViewer = () => {
        participantType.current = COLLECTION_ROLE.VIEWER;
        openAddParticipant();
    };

    return (
        <>
            <Stack>
                <MenuSectionTitle
                    title={t("shared_with_people", {
                        count: collection.sharees?.length ?? 0,
                    })}
                    icon={<Workspaces />}
                />
                <MenuItemGroup>
                    {collection.sharees.length > 0 ? (
                        <>
                            <EnteMenuItem
                                fontWeight={"normal"}
                                startIcon={
                                    <AvatarGroup sharees={collection.sharees} />
                                }
                                onClick={openManageEmailShare}
                                label={
                                    collection.sharees.length === 1
                                        ? t(collection.sharees[0]?.email)
                                        : null
                                }
                                endIcon={<ChevronRight />}
                            />
                            <MenuItemDivider hasIcon />
                        </>
                    ) : null}
                    <EnteMenuItem
                        startIcon={<AddIcon />}
                        onClick={openAddViewer}
                        label={t("ADD_VIEWERS")}
                    />
                    <MenuItemDivider hasIcon />
                    <EnteMenuItem
                        startIcon={<AddIcon />}
                        onClick={openAddCollab}
                        label={t("ADD_COLLABORATORS")}
                    />
                </MenuItemGroup>
            </Stack>
            <AddParticipant
                open={addParticipantView}
                onClose={closeAddParticipant}
                onRootClose={onRootClose}
                collection={collection}
                type={participantType.current}
            />
            <ManageEmailShare
                peopleCount={collection.sharees.length}
                open={manageEmailShareView}
                onClose={closeManageEmailShare}
                onRootClose={onRootClose}
                collection={collection}
            />
        </>
    );
}
