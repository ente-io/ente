import {
    MenuItemDivider,
    MenuItemGroup,
    MenuSectionTitle,
} from "@/base/components/Menu";
import { SidebarDrawer } from "@/base/components/mui/SidebarDrawer";
import { Titlebar } from "@/base/components/Titlebar";
import { useModalVisibility } from "@/base/components/utils/modal";
import type {
    Collection,
    PublicURL,
    UpdatePublicURL,
} from "@/media/collection";
import { PublicLinkCreated } from "@/new/photos/components/share/PublicLinkCreated";
import type { CollectionSummary } from "@/new/photos/services/collection/ui";
import { useAppContext } from "@/new/photos/types/context";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import {
    default as ChevronRight,
    default as ChevronRightIcon,
} from "@mui/icons-material/ChevronRight";
import ContentCopyIcon from "@mui/icons-material/ContentCopyOutlined";
import ErrorOutlineIcon from "@mui/icons-material/ErrorOutline";
import LinkIcon from "@mui/icons-material/Link";
import PublicIcon from "@mui/icons-material/Public";
import RemoveCircleOutline from "@mui/icons-material/RemoveCircleOutline";
import { DialogProps, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import { useContext, useEffect, useMemo, useState } from "react";
import { Trans } from "react-i18next";
import {
    deleteShareableURL,
    updateShareableURL,
} from "services/collectionService";
import { SetPublicShareProp } from "types/publicCollection";
import {
    appendCollectionKeyToShareURL,
    getDeviceLimitOptions,
} from "utils/collection";
import { handleSharingErrors } from "utils/error/ui";
import EmailShare from "./emailShare";
import EnablePublicShareOptions from "./publicShare/EnablePublicShareOptions";
import { ManageLinkExpiry } from "./publicShare/manage/linkExpiry";
import { ManageLinkPassword } from "./publicShare/manage/linkPassword";
import SharingDetails from "./sharingDetails";

interface CollectionShareProps {
    open: boolean;
    onClose: () => void;
    collection: Collection;
    collectionSummary: CollectionSummary;
}

export const CollectionShare: React.FC<CollectionShareProps> = ({
    collectionSummary,
    ...props
}) => {
    const handleRootClose = () => {
        props.onClose();
    };
    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
            handleRootClose();
        } else {
            props.onClose();
        }
    };
    if (!props.collection || !collectionSummary) {
        return <></>;
    }
    const { type } = collectionSummary;

    return (
        <SidebarDrawer
            anchor="right"
            open={props.open}
            onClose={handleDrawerClose}
            slotProps={{
                backdrop: {
                    sx: { "&&&": { backgroundColor: "transparent" } },
                },
            }}
        >
            <Stack spacing={"4px"} py={"12px"}>
                <Titlebar
                    onClose={props.onClose}
                    title={
                        type == "incomingShareCollaborator" ||
                        type == "incomingShareViewer"
                            ? t("sharing_details")
                            : t("share_album")
                    }
                    onRootClose={handleRootClose}
                    caption={props.collection.name}
                />
                <Stack py={"20px"} px={"8px"} gap={"24px"}>
                    {type == "incomingShareCollaborator" ||
                    type == "incomingShareViewer" ? (
                        <SharingDetails
                            collection={props.collection}
                            type={type}
                        />
                    ) : (
                        <>
                            <EmailShare
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            />
                            <PublicShare
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            />
                        </>
                    )}
                </Stack>
            </Stack>
        </SidebarDrawer>
    );
};

interface PublicShareProps {
    collection: Collection;
    onRootClose: () => void;
}

const PublicShare: React.FC<PublicShareProps> = ({
    collection,
    onRootClose,
}) => {
    const [publicShareUrl, setPublicShareUrl] = useState<string>(null);
    const [publicShareProp, setPublicShareProp] = useState<PublicURL>(null);
    const {
        show: showPublicLinkCreated,
        props: publicLinkCreatedVisibilityProps,
    } = useModalVisibility();

    useEffect(() => {
        if (collection.publicURLs?.length) {
            setPublicShareProp(collection.publicURLs[0]);
        }
    }, [collection]);

    useEffect(() => {
        if (publicShareProp) {
            const url = appendCollectionKeyToShareURL(
                publicShareProp.url,
                collection.key,
            );
            setPublicShareUrl(url);
        } else {
            setPublicShareUrl(null);
        }
    }, [publicShareProp]);

    const copyToClipboardHelper = () => {
        navigator.clipboard.writeText(publicShareUrl);
    };

    return (
        <>
            {publicShareProp ? (
                <ManagePublicShare
                    publicShareProp={publicShareProp}
                    setPublicShareProp={setPublicShareProp}
                    collection={collection}
                    publicShareUrl={publicShareUrl}
                    onRootClose={onRootClose}
                    copyToClipboardHelper={copyToClipboardHelper}
                />
            ) : (
                <EnablePublicShareOptions
                    setPublicShareProp={setPublicShareProp}
                    collection={collection}
                    onLinkCreated={showPublicLinkCreated}
                />
            )}
            <PublicLinkCreated
                {...publicLinkCreatedVisibilityProps}
                onCopyLink={copyToClipboardHelper}
            />
        </>
    );
};

export const isLinkExpired = (validTill: number) => {
    return validTill && validTill < Date.now() * 1000;
};

interface ManagePublicShareProps {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
    onRootClose: () => void;
    publicShareUrl: string;
    copyToClipboardHelper: () => void;
}

const ManagePublicShare: React.FC<ManagePublicShareProps> = ({
    publicShareProp,
    setPublicShareProp,
    collection,
    onRootClose,
    publicShareUrl,
    copyToClipboardHelper,
}) => {
    const [manageShareView, setManageShareView] = useState(false);
    const closeManageShare = () => setManageShareView(false);
    const openManageShare = () => setManageShareView(true);
    return (
        <>
            <Stack>
                <Typography color="text.muted" variant="small" padding={1}>
                    <PublicIcon style={{ fontSize: 17, marginRight: 8 }} />
                    {t("PUBLIC_LINK_ENABLED")}
                </Typography>
                <MenuItemGroup>
                    {isLinkExpired(publicShareProp.validTill) ? (
                        <EnteMenuItem
                            disabled
                            startIcon={<ErrorOutlineIcon />}
                            color="critical"
                            onClick={openManageShare}
                            label={t("link_expired")}
                        />
                    ) : (
                        <EnteMenuItem
                            startIcon={<ContentCopyIcon />}
                            onClick={copyToClipboardHelper}
                            disabled={isLinkExpired(publicShareProp.validTill)}
                            label={t("copy_link")}
                        />
                    )}

                    <MenuItemDivider hasIcon={true} />
                    <EnteMenuItem
                        startIcon={<LinkIcon />}
                        endIcon={<ChevronRightIcon />}
                        onClick={openManageShare}
                        label={t("MANAGE_LINK")}
                    />
                </MenuItemGroup>
            </Stack>
            <ManagePublicShareOptions
                open={manageShareView}
                onClose={closeManageShare}
                onRootClose={onRootClose}
                publicShareProp={publicShareProp}
                collection={collection}
                setPublicShareProp={setPublicShareProp}
                publicShareUrl={publicShareUrl}
            />
        </>
    );
};

interface ManagePublicShareOptionsProps {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
    publicShareUrl: string;
}

const ManagePublicShareOptions: React.FC<ManagePublicShareOptionsProps> = ({
    publicShareProp,
    collection,
    setPublicShareProp,
    open,
    onClose,
    onRootClose,
    publicShareUrl,
}) => {
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
        <SidebarDrawer anchor="right" open={open} onClose={handleDrawerClose}>
            <Stack spacing={"4px"} py={"12px"}>
                <Titlebar
                    onClose={onClose}
                    title={t("share_album")}
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
                                onClick={copyToClipboardHelper(publicShareUrl)}
                                label={t("copy_link")}
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
        </SidebarDrawer>
    );
};

interface ManageDeviceLimitProps {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
    onRootClose: () => void;
}

const ManageDeviceLimit: React.FC<ManageDeviceLimitProps> = ({
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
    onRootClose,
}) => {
    const updateDeviceLimit = async (newLimit: number) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            deviceLimit: newLimit,
        });
    };
    const [isChangeDeviceLimitVisible, setIsChangeDeviceLimitVisible] =
        useState(false);
    const deviceLimitOptions = useMemo(() => getDeviceLimitOptions(), []);

    const closeDeviceLimitChangeModal = () =>
        setIsChangeDeviceLimitVisible(false);
    const openDeviceLimitChangeModalView = () =>
        setIsChangeDeviceLimitVisible(true);

    const changeDeviceLimitValue = (value: number) => async () => {
        await updateDeviceLimit(value);
        setIsChangeDeviceLimitVisible(false);
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
            onRootClose();
        } else {
            closeDeviceLimitChangeModal();
        }
    };

    return (
        <>
            <EnteMenuItem
                label={t("LINK_DEVICE_LIMIT")}
                variant="captioned"
                subText={
                    publicShareProp.deviceLimit === 0
                        ? t("NO_DEVICE_LIMIT")
                        : publicShareProp.deviceLimit.toString()
                }
                onClick={openDeviceLimitChangeModalView}
                endIcon={<ChevronRight />}
            />

            <SidebarDrawer
                anchor="right"
                open={isChangeDeviceLimitVisible}
                onClose={handleDrawerClose}
            >
                <Stack spacing={"4px"} py={"12px"}>
                    <Titlebar
                        onClose={closeDeviceLimitChangeModal}
                        title={t("LINK_DEVICE_LIMIT")}
                        onRootClose={onRootClose}
                    />
                    <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                        <MenuItemGroup>
                            {deviceLimitOptions.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        fontWeight="normal"
                                        key={item.label}
                                        onClick={changeDeviceLimitValue(
                                            item.value,
                                        )}
                                        label={item.label}
                                    />
                                    {index !==
                                        deviceLimitOptions.length - 1 && (
                                        <MenuItemDivider />
                                    )}
                                </>
                            ))}
                        </MenuItemGroup>
                    </Stack>
                </Stack>
            </SidebarDrawer>
        </>
    );
};

interface ManageDownloadAccessProps {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

const ManageDownloadAccess: React.FC<ManageDownloadAccessProps> = ({
    publicShareProp,
    updatePublicShareURLHelper,
    collection,
}) => {
    const { showMiniDialog } = useAppContext();

    const handleFileDownloadSetting = () => {
        if (publicShareProp.enableDownload) {
            disableFileDownload();
        } else {
            updatePublicShareURLHelper({
                collectionID: collection.id,
                enableDownload: true,
            });
        }
    };

    const disableFileDownload = () => {
        showMiniDialog({
            title: t("disable_file_download"),
            message: <Trans i18nKey={"disable_file_download_message"} />,
            continue: {
                text: t("disable"),
                color: "critical",
                action: () =>
                    updatePublicShareURLHelper({
                        collectionID: collection.id,
                        enableDownload: false,
                    }),
            },
        });
    };
    return (
        <EnteMenuItem
            checked={publicShareProp?.enableDownload ?? true}
            onClick={handleFileDownloadSetting}
            variant="toggle"
            label={t("FILE_DOWNLOAD")}
        />
    );
};

interface ManagePublicCollectProps {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

const ManagePublicCollect: React.FC<ManagePublicCollectProps> = ({
    publicShareProp,
    updatePublicShareURLHelper,
    collection,
}) => {
    const handleFileDownloadSetting = () => {
        updatePublicShareURLHelper({
            collectionID: collection.id,
            enableCollect: !publicShareProp.enableCollect,
        });
    };

    return (
        <Stack>
            <MenuItemGroup>
                <EnteMenuItem
                    onClick={handleFileDownloadSetting}
                    variant="toggle"
                    checked={publicShareProp?.enableCollect}
                    label={t("PUBLIC_COLLECT")}
                />
            </MenuItemGroup>
            <MenuSectionTitle title={t("PUBLIC_COLLECT_SUBTEXT")} />
        </Stack>
    );
};
