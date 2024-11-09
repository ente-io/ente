import {
    MenuItemDivider,
    MenuItemGroup,
    MenuSectionTitle,
} from "@/base/components/Menu";
import { SidebarDrawer } from "@/base/components/mui/SidebarDrawer";
import { Titlebar } from "@/base/components/Titlebar";
import { useModalVisibility } from "@/base/components/utils/modal";
import { sharedCryptoWorker } from "@/base/crypto";
import type {
    Collection,
    PublicURL,
    UpdatePublicURL,
} from "@/media/collection";
import { COLLECTION_ROLE } from "@/media/collection";
import { PublicLinkCreated } from "@/new/photos/components/share/PublicLinkCreated";
import type { CollectionSummary } from "@/new/photos/services/collection/ui";
import { useAppContext } from "@/new/photos/types/context";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { formatDateTime } from "@ente/shared/time/format";
import AdminPanelSettingsIcon from "@mui/icons-material/AdminPanelSettings";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import ContentCopyIcon from "@mui/icons-material/ContentCopyOutlined";
import DownloadSharp from "@mui/icons-material/DownloadSharp";
import ErrorOutlineIcon from "@mui/icons-material/ErrorOutline";
import LinkIcon from "@mui/icons-material/Link";
import ModeEditIcon from "@mui/icons-material/ModeEdit";
import Photo from "@mui/icons-material/Photo";
import PublicIcon from "@mui/icons-material/Public";
import RemoveCircleOutline from "@mui/icons-material/RemoveCircleOutline";
import { Dialog, DialogProps, Stack, Typography } from "@mui/material";
import Avatar from "components/pages/gallery/Avatar";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useEffect, useMemo, useState } from "react";
import { Trans } from "react-i18next";
import {
    createShareableURL,
    deleteShareableURL,
    updateShareableURL,
} from "services/collectionService";
import { SetPublicShareProp } from "types/publicCollection";
import {
    appendCollectionKeyToShareURL,
    getDeviceLimitOptions,
    shareExpiryOptions,
} from "utils/collection";
import { handleSharingErrors } from "utils/error/ui";
import EmailShare from "./emailShare";

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

function SharingDetails({ collection, type }) {
    const galleryContext = useContext(GalleryContext);

    const ownerEmail =
        galleryContext.user.id === collection.owner?.id
            ? galleryContext.user?.email
            : collection.owner?.email;

    const collaborators = collection.sharees
        ?.filter((sharee) => sharee.role === COLLECTION_ROLE.COLLABORATOR)
        .map((sharee) => sharee.email);

    const viewers =
        collection.sharees
            ?.filter((sharee) => sharee.role === COLLECTION_ROLE.VIEWER)
            .map((sharee) => sharee.email) || [];

    const isOwner = galleryContext.user?.id === collection.owner?.id;

    const isMe = (email: string) => email === galleryContext.user?.email;

    return (
        <>
            <Stack>
                <MenuSectionTitle
                    title={t("OWNER")}
                    icon={<AdminPanelSettingsIcon />}
                />
                <MenuItemGroup>
                    <EnteMenuItem
                        fontWeight="normal"
                        onClick={() => {}}
                        label={isOwner ? t("you") : ownerEmail}
                        startIcon={<Avatar email={ownerEmail} />}
                    />
                </MenuItemGroup>
            </Stack>
            {type == "incomingShareCollaborator" &&
                collaborators?.length > 0 && (
                    <Stack>
                        <MenuSectionTitle
                            title={t("COLLABORATORS")}
                            icon={<ModeEditIcon />}
                        />
                        <MenuItemGroup>
                            {collaborators.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        fontWeight="normal"
                                        key={item}
                                        onClick={() => {}}
                                        label={isMe(item) ? t("you") : item}
                                        startIcon={<Avatar email={item} />}
                                    />
                                    {index !== collaborators.length - 1 && (
                                        <MenuItemDivider />
                                    )}
                                </>
                            ))}
                        </MenuItemGroup>
                    </Stack>
                )}
            {viewers?.length > 0 && (
                <Stack>
                    <MenuSectionTitle title={t("VIEWERS")} icon={<Photo />} />
                    <MenuItemGroup>
                        {viewers.map((item, index) => (
                            <>
                                <EnteMenuItem
                                    fontWeight="normal"
                                    key={item}
                                    onClick={() => {}}
                                    label={isMe(item) ? t("you") : item}
                                    startIcon={<Avatar email={item} />}
                                />
                                {index !== viewers.length - 1 && (
                                    <MenuItemDivider />
                                )}
                            </>
                        ))}
                    </MenuItemGroup>
                </Stack>
            )}
        </>
    );
}

interface EnablePublicShareOptionsProps {
    collection: Collection;
    setPublicShareProp: (value: PublicURL) => void;
    onLinkCreated: () => void;
}

const EnablePublicShareOptions: React.FC<EnablePublicShareOptionsProps> = ({
    collection,
    setPublicShareProp,
    onLinkCreated,
}) => {
    const galleryContext = useContext(GalleryContext);
    const [sharableLinkError, setSharableLinkError] = useState(null);

    const createSharableURLHelper = async () => {
        try {
            setSharableLinkError(null);
            galleryContext.setBlockingLoad(true);
            const publicURL = await createShareableURL(collection);
            setPublicShareProp(publicURL);
            onLinkCreated();
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };

    const createCollectPhotoShareableURLHelper = async () => {
        try {
            setSharableLinkError(null);
            galleryContext.setBlockingLoad(true);
            const publicURL = await createShareableURL(collection);
            await updateShareableURL({
                collectionID: collection.id,
                enableCollect: true,
            });
            setPublicShareProp(publicURL);
            onLinkCreated();
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };

    return (
        <Stack>
            <MenuSectionTitle
                title={t("LINK_SHARE_TITLE")}
                icon={<PublicIcon />}
            />
            <MenuItemGroup>
                <EnteMenuItem
                    label={t("CREATE_PUBLIC_SHARING")}
                    startIcon={<LinkIcon />}
                    onClick={createSharableURLHelper}
                />
                <MenuItemDivider hasIcon />
                <EnteMenuItem
                    label={t("COLLECT_PHOTOS")}
                    startIcon={<DownloadSharp />}
                    onClick={createCollectPhotoShareableURLHelper}
                />
            </MenuItemGroup>
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

const isLinkExpired = (validTill: number) => {
    return validTill && validTill < Date.now() * 1000;
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

interface ManageLinkExpiryProps {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
    onRootClose: () => void;
}

const ManageLinkExpiry: React.FC<ManageLinkExpiryProps> = ({
    publicShareProp,
    collection,
    updatePublicShareURLHelper,
    onRootClose,
}) => {
    const updateDeviceExpiry = async (optionFn) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            validTill: optionFn,
        });
    };

    const [shareExpiryOptionsModalView, setShareExpiryOptionsModalView] =
        useState(false);

    const shareExpireOption = useMemo(() => shareExpiryOptions(), []);

    const closeShareExpiryOptionsModalView = () =>
        setShareExpiryOptionsModalView(false);

    const openShareExpiryOptionsModalView = () =>
        setShareExpiryOptionsModalView(true);

    const changeShareExpiryValue = (value: number) => async () => {
        await updateDeviceExpiry(value);
        publicShareProp.validTill = value;
        setShareExpiryOptionsModalView(false);
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
            onRootClose();
        } else {
            closeShareExpiryOptionsModalView();
        }
    };

    return (
        <>
            <MenuItemGroup>
                <EnteMenuItem
                    onClick={openShareExpiryOptionsModalView}
                    endIcon={<ChevronRightIcon />}
                    variant="captioned"
                    label={t("LINK_EXPIRY")}
                    color={
                        isLinkExpired(publicShareProp?.validTill)
                            ? "critical"
                            : "primary"
                    }
                    subText={
                        isLinkExpired(publicShareProp?.validTill)
                            ? t("link_expired")
                            : publicShareProp?.validTill
                              ? formatDateTime(
                                    publicShareProp?.validTill / 1000,
                                )
                              : t("never")
                    }
                />
            </MenuItemGroup>
            <SidebarDrawer
                anchor="right"
                open={shareExpiryOptionsModalView}
                onClose={handleDrawerClose}
            >
                <Stack spacing={"4px"} py={"12px"}>
                    <Titlebar
                        onClose={closeShareExpiryOptionsModalView}
                        title={t("LINK_EXPIRY")}
                        onRootClose={onRootClose}
                    />
                    <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                        <MenuItemGroup>
                            {shareExpireOption.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        fontWeight="normal"
                                        key={item.value()}
                                        onClick={changeShareExpiryValue(
                                            item.value(),
                                        )}
                                        label={item.label}
                                    />
                                    {index !== shareExpireOption.length - 1 && (
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
                endIcon={<ChevronRightIcon />}
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

interface ManageLinkPasswordProps {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

const ManageLinkPassword: React.FC<ManageLinkPasswordProps> = ({
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
}) => {
    const { showMiniDialog } = useAppContext();
    const [changePasswordView, setChangePasswordView] = useState(false);

    const closeConfigurePassword = () => setChangePasswordView(false);

    const handlePasswordChangeSetting = async () => {
        if (publicShareProp.passwordEnabled) {
            await confirmDisablePublicUrlPassword();
        } else {
            setChangePasswordView(true);
        }
    };

    const confirmDisablePublicUrlPassword = async () => {
        showMiniDialog({
            title: t("disable_password"),
            message: t("disable_password_message"),
            continue: {
                text: t("disable"),
                color: "critical",
                action: () =>
                    updatePublicShareURLHelper({
                        collectionID: collection.id,
                        disablePassword: true,
                    }),
            },
        });
    };

    return (
        <>
            <EnteMenuItem
                label={t("password_lock")}
                onClick={handlePasswordChangeSetting}
                checked={!!publicShareProp?.passwordEnabled}
                variant="toggle"
            />
            <PublicLinkSetPassword
                open={changePasswordView}
                onClose={closeConfigurePassword}
                collection={collection}
                publicShareProp={publicShareProp}
                updatePublicShareURLHelper={updatePublicShareURLHelper}
                setChangePasswordView={setChangePasswordView}
            />
        </>
    );
};

function PublicLinkSetPassword({
    open,
    onClose,
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
    setChangePasswordView,
}) {
    const savePassword: SingleInputFormProps["callback"] = async (
        passphrase,
        setFieldError,
    ) => {
        if (passphrase && passphrase.trim().length >= 1) {
            await enablePublicUrlPassword(passphrase);
            setChangePasswordView(false);
            publicShareProp.passwordEnabled = true;
        } else {
            setFieldError("can not be empty");
        }
    };

    const enablePublicUrlPassword = async (password: string) => {
        const cryptoWorker = await sharedCryptoWorker();
        const kekSalt = await cryptoWorker.generateSaltToDeriveKey();
        const kek = await cryptoWorker.deriveInteractiveKey(password, kekSalt);

        return updatePublicShareURLHelper({
            collectionID: collection.id,
            passHash: kek.key,
            nonce: kekSalt,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        });
    };
    return (
        <Dialog
            open={open}
            onClose={onClose}
            disablePortal
            BackdropProps={{ sx: { position: "absolute" } }}
            sx={{ position: "absolute" }}
            PaperProps={{ sx: { p: 1 } }}
            maxWidth={"sm"}
            fullWidth
        >
            <Stack spacing={3} p={1.5}>
                <Typography variant="h3" px={1} py={0.5} fontWeight={"bold"}>
                    {t("password_lock")}
                </Typography>
                <SingleInputForm
                    callback={savePassword}
                    placeholder={t("password")}
                    buttonText={t("lock")}
                    fieldType="password"
                    secondaryButtonAction={onClose}
                    submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                />
            </Stack>
        </Dialog>
    );
}
