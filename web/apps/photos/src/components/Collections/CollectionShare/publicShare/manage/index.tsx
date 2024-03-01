import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import RemoveCircleOutline from "@mui/icons-material/RemoveCircleOutline";
import { DialogProps, Stack, Typography } from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import MenuItemDivider from "components/Menu/MenuItemDivider";
import { MenuItemGroup } from "components/Menu/MenuItemGroup";
import Titlebar from "components/Titlebar";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import { useContext, useState } from "react";
import {
    deleteShareableURL,
    updateShareableURL,
} from "services/collectionService";
import { Collection, PublicURL, UpdatePublicURL } from "types/collection";
import { SetPublicShareProp } from "types/publicCollection";
import { handleSharingErrors } from "utils/error/ui";
import { ManageDeviceLimit } from "./deviceLimit";
import { ManageDownloadAccess } from "./downloadAccess";
import { ManageLinkExpiry } from "./linkExpiry";
import { ManageLinkPassword } from "./linkPassword";
import { ManagePublicCollect } from "./publicCollect";

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
    publicShareUrl: string;
}

export default function ManagePublicShareOptions({
    publicShareProp,
    collection,
    setPublicShareProp,
    open,
    onClose,
    onRootClose,
    publicShareUrl,
}: Iprops) {
    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
            onRootClose();
        } else {
            onClose();
        }
    };
    const galleryContext = useContext(GalleryContext);

    const [sharableLinkError, setSharableLinkError] = useState(null);

    const updatePublicShareURLHelper = async (req: UpdatePublicURL) => {
        try {
            galleryContext.setBlockingLoad(true);
            const response = await updateShareableURL(req);
            setPublicShareProp(response);
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };
    const disablePublicSharing = async () => {
        try {
            galleryContext.setBlockingLoad(true);
            await deleteShareableURL(collection);
            setPublicShareProp(null);
            galleryContext.syncWithRemote(false, true);
            onClose();
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };
    const copyToClipboardHelper = (text: string) => () => {
        navigator.clipboard.writeText(text);
    };
    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleDrawerClose}>
                <Stack spacing={"4px"} py={"12px"}>
                    <Titlebar
                        onClose={onClose}
                        title={t("SHARE_COLLECTION")}
                        onRootClose={onRootClose}
                    />
                    <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                        <Stack spacing={3}>
                            <ManagePublicCollect
                                collection={collection}
                                publicShareProp={publicShareProp}
                                updatePublicShareURLHelper={
                                    updatePublicShareURLHelper
                                }
                            />
                            <ManageLinkExpiry
                                collection={collection}
                                publicShareProp={publicShareProp}
                                updatePublicShareURLHelper={
                                    updatePublicShareURLHelper
                                }
                                onRootClose={onRootClose}
                            />
                            <MenuItemGroup>
                                <ManageDeviceLimit
                                    collection={collection}
                                    publicShareProp={publicShareProp}
                                    updatePublicShareURLHelper={
                                        updatePublicShareURLHelper
                                    }
                                    onRootClose={onRootClose}
                                />
                                <MenuItemDivider />
                                <ManageDownloadAccess
                                    collection={collection}
                                    publicShareProp={publicShareProp}
                                    updatePublicShareURLHelper={
                                        updatePublicShareURLHelper
                                    }
                                />
                                <MenuItemDivider />
                                <ManageLinkPassword
                                    collection={collection}
                                    publicShareProp={publicShareProp}
                                    updatePublicShareURLHelper={
                                        updatePublicShareURLHelper
                                    }
                                />
                            </MenuItemGroup>
                            <MenuItemGroup>
                                <EnteMenuItem
                                    startIcon={<ContentCopyIcon />}
                                    onClick={copyToClipboardHelper(
                                        publicShareUrl,
                                    )}
                                    label={t("COPY_LINK")}
                                />
                            </MenuItemGroup>
                            <MenuItemGroup>
                                <EnteMenuItem
                                    color="critical"
                                    startIcon={<RemoveCircleOutline />}
                                    onClick={disablePublicSharing}
                                    label={t("REMOVE_LINK")}
                                />
                            </MenuItemGroup>
                        </Stack>
                        {sharableLinkError && (
                            <Typography
                                textAlign={"center"}
                                variant="small"
                                sx={{
                                    color: (theme) => theme.colors.danger.A700,
                                    mt: 0.5,
                                }}
                            >
                                {sharableLinkError}
                            </Typography>
                        )}
                    </Stack>
                </Stack>
            </EnteDrawer>
        </>
    );
}
