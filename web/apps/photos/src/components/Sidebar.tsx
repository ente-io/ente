import { RecoveryKey } from "@/accounts/components/RecoveryKey";
import { openAccountsManagePasskeysPage } from "@/accounts/services/passkey";
import { isDesktop } from "@/base/app";
import { EnteLogo } from "@/base/components/EnteLogo";
import { LinkButton } from "@/base/components/LinkButton";
import {
    RowButton,
    RowButtonDivider,
    RowButtonGroup,
    RowButtonGroupHint,
    RowSwitch,
} from "@/base/components/RowButton";
import { SpacedRow } from "@/base/components/containers";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { DialogCloseIconButton } from "@/base/components/mui/DialogCloseIconButton";
import {
    NestedSidebarDrawer,
    SidebarDrawer,
    SidebarDrawerTitlebar,
    type NestedSidebarDrawerVisibilityProps,
} from "@/base/components/mui/SidebarDrawer";
import { useIsSmallWidth } from "@/base/components/utils/hooks";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "@/base/components/utils/modal";
import { useBaseContext } from "@/base/context";
import {
    getLocaleInUse,
    setLocaleInUse,
    supportedLocales,
    ut,
    type SupportedLocale,
} from "@/base/i18n";
import log from "@/base/log";
import { savedLogs } from "@/base/log-web";
import { customAPIHost } from "@/base/origins";
import { downloadString } from "@/base/utils/web";
import { DeleteAccount } from "@/new/photos/components/DeleteAccount";
import { DropdownInput } from "@/new/photos/components/DropdownInput";
import { MLSettings } from "@/new/photos/components/sidebar/MLSettings";
import { TwoFactorSettings } from "@/new/photos/components/sidebar/TwoFactorSettings";
import {
    confirmDisableMapsDialogAttributes,
    confirmEnableMapsDialogAttributes,
} from "@/new/photos/components/utils/dialog";
import { downloadAppDialogAttributes } from "@/new/photos/components/utils/download";
import {
    useSettingsSnapshot,
    useUserDetailsSnapshot,
} from "@/new/photos/components/utils/use-snapshot";
import {
    ARCHIVE_SECTION,
    DUMMY_UNCATEGORIZED_COLLECTION,
    TRASH_SECTION,
} from "@/new/photos/services/collection";
import type { CollectionSummaries } from "@/new/photos/services/collection/ui";
import { isMLSupported } from "@/new/photos/services/ml";
import {
    isDevBuildAndUser,
    syncSettings,
    updateCFProxyDisabledPreference,
    updateMapEnabled,
} from "@/new/photos/services/settings";
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
import { usePhotosAppContext } from "@/new/photos/types/context";
import { initiateEmail, openURL } from "@/new/photos/utils/web";
import {
    FlexWrapper,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import ArchiveOutlinedIcon from "@mui/icons-material/ArchiveOutlined";
import CategoryIcon from "@mui/icons-material/Category";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import CloseIcon from "@mui/icons-material/Close";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import HealthAndSafetyIcon from "@mui/icons-material/HealthAndSafety";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import LockOutlinedIcon from "@mui/icons-material/LockOutlined";
import NorthEastIcon from "@mui/icons-material/NorthEast";
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
    useColorScheme,
} from "@mui/material";
import Typography from "@mui/material/Typography";
import { WatchFolder } from "components/WatchFolder";
import { t } from "i18next";
import { useRouter } from "next/router";
import { GalleryContext } from "pages/gallery";
import React, {
    MouseEventHandler,
    useCallback,
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

type SidebarProps = ModalVisibilityProps & {
    /**
     * The latest UI collections.
     *
     * These are used to obtain data about the uncategorized, hidden and other
     * items shown in the shortcut section within the sidebar.
     */
    collectionSummaries: CollectionSummaries;
    /**
     * Called when the plan selection modal should be shown.
     */
    onShowPlanSelector: () => void;
    /**
     * Called when the export dialog should be shown.
     */
    onShowExport: () => void;
    /**
     * Called when the user should be authenticated again.
     *
     * This will be invoked before sensitive actions, and the action will only
     * proceed if the promise returned by this function is fulfilled.
     */
    onAuthenticateUser: () => Promise<void>;
};

export const Sidebar: React.FC<SidebarProps> = ({
    open,
    onClose,
    collectionSummaries,
    onShowPlanSelector,
    onShowExport,
    onAuthenticateUser,
}) => (
    <RootSidebarDrawer open={open} onClose={onClose}>
        <HeaderSection onCloseSidebar={onClose} />
        <UserDetailsSection sidebarOpen={open} {...{ onShowPlanSelector }} />
        <Stack sx={{ gap: 0.5, mb: 3 }}>
            <ShortcutSection
                onCloseSidebar={onClose}
                collectionSummaries={collectionSummaries}
            />
            <UtilitySection
                onCloseSidebar={onClose}
                {...{ onShowExport, onAuthenticateUser }}
            />
            <Divider sx={{ my: "2px" }} />
            <ExitSection />
            <InfoSection />
        </Stack>
    </RootSidebarDrawer>
);

const RootSidebarDrawer = styled(SidebarDrawer)(({ theme }) => ({
    "& .MuiPaper-root": { padding: theme.spacing(1.5) },
}));

interface SectionProps {
    onCloseSidebar: SidebarProps["onClose"];
}

const HeaderSection: React.FC<SectionProps> = ({ onCloseSidebar }) => (
    <SpacedRow sx={{ my: "4px 4px", pl: "12px" }}>
        <EnteLogo />
        <IconButton
            aria-label={t("close")}
            onClick={onCloseSidebar}
            color="secondary"
        >
            <CloseIcon fontSize="small" />
        </IconButton>
    </SpacedRow>
);

type UserDetailsSectionProps = Pick<SidebarProps, "onShowPlanSelector"> & {
    sidebarOpen: boolean;
};

const UserDetailsSection: React.FC<UserDetailsSectionProps> = ({
    sidebarOpen,
    onShowPlanSelector,
}) => {
    const userDetails = useUserDetailsSnapshot();
    const [memberSubscriptionManageView, setMemberSubscriptionManageView] =
        useState(false);

    const openMemberSubscriptionManage = () =>
        setMemberSubscriptionManageView(true);
    const closeMemberSubscriptionManage = () =>
        setMemberSubscriptionManageView(false);

    useEffect(() => {
        if (sidebarOpen) void syncUserDetails();
    }, [sidebarOpen]);

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
                onShowPlanSelector();
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
                    <SubscriptionStatus
                        {...{ userDetails, onShowPlanSelector }}
                    />
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

type SubscriptionStatusProps = Pick<SidebarProps, "onShowPlanSelector"> & {
    userDetails: UserDetails;
};

const SubscriptionStatus: React.FC<SubscriptionStatusProps> = ({
    userDetails,
    onShowPlanSelector,
}) => {
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
                    onShowPlanSelector();
                }
            } else {
                if (
                    isSubscriptionStripe(userDetails.subscription) &&
                    isSubscriptionPastDue(userDetails.subscription)
                ) {
                    redirectToCustomerPortal();
                } else {
                    onShowPlanSelector();
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
                    components={{ a: <LinkButton onClick={handleClick} /> }}
                />
            );
        }
    }

    if (!message && hasExceededStorageQuota(userDetails)) {
        message = (
            <Trans
                i18nKey={"subscription_info_storage_quota_exceeded"}
                components={{ a: <LinkButton onClick={handleClick} /> }}
            />
        );
    }

    if (!message) return <></>;

    return (
        <Box sx={{ px: 1, pt: 0.5 }}>
            <Typography
                variant="small"
                onClick={handleClick && handleClick}
                sx={{ color: "text.muted", cursor: handleClick && "pointer" }}
            >
                {message}
            </Typography>
        </Box>
    );
};

function MemberSubscriptionManage({ open, userDetails, onClose }) {
    const { showMiniDialog } = useBaseContext();
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

type ShortcutSectionProps = SectionProps & {
    collectionSummaries: SidebarProps["collectionSummaries"];
};

const ShortcutSection: React.FC<ShortcutSectionProps> = ({
    onCloseSidebar,
    collectionSummaries,
}) => {
    const galleryContext = useContext(GalleryContext);
    const [uncategorizedCollectionId, setUncategorizedCollectionID] =
        useState<number>();

    useEffect(() => {
        void getUncategorizedCollection().then((uncat) =>
            setUncategorizedCollectionID(
                uncat?.id ?? DUMMY_UNCATEGORIZED_COLLECTION,
            ),
        );
    }, []);

    const openUncategorizedSection = () => {
        galleryContext.setActiveCollectionID(uncategorizedCollectionId);
        onCloseSidebar();
    };

    const openTrashSection = () => {
        galleryContext.setActiveCollectionID(TRASH_SECTION);
        onCloseSidebar();
    };

    const openArchiveSection = () => {
        galleryContext.setActiveCollectionID(ARCHIVE_SECTION);
        onCloseSidebar();
    };

    const openHiddenSection = () => {
        galleryContext.openHiddenSection(() => {
            onCloseSidebar();
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

type UtilitySectionProps = SectionProps &
    Pick<SidebarProps, "onShowExport" | "onAuthenticateUser">;

const UtilitySection: React.FC<UtilitySectionProps> = ({
    onCloseSidebar,
    onShowExport,
    onAuthenticateUser,
}) => {
    const { showMiniDialog } = useBaseContext();
    const { watchFolderView, setWatchFolderView } = usePhotosAppContext();

    const router = useRouter();

    const { show: showHelp, props: helpVisibilityProps } = useModalVisibility();

    const { show: showAccount, props: accountVisibilityProps } =
        useModalVisibility();
    const { show: showPreferences, props: preferencesVisibilityProps } =
        useModalVisibility();

    const showWatchFolder = () => setWatchFolderView(true);
    const handleCloseWatchFolder = () => setWatchFolderView(false);

    const handleDeduplicate = () => router.push("/duplicates");

    const handleExport = () =>
        isDesktop
            ? onShowExport()
            : showMiniDialog(downloadAppDialogAttributes());

    return (
        <>
            <RowButton
                variant="secondary"
                label={t("account")}
                onClick={showAccount}
            />
            {isDesktop && (
                <RowButton
                    variant="secondary"
                    label={t("watch_folders")}
                    onClick={showWatchFolder}
                />
            )}
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
            <RowButton
                variant="secondary"
                label={t("help")}
                onClick={showHelp}
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
            <Help {...helpVisibilityProps} onRootClose={onCloseSidebar} />
            {isDesktop && (
                <WatchFolder
                    open={watchFolderView}
                    onClose={handleCloseWatchFolder}
                />
            )}
            <Account
                {...accountVisibilityProps}
                onRootClose={onCloseSidebar}
                {...{ onAuthenticateUser }}
            />
            <Preferences
                {...preferencesVisibilityProps}
                onRootClose={onCloseSidebar}
            />
        </>
    );
};

const ExitSection: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();

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
        </>
    );
};

const InfoSection: React.FC = () => {
    const [appVersion, setAppVersion] = useState<string | undefined>();
    const [host, setHost] = useState<string | undefined>();

    useEffect(() => {
        void globalThis.electron?.appVersion().then(setAppVersion);
        void customAPIHost().then(setHost);
    });

    return (
        <>
            <Stack
                sx={{
                    p: "24px 18px 16px 18px",
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

type AccountProps = NestedSidebarDrawerVisibilityProps &
    Pick<SidebarProps, "onAuthenticateUser">;
const Account: React.FC<AccountProps> = ({
    open,
    onClose,
    onRootClose,
    onAuthenticateUser,
}) => {
    const { showMiniDialog } = useBaseContext();

    const router = useRouter();

    const { show: showRecoveryKey, props: recoveryKeyVisibilityProps } =
        useModalVisibility();
    const { show: showTwoFactor, props: twoFactorVisibilityProps } =
        useModalVisibility();
    const { show: showDeleteAccount, props: deleteAccountVisibilityProps } =
        useModalVisibility();

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleChangePassword = () => router.push("/change-password");
    const handleChangeEmail = () => router.push("/change-email");

    const handlePasskeys = async () => {
        onRootClose();
        await openAccountsManagePasskeysPage();
    };

    return (
        <NestedSidebarDrawer {...{ open, onClose }} onRootClose={onRootClose}>
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <SidebarDrawerTitlebar
                    onClose={onClose}
                    title={t("account")}
                    onRootClose={handleRootClose}
                />
                <Stack sx={{ px: "16px", py: "8px", gap: "24px" }}>
                    <RowButtonGroup>
                        <RowButton
                            endIcon={
                                <HealthAndSafetyIcon
                                    sx={{ color: "accent.main" }}
                                />
                            }
                            label={t("recovery_key")}
                            onClick={showRecoveryKey}
                        />
                    </RowButtonGroup>
                    <RowButtonGroup>
                        <RowButton
                            label={t("two_factor")}
                            onClick={showTwoFactor}
                        />
                        <RowButtonDivider />
                        <RowButton
                            label={t("passkeys")}
                            onClick={handlePasskeys}
                        />
                    </RowButtonGroup>
                    <RowButtonGroup>
                        <RowButton
                            label={t("change_password")}
                            onClick={handleChangePassword}
                        />
                        <RowButtonDivider />
                        <RowButton
                            label={t("change_email")}
                            onClick={handleChangeEmail}
                        />
                    </RowButtonGroup>
                    <RowButtonGroup>
                        <RowButton
                            color="critical"
                            label={t("delete_account")}
                            onClick={showDeleteAccount}
                        />
                    </RowButtonGroup>
                </Stack>
            </Stack>
            <RecoveryKey
                {...recoveryKeyVisibilityProps}
                {...{ showMiniDialog }}
            />
            <TwoFactorSettings
                {...twoFactorVisibilityProps}
                onRootClose={onRootClose}
            />
            <DeleteAccount
                {...deleteAccountVisibilityProps}
                {...{ onAuthenticateUser }}
            />
        </NestedSidebarDrawer>
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
        case "ja-JP":
            return "日本語";
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
    const { showMiniDialog } = useBaseContext();

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
    const [isAutoLaunchEnabled, setIsAutoLaunchEnabled] = useState(false);

    const electron = globalThis.electron;

    const refreshAutoLaunchEnabled = useCallback(async () => {
        return electron
            ?.isAutoLaunchEnabled()
            .then((enabled) => setIsAutoLaunchEnabled(enabled));
    }, [electron]);

    useEffect(
        () => void refreshAutoLaunchEnabled(),
        [refreshAutoLaunchEnabled],
    );

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const toggleProxy = () =>
        void updateCFProxyDisabledPreference(!cfUploadProxyDisabled);

    const toggleAutoLaunch = () =>
        void electron?.toggleAutoLaunch().then(refreshAutoLaunchEnabled);

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
                <Stack sx={{ px: "16px", py: "20px", gap: "24px" }}>
                    <Stack>
                        <RowButtonGroup>
                            <RowSwitch
                                label={t("faster_upload")}
                                checked={!cfUploadProxyDisabled}
                                onClick={toggleProxy}
                            />
                        </RowButtonGroup>
                        <RowButtonGroupHint>
                            {t("faster_upload_description")}
                        </RowButtonGroupHint>
                    </Stack>
                    {electron && (
                        <RowButtonGroup>
                            <RowSwitch
                                label={t("open_ente_on_startup")}
                                checked={isAutoLaunchEnabled}
                                onClick={toggleAutoLaunch}
                            />
                        </RowButtonGroup>
                    )}
                </Stack>
            </Stack>
        </NestedSidebarDrawer>
    );
};

const Help: React.FC<NestedSidebarDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const { showMiniDialog } = useBaseContext();

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleHelp = () => openURL("https://help.ente.io/photos/");

    const handleBlog = () => openURL("https://ente.io/blog/");

    const handleRequestFeature = () =>
        openURL("https://github.com/ente-io/ente/discussions");

    const handleSupport = () => initiateEmail("support@ente.io");

    const confirmViewLogs = () =>
        showMiniDialog({
            title: t("view_logs"),
            message: <Trans i18nKey={"view_logs_message"} />,
            continue: { text: t("view_logs"), action: viewLogs },
        });

    const viewLogs = () => {
        log.info("Viewing logs");
        const electron = globalThis.electron;
        if (electron) electron.openLogDirectory();
        else downloadString(savedLogs(), `ente-web-logs-${Date.now()}.txt`);
    };

    return (
        <NestedSidebarDrawer {...{ open, onClose }} onRootClose={onRootClose}>
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <SidebarDrawerTitlebar
                    onClose={onClose}
                    title={t("help")}
                    onRootClose={handleRootClose}
                />
                <Stack sx={{ px: "16px", py: "8px", gap: "24px" }}>
                    <RowButtonGroup>
                        <RowButton
                            endIcon={<InfoOutlinedIcon />}
                            label={t("ente_help")}
                            onClick={handleHelp}
                        />
                    </RowButtonGroup>
                    <RowButtonGroup>
                        <RowButton
                            endIcon={<NorthEastIcon />}
                            label={t("blog")}
                            onClick={handleBlog}
                        />
                        <RowButtonDivider />
                        <RowButton
                            endIcon={<NorthEastIcon />}
                            label={t("request_feature")}
                            onClick={handleRequestFeature}
                        />
                    </RowButtonGroup>
                    <RowButtonGroup>
                        <RowButton
                            endIcon={<ChevronRightIcon />}
                            label={
                                <Tooltip title="support@ente.io">
                                    <Typography sx={{ fontWeight: "medium" }}>
                                        {t("support")}
                                    </Typography>
                                </Tooltip>
                            }
                            onClick={handleSupport}
                        />
                    </RowButtonGroup>
                </Stack>
                <Stack sx={{ px: "16px" }}>
                    <RowButton
                        variant="secondary"
                        label={
                            <Typography variant="mini" color="text.muted">
                                {t("view_logs")}
                            </Typography>
                        }
                        onClick={confirmViewLogs}
                    />
                    {isDevBuildAndUser() && (
                        <RowButton
                            variant="secondary"
                            label={
                                <Typography variant="mini" color="text.muted">
                                    {ut("Test upload")}
                                </Typography>
                            }
                            onClick={testUpload}
                        />
                    )}
                </Stack>
            </Stack>
        </NestedSidebarDrawer>
    );
};
