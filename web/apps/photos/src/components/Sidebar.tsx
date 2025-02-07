import { RecoveryKey } from "@/accounts/components/RecoveryKey";
import { openAccountsManagePasskeysPage } from "@/accounts/services/passkey";
import { isDesktop } from "@/base/app";
import { EnteLogo } from "@/base/components/EnteLogo";
import { LinkButton } from "@/base/components/LinkButton";
import { RowButton } from "@/base/components/RowButton";
import { SpacedRow } from "@/base/components/containers";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { SidebarDrawer } from "@/base/components/mui/SidebarDrawer";
import { useIsSmallWidth } from "@/base/components/utils/hooks";
import { useModalVisibility } from "@/base/components/utils/modal";
import { isDevBuild } from "@/base/env";
import { ut } from "@/base/i18n";
import log from "@/base/log";
import { savedLogs } from "@/base/log-web";
import { customAPIHost } from "@/base/origins";
import { downloadString } from "@/base/utils/web";
import { DialogCloseIconButton } from "@/new/photos/components/mui/Dialog";
import { TwoFactorSettings } from "@/new/photos/components/sidebar/TwoFactorSettings";
import { downloadAppDialogAttributes } from "@/new/photos/components/utils/download";
import { useUserDetailsSnapshot } from "@/new/photos/components/utils/use-snapshot";
import {
    ARCHIVE_SECTION,
    DUMMY_UNCATEGORIZED_COLLECTION,
    TRASH_SECTION,
} from "@/new/photos/services/collection";
import type { CollectionSummaries } from "@/new/photos/services/collection/ui";
import { isInternalUser } from "@/new/photos/services/settings";
import {
    familyAdminEmail,
    hasExceededStorageQuota,
    isFamilyAdmin,
    isPartOfFamily,
    isSubscriptionActive,
    isSubscriptionActivePaid,
    isSubscriptionCancelled,
    isSubscriptionFree,
    isSubscriptionPastDue,
    isSubscriptionStripe,
    leaveFamily,
    redirectToCustomerPortal,
    syncUserDetails,
    userDetailsAddOnBonuses,
    type UserDetails,
} from "@/new/photos/services/user-details";
import { AppContext, useAppContext } from "@/new/photos/types/context";
import { initiateEmail, openURL } from "@/new/photos/utils/web";
import {
    FlexWrapper,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import ArchiveOutlinedIcon from "@mui/icons-material/ArchiveOutlined";
import CategoryIcon from "@mui/icons-material/Category";
import CloseIcon from "@mui/icons-material/Close";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import LockOutlinedIcon from "@mui/icons-material/LockOutlined";
import VisibilityOffIcon from "@mui/icons-material/VisibilityOff";
import {
    Box,
    Button,
    Dialog,
    DialogContent,
    Divider,
    IconButton,
    Skeleton,
    Stack,
    styled,
    Tooltip,
} from "@mui/material";
import Typography from "@mui/material/Typography";
import DeleteAccountModal from "components/DeleteAccountModal";
import { WatchFolder } from "components/WatchFolder";
import { t } from "i18next";
import { useRouter } from "next/router";
import { GalleryContext } from "pages/gallery";
import React, {
    MouseEventHandler,
    useContext,
    useEffect,
    useMemo,
    useState,
} from "react";
import { Trans } from "react-i18next";
import { getUncategorizedCollection } from "services/collectionService";
import exportService from "services/export";
import { testUpload } from "../../tests/upload.test";
import { SubscriptionCard } from "./SubscriptionCard";

import {
    RowButtonGroup,
    RowButtonGroupHint,
    RowSwitch,
} from "@/base/components/RowButton";
import {
    NestedSidebarDrawer,
    SidebarDrawerTitlebar,
    type NestedSidebarDrawerVisibilityProps,
} from "@/base/components/mui/SidebarDrawer";
import {
    getLocaleInUse,
    setLocaleInUse,
    supportedLocales,
    type SupportedLocale,
} from "@/base/i18n";
import { DropdownInput } from "@/new/photos/components/DropdownInput";
import { MLSettings } from "@/new/photos/components/sidebar/MLSettings";
import {
    confirmDisableMapsDialogAttributes,
    confirmEnableMapsDialogAttributes,
} from "@/new/photos/components/utils/dialog";
import { useSettingsSnapshot } from "@/new/photos/components/utils/use-snapshot";
import { isMLSupported } from "@/new/photos/services/ml";
import {
    syncSettings,
    updateCFProxyDisabledPreference,
    updateMapEnabled,
} from "@/new/photos/services/settings";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import { useColorScheme } from "@mui/material";
import { useCallback } from "react";

interface SidebarProps {
    collectionSummaries: CollectionSummaries;
    sidebarView: boolean;
    closeSidebar: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
    collectionSummaries,
    sidebarView,
    closeSidebar,
}) => (
    <RootSidebarDrawer open={sidebarView} onClose={closeSidebar}>
        <HeaderSection closeSidebar={closeSidebar} />
        <Divider />
        <UserDetailsSection sidebarView={sidebarView} />
        <Stack sx={{ gap: 0.5, mb: 3 }}>
            <ShortcutSection
                closeSidebar={closeSidebar}
                collectionSummaries={collectionSummaries}
            />
            <UtilitySection closeSidebar={closeSidebar} />
            <Divider />
            <HelpSection />
            <Divider />
            <ExitSection />
            <Divider />
            <DebugSection />
        </Stack>
    </RootSidebarDrawer>
);

const RootSidebarDrawer = styled(SidebarDrawer)(({ theme }) => ({
    "& .MuiPaper-root": {
        padding: theme.spacing(1.5),
    },
}));

interface HeaderSectionProps {
    closeSidebar: () => void;
}

const HeaderSection: React.FC<HeaderSectionProps> = ({ closeSidebar }) => {
    return (
        <SpacedRow sx={{ my: "4px 4px", pl: "12px" }}>
            <EnteLogo />
            <IconButton
                aria-label={t("close")}
                onClick={closeSidebar}
                color="secondary"
            >
                <CloseIcon fontSize="small" />
            </IconButton>
        </SpacedRow>
    );
};

interface UserDetailsSectionProps {
    sidebarView: boolean;
}

const UserDetailsSection: React.FC<UserDetailsSectionProps> = ({
    sidebarView,
}) => {
    const galleryContext = useContext(GalleryContext);
    const userDetails = useUserDetailsSnapshot();
    const [memberSubscriptionManageView, setMemberSubscriptionManageView] =
        useState(false);

    const openMemberSubscriptionManage = () =>
        setMemberSubscriptionManageView(true);
    const closeMemberSubscriptionManage = () =>
        setMemberSubscriptionManageView(false);

    useEffect(() => {
        if (sidebarView) void syncUserDetails();
    }, [sidebarView]);

    const isNonAdminFamilyMember = useMemo(
        () =>
            userDetails &&
            isPartOfFamily(userDetails) &&
            !isFamilyAdmin(userDetails),
        [userDetails],
    );

    const handleSubscriptionCardClick = () => {
        if (isNonAdminFamilyMember) {
            openMemberSubscriptionManage();
        } else {
            if (
                userDetails &&
                isSubscriptionStripe(userDetails.subscription) &&
                isSubscriptionPastDue(userDetails.subscription)
            ) {
                redirectToCustomerPortal();
            } else {
                galleryContext.showPlanSelectorModal();
            }
        }
    };

    return (
        <>
            <Box sx={{ px: 0.5, mt: 2, pb: 1.5, mb: 1 }}>
                <Typography sx={{ px: 1, pb: 1, color: "text.muted" }}>
                    {userDetails ? (
                        userDetails.email
                    ) : (
                        <Skeleton animation="wave" />
                    )}
                </Typography>

                <SubscriptionCard
                    userDetails={userDetails}
                    onClick={handleSubscriptionCardClick}
                />
                {userDetails && (
                    <SubscriptionStatus userDetails={userDetails} />
                )}
            </Box>
            {isNonAdminFamilyMember && (
                <MemberSubscriptionManage
                    userDetails={userDetails}
                    open={memberSubscriptionManageView}
                    onClose={closeMemberSubscriptionManage}
                />
            )}
        </>
    );
};

interface SubscriptionStatusProps {
    userDetails: UserDetails;
}

const SubscriptionStatus: React.FC<SubscriptionStatusProps> = ({
    userDetails,
}) => {
    const { showPlanSelectorModal } = useContext(GalleryContext);

    const hasAMessage = useMemo(() => {
        if (isPartOfFamily(userDetails) && !isFamilyAdmin(userDetails)) {
            return false;
        }
        if (
            isSubscriptionActivePaid(userDetails.subscription) &&
            !isSubscriptionCancelled(userDetails.subscription)
        ) {
            return false;
        }
        return true;
    }, [userDetails]);

    const handleClick = useMemo(() => {
        const eventHandler: MouseEventHandler<HTMLSpanElement> = (e) => {
            e.stopPropagation();

            if (isSubscriptionActive(userDetails.subscription)) {
                if (hasExceededStorageQuota(userDetails)) {
                    showPlanSelectorModal();
                }
            } else {
                if (
                    isSubscriptionStripe(userDetails.subscription) &&
                    isSubscriptionPastDue(userDetails.subscription)
                ) {
                    redirectToCustomerPortal();
                } else {
                    showPlanSelectorModal();
                }
            }
        };
        return eventHandler;
    }, [userDetails]);

    if (!hasAMessage) {
        return <></>;
    }

    const hasAddOnBonus = userDetailsAddOnBonuses(userDetails).length > 0;

    let message: React.ReactNode;
    if (!hasAddOnBonus) {
        if (isSubscriptionActive(userDetails.subscription)) {
            if (isSubscriptionFree(userDetails.subscription)) {
                message = t("subscription_info_free");
            } else if (isSubscriptionCancelled(userDetails.subscription)) {
                message = t("subscription_info_renewal_cancelled", {
                    date: userDetails.subscription?.expiryTime,
                });
            }
        } else {
            message = (
                <Trans
                    i18nKey={"subscription_info_expired"}
                    components={{
                        a: <LinkButton onClick={handleClick} />,
                    }}
                />
            );
        }
    }

    if (!message && hasExceededStorageQuota(userDetails)) {
        message = (
            <Trans
                i18nKey={"subscription_info_storage_quota_exceeded"}
                components={{
                    a: <LinkButton onClick={handleClick} />,
                }}
            />
        );
    }

    if (!message) return <></>;

    return (
        <Box sx={{ px: 1, pt: 0.5 }}>
            <Typography
                variant="small"
                onClick={handleClick && handleClick}
                sx={{
                    color: "text.muted",
                    cursor: handleClick && "pointer",
                }}
            >
                {message}
            </Typography>
        </Box>
    );
};

function MemberSubscriptionManage({ open, userDetails, onClose }) {
    const { showMiniDialog } = useAppContext();
    const fullScreen = useIsSmallWidth();

    const confirmLeaveFamily = () =>
        showMiniDialog({
            title: t("leave_family_plan"),
            message: t("leave_family_plan_confirm"),
            continue: {
                text: t("leave"),
                color: "critical",
                action: leaveFamily,
            },
        });

    if (!userDetails) {
        return <></>;
    }

    return (
        <Dialog {...{ open, onClose, fullScreen }} maxWidth="xs" fullWidth>
            <SpacedRow sx={{ p: "20px 8px 12px 16px" }}>
                <Stack>
                    <Typography variant="h3">{t("subscription")}</Typography>
                    <Typography sx={{ color: "text.muted" }}>
                        {t("family_plan")}
                    </Typography>
                </Stack>
                <DialogCloseIconButton {...{ onClose }} />
            </SpacedRow>
            <DialogContent>
                <VerticallyCentered>
                    <Box sx={{ mb: 4 }}>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("subscription_info_family")}
                        </Typography>
                        <Typography>
                            {familyAdminEmail(userDetails) ?? ""}
                        </Typography>
                    </Box>

                    <img
                        height={256}
                        src="/images/family-plan/1x.png"
                        srcSet="/images/family-plan/2x.png 2x, /images/family-plan/3x.png 3x"
                    />
                    <FlexWrapper px={2}>
                        <Button
                            fullWidth
                            variant="outlined"
                            color="critical"
                            onClick={confirmLeaveFamily}
                        >
                            {t("leave_family_plan")}
                        </Button>
                    </FlexWrapper>
                </VerticallyCentered>
            </DialogContent>
        </Dialog>
    );
}

interface ShortcutSectionProps {
    closeSidebar: () => void;
    collectionSummaries: CollectionSummaries;
}

const ShortcutSection: React.FC<ShortcutSectionProps> = ({
    closeSidebar,
    collectionSummaries,
}) => {
    const galleryContext = useContext(GalleryContext);
    const [uncategorizedCollectionId, setUncategorizedCollectionID] =
        useState<number>();

    useEffect(() => {
        const main = async () => {
            const unCategorizedCollection = await getUncategorizedCollection();
            if (unCategorizedCollection) {
                setUncategorizedCollectionID(unCategorizedCollection.id);
            } else {
                setUncategorizedCollectionID(DUMMY_UNCATEGORIZED_COLLECTION);
            }
        };
        main();
    }, []);

    const openUncategorizedSection = () => {
        galleryContext.setActiveCollectionID(uncategorizedCollectionId);
        closeSidebar();
    };

    const openTrashSection = () => {
        galleryContext.setActiveCollectionID(TRASH_SECTION);
        closeSidebar();
    };

    const openArchiveSection = () => {
        galleryContext.setActiveCollectionID(ARCHIVE_SECTION);
        closeSidebar();
    };

    const openHiddenSection = () => {
        galleryContext.openHiddenSection(() => {
            closeSidebar();
        });
    };

    return (
        <>
            <RowButton
                startIcon={<CategoryIcon />}
                label={t("section_uncategorized")}
                caption={collectionSummaries
                    .get(uncategorizedCollectionId)
                    ?.fileCount.toString()}
                onClick={openUncategorizedSection}
            />
            <RowButton
                startIcon={<ArchiveOutlinedIcon />}
                label={t("section_archive")}
                caption={collectionSummaries
                    .get(ARCHIVE_SECTION)
                    ?.fileCount.toString()}
                onClick={openArchiveSection}
            />
            <RowButton
                startIcon={<VisibilityOffIcon />}
                label={t("section_hidden")}
                caption={
                    <LockOutlinedIcon
                        sx={{
                            verticalAlign: "middle",
                            fontSize: "19px !important",
                        }}
                    />
                }
                onClick={openHiddenSection}
            />
            <RowButton
                startIcon={<DeleteOutlineIcon />}
                label={t("section_trash")}
                caption={collectionSummaries
                    .get(TRASH_SECTION)
                    ?.fileCount.toString()}
                onClick={openTrashSection}
            />
        </>
    );
};

interface UtilitySectionProps {
    closeSidebar: () => void;
}

const UtilitySection: React.FC<UtilitySectionProps> = ({ closeSidebar }) => {
    const router = useRouter();
    const { watchFolderView, setWatchFolderView, showMiniDialog } =
        useAppContext();

    const { show: showRecoveryKey, props: recoveryKeyVisibilityProps } =
        useModalVisibility();
    const { show: showTwoFactor, props: twoFactorVisibilityProps } =
        useModalVisibility();
    const { show: showPreferences, props: preferencesVisibilityProps } =
        useModalVisibility();

    const showWatchFolder = () => setWatchFolderView(true);
    const handleCloseWatchFolder = () => setWatchFolderView(false);

    const redirectToChangePasswordPage = () => {
        closeSidebar();
        router.push(PAGES.CHANGE_PASSWORD);
    };

    const handleChangeEmail = () => router.push("/change-email");

    const redirectToAccountsPage = async () => {
        closeSidebar();
        await openAccountsManagePasskeysPage();
    };

    const handleDeduplicate = () => router.push("/duplicates");

    return (
        <>
            {isDesktop && (
                <RowButton
                    variant="secondary"
                    label={t("watch_folders")}
                    onClick={showWatchFolder}
                />
            )}
            <RowButton
                variant="secondary"
                label={t("recovery_key")}
                onClick={showRecoveryKey}
            />
            <RowButton
                variant="secondary"
                label={t("two_factor")}
                onClick={showTwoFactor}
            />
            <RowButton
                variant="secondary"
                label={t("passkeys")}
                onClick={redirectToAccountsPage}
            />
            <RowButton
                variant="secondary"
                label={t("change_password")}
                onClick={redirectToChangePasswordPage}
            />
            <RowButton
                variant="secondary"
                label={t("change_email")}
                onClick={handleChangeEmail}
            />
            <RowButton
                variant="secondary"
                label={t("deduplicate_files")}
                onClick={handleDeduplicate}
            />
            <RowButton
                variant="secondary"
                label={t("preferences")}
                onClick={showPreferences}
            />

            <RecoveryKey
                {...recoveryKeyVisibilityProps}
                {...{ showMiniDialog }}
            />
            <TwoFactorSettings
                {...twoFactorVisibilityProps}
                onRootClose={closeSidebar}
            />
            {isDesktop && (
                <WatchFolder
                    open={watchFolderView}
                    onClose={handleCloseWatchFolder}
                />
            )}
            <Preferences
                {...preferencesVisibilityProps}
                onRootClose={closeSidebar}
            />
        </>
    );
};

const HelpSection: React.FC = () => {
    const { showMiniDialog } = useContext(AppContext);
    const { openExportModal } = useContext(GalleryContext);

    const requestFeature = () =>
        openURL("https://github.com/ente-io/ente/discussions");

    const contactSupport = () => initiateEmail("support@ente.io");

    const handleExport = () =>
        isDesktop
            ? openExportModal()
            : showMiniDialog(downloadAppDialogAttributes());

    return (
        <>
            <RowButton
                variant="secondary"
                label={t("request_feature")}
                onClick={requestFeature}
            />
            <RowButton
                variant="secondary"
                label={
                    <Tooltip title="support@ente.io">
                        <Typography sx={{ fontWeight: "medium" }}>
                            {t("support")}
                        </Typography>
                    </Tooltip>
                }
                onClick={contactSupport}
            />
            <RowButton
                variant="secondary"
                label={t("export_data")}
                endIcon={
                    exportService.isExportInProgress() && (
                        <ActivityIndicator size="20px" />
                    )
                }
                onClick={handleExport}
            />
        </>
    );
};

const ExitSection: React.FC = () => {
    const { showMiniDialog, logout } = useContext(AppContext);

    const { show: showDeleteAccount, props: deleteAccountVisibilityProps } =
        useModalVisibility();

    const handleLogout = () =>
        showMiniDialog({
            message: t("logout_message"),
            continue: { text: t("logout"), color: "critical", action: logout },
            buttonDirection: "row",
        });

    return (
        <>
            <RowButton
                variant="secondary"
                color="critical"
                label={t("logout")}
                onClick={handleLogout}
            />
            <RowButton
                variant="secondary"
                color="critical"
                onClick={showDeleteAccount}
                label={t("delete_account")}
            />
            <DeleteAccountModal {...deleteAccountVisibilityProps} />
        </>
    );
};

const DebugSection: React.FC = () => {
    const { showMiniDialog } = useAppContext();
    const [appVersion, setAppVersion] = useState<string | undefined>();
    const [host, setHost] = useState<string | undefined>();

    const electron = globalThis.electron;

    useEffect(() => {
        void electron?.appVersion().then(setAppVersion);
        void customAPIHost().then(setHost);
    });

    const confirmLogDownload = () =>
        showMiniDialog({
            title: t("download_logs"),
            message: <Trans i18nKey={"download_logs_message"} />,
            continue: {
                text: t("download"),
                action: downloadLogs,
            },
        });

    const downloadLogs = () => {
        log.info("Downloading logs");
        if (electron) electron.openLogDirectory();
        else downloadString(savedLogs(), `ente-web-logs-${Date.now()}.txt`);
    };

    return (
        <>
            {isInternalUser() && isDevBuild && (
                <RowButton
                    variant="secondary"
                    label={ut("Test Upload")}
                    onClick={testUpload}
                />
            )}
            <RowButton
                variant="secondary"
                label={
                    <Typography variant="mini" color="text.muted">
                        {t("view_logs")}
                    </Typography>
                }
                onClick={confirmLogDownload}
            />
            <Stack
                sx={{
                    py: "14px",
                    px: "16px",
                    gap: "24px",
                    color: "text.muted",
                }}
            >
                {appVersion && (
                    <Typography variant="mini">{appVersion}</Typography>
                )}
                {host && <Typography variant="mini">{host}</Typography>}
            </Stack>
        </>
    );
};

const Preferences: React.FC<NestedSidebarDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const { show: showMapSettings, props: mapSettingsVisibilityProps } =
        useModalVisibility();
    const {
        show: showAdvancedSettings,
        props: advancedSettingsVisibilityProps,
    } = useModalVisibility();
    const { show: showMLSettings, props: mlSettingsVisibilityProps } =
        useModalVisibility();

    useEffect(() => {
        if (open) void syncSettings();
    }, [open]);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    return (
        <NestedSidebarDrawer {...{ open, onClose }} onRootClose={onRootClose}>
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <SidebarDrawerTitlebar
                    onClose={onClose}
                    title={t("preferences")}
                    onRootClose={handleRootClose}
                />
                <Stack sx={{ px: "16px", py: "8px", gap: "24px" }}>
                    <LanguageSelector />
                    <ThemeSelector />
                    <Divider sx={{ my: "2px", opacity: 0.1 }} />
                    {isMLSupported && (
                        <RowButtonGroup>
                            <RowButton
                                endIcon={<ChevronRightIcon />}
                                label={t("ml_search")}
                                onClick={showMLSettings}
                            />
                        </RowButtonGroup>
                    )}
                    <RowButton
                        endIcon={<ChevronRightIcon />}
                        label={t("map")}
                        onClick={showMapSettings}
                    />
                    <RowButton
                        endIcon={<ChevronRightIcon />}
                        label={t("advanced")}
                        onClick={showAdvancedSettings}
                    />
                </Stack>
            </Stack>
            <MapSettings
                {...mapSettingsVisibilityProps}
                onRootClose={onRootClose}
            />
            <AdvancedSettings
                {...advancedSettingsVisibilityProps}
                onRootClose={onRootClose}
            />
            <MLSettings
                {...mlSettingsVisibilityProps}
                onRootClose={handleRootClose}
            />
        </NestedSidebarDrawer>
    );
};

const LanguageSelector = () => {
    const locale = getLocaleInUse();

    const updateCurrentLocale = (newLocale: SupportedLocale) => {
        setLocaleInUse(newLocale);
        // [Note: Changing locale causes a full reload]
        //
        // A full reload is needed because we use the global `t` instance
        // instead of the useTranslation hook.
        //
        // We also rely on this behaviour by caching various formatters in
        // module static variables that not get updated if the i18n.language
        // changes unless there is a full reload.
        window.location.reload();
    };

    const options = supportedLocales.map((locale) => ({
        label: localeName(locale),
        value: locale,
    }));

    return (
        <Stack sx={{ gap: 1 }}>
            <Typography variant="small" sx={{ px: 1, color: "text.muted" }}>
                {t("language")}
            </Typography>
            <DropdownInput
                options={options}
                selected={locale}
                onSelect={updateCurrentLocale}
            />
        </Stack>
    );
};

/**
 * Human readable name for each supported locale.
 */
const localeName = (locale: SupportedLocale) => {
    switch (locale) {
        case "en-US":
            return "English";
        case "fr-FR":
            return "Français";
        case "de-DE":
            return "Deutsch";
        case "zh-CN":
            return "中文";
        case "nl-NL":
            return "Nederlands";
        case "es-ES":
            return "Español";
        case "pt-PT":
            return "Português";
        case "pt-BR":
            return "Português Brasileiro";
        case "ru-RU":
            return "Русский";
        case "pl-PL":
            return "Polski";
        case "it-IT":
            return "Italiano";
        case "lt-LT":
            return "Lietuvių kalba";
        case "uk-UA":
            return "Українська";
        case "vi-VN":
            return "Tiếng Việt";
    }
};

const ThemeSelector = () => {
    const { mode, setMode } = useColorScheme();

    // During SSR, mode is always undefined.
    if (!mode) return null;

    return (
        <Stack sx={{ gap: 1 }}>
            <Typography variant="small" sx={{ px: 1, color: "text.muted" }}>
                {t("theme")}
            </Typography>
            <DropdownInput
                options={[
                    { label: t("system"), value: "system" },
                    { label: t("light"), value: "light" },
                    { label: t("dark"), value: "dark" },
                ]}
                selected={mode}
                onSelect={setMode}
            />
        </Stack>
    );
};

const MapSettings: React.FC<NestedSidebarDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const { showMiniDialog } = useAppContext();

    const { mapEnabled } = useSettingsSnapshot();

    const confirmToggle = useCallback(
        () =>
            showMiniDialog(
                mapEnabled
                    ? confirmDisableMapsDialogAttributes(() =>
                          updateMapEnabled(false),
                      )
                    : confirmEnableMapsDialogAttributes(() =>
                          updateMapEnabled(true),
                      ),
            ),
        [showMiniDialog, mapEnabled],
    );

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    return (
        <NestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
        >
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <SidebarDrawerTitlebar
                    onClose={onClose}
                    onRootClose={handleRootClose}
                    title={t("map")}
                />

                <Stack sx={{ px: "16px", py: "20px" }}>
                    <RowButtonGroup>
                        <RowSwitch
                            label={t("enabled")}
                            checked={mapEnabled}
                            onClick={confirmToggle}
                        />
                    </RowButtonGroup>
                </Stack>
            </Stack>
        </NestedSidebarDrawer>
    );
};

const AdvancedSettings: React.FC<NestedSidebarDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const { cfUploadProxyDisabled } = useSettingsSnapshot();

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const toggle = () =>
        void updateCFProxyDisabledPreference(!cfUploadProxyDisabled);

    return (
        <NestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
        >
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <SidebarDrawerTitlebar
                    onClose={onClose}
                    onRootClose={handleRootClose}
                    title={t("advanced")}
                />

                <Stack sx={{ px: "16px", py: "20px" }}>
                    <Stack sx={{ gap: "4px" }}>
                        <RowButtonGroup>
                            <RowSwitch
                                label={t("faster_upload")}
                                checked={!cfUploadProxyDisabled}
                                onClick={toggle}
                            />
                        </RowButtonGroup>
                        <RowButtonGroupHint>
                            {t("faster_upload_description")}
                        </RowButtonGroupHint>
                    </Stack>
                </Stack>
            </Stack>
        </NestedSidebarDrawer>
    );
};
