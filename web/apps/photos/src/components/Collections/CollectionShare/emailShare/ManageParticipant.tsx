import { MenuItemDivider, MenuItemGroup } from "@/base/components/Menu";
import { SidebarDrawer } from "@/base/components/mui/SidebarDrawer";
import { Titlebar } from "@/base/components/Titlebar";
import log from "@/base/log";
import type { Collection, CollectionUser } from "@/media/collection";
import { AppContext } from "@/new/photos/types/context";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import BlockIcon from "@mui/icons-material/Block";
import DoneIcon from "@mui/icons-material/Done";
import ModeEditIcon from "@mui/icons-material/ModeEdit";
import PhotoIcon from "@mui/icons-material/Photo";
import { DialogProps, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import { useContext } from "react";
import { Trans } from "react-i18next";
import { shareCollection } from "services/collectionService";
import { handleSharingErrors } from "utils/error/ui";

interface Iprops {
    open: boolean;
    collection: Collection;
    onClose: () => void;
    onRootClose: () => void;
    selectedParticipant: CollectionUser;
    collectionUnshare: (email: string) => Promise<void>;
}

export default function ManageParticipant({
    collection,
    open,
    onClose,
    onRootClose,
    selectedParticipant,
    collectionUnshare,
}: Iprops) {
    const galleryContext = useContext(GalleryContext);
    const appContext = useContext(AppContext);

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
            onRootClose();
        } else {
            onClose();
        }
    };

    const handleClick = () => {
        collectionUnshare(selectedParticipant.email);
        onClose();
    };

    const handleRoleChange = (role: string) => () => {
        if (role !== selectedParticipant.role) {
            changeRolePermission(selectedParticipant.email, role);
        }
    };

    const updateCollectionRole = async (selectedEmail, newRole) => {
        try {
            await shareCollection(collection, selectedEmail, newRole);
            selectedParticipant.role = newRole;
            await galleryContext.syncWithRemote(false, true);
        } catch (e) {
            log.error(handleSharingErrors(e), e);
        }
    };

    const changeRolePermission = (selectedEmail, newRole) => {
        let contentText;
        let buttonText;

        if (newRole === "VIEWER") {
            contentText = (
                <Trans
                    i18nKey="CHANGE_PERMISSIONS_TO_VIEWER"
                    values={{
                        selectedEmail: `${selectedEmail}`,
                    }}
                />
            );

            buttonText = t("CONVERT_TO_VIEWER");
        } else if (newRole === "COLLABORATOR") {
            contentText = t("CHANGE_PERMISSIONS_TO_COLLABORATOR", {
                selectedEmail: selectedEmail,
            });
            buttonText = t("CONVERT_TO_COLLABORATOR");
        }

        appContext.setDialogMessage({
            title: t("CHANGE_PERMISSION"),
            content: contentText,
            close: { text: t("cancel") },
            proceed: {
                text: buttonText,
                action: () => {
                    updateCollectionRole(selectedEmail, newRole);
                },
                variant: "critical",
            },
        });
    };

    const removeParticipant = () => {
        appContext.setDialogMessage({
            title: t("REMOVE_PARTICIPANT"),
            content: (
                <Trans
                    i18nKey="REMOVE_PARTICIPANT_MESSAGE"
                    values={{
                        selectedEmail: `${selectedParticipant.email}`,
                    }}
                />
            ),
            close: { text: t("cancel") },
            proceed: {
                text: t("CONFIRM_REMOVE"),
                action: () => {
                    handleClick();
                },
                variant: "critical",
            },
        });
    };

    if (!selectedParticipant) {
        return <></>;
    }

    return (
        <SidebarDrawer anchor="right" open={open} onClose={handleDrawerClose}>
            <Stack spacing={"4px"} py={"12px"}>
                <Titlebar
                    onClose={onClose}
                    title={t("MANAGE")}
                    onRootClose={onRootClose}
                    caption={selectedParticipant.email}
                />

                <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                    <Stack>
                        <Typography
                            color="text.muted"
                            variant="small"
                            padding={1}
                        >
                            {t("ADDED_AS")}
                        </Typography>

                        <MenuItemGroup>
                            <EnteMenuItem
                                fontWeight="normal"
                                onClick={handleRoleChange("COLLABORATOR")}
                                label={"Collaborator"}
                                startIcon={<ModeEditIcon />}
                                endIcon={
                                    selectedParticipant.role ===
                                        "COLLABORATOR" && <DoneIcon />
                                }
                            />
                            <MenuItemDivider hasIcon />

                            <EnteMenuItem
                                fontWeight="normal"
                                onClick={handleRoleChange("VIEWER")}
                                label={"Viewer"}
                                startIcon={<PhotoIcon />}
                                endIcon={
                                    selectedParticipant.role === "VIEWER" && (
                                        <DoneIcon />
                                    )
                                }
                            />
                        </MenuItemGroup>

                        <Typography
                            color="text.muted"
                            variant="small"
                            padding={1}
                        >
                            {t("COLLABORATOR_RIGHTS")}
                        </Typography>

                        <Stack py={"30px"}>
                            <Typography
                                color="text.muted"
                                variant="small"
                                padding={1}
                            >
                                {t("REMOVE_PARTICIPANT_HEAD")}
                            </Typography>

                            <MenuItemGroup>
                                <EnteMenuItem
                                    color="critical"
                                    fontWeight="normal"
                                    onClick={removeParticipant}
                                    label={"Remove"}
                                    startIcon={<BlockIcon />}
                                />
                            </MenuItemGroup>
                        </Stack>
                    </Stack>
                </Stack>
            </Stack>
        </SidebarDrawer>
    );
}
