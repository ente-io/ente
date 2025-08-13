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
    Dialog,
    DialogContent,
    Divider,
    IconButton,
    Skeleton,
    Stack,
    styled,
    TextField,
    Tooltip,
    useColorScheme,
} from "@mui/material";
import Typography from "@mui/material/Typography";
import { WatchFolder } from "components/WatchFolder";
import { RecoveryKey } from "ente-accounts/components/RecoveryKey";
import { openAccountsManagePasskeysPage } from "ente-accounts/services/passkey";
import { isDesktop } from "ente-base/app";
import { EnteLogo, EnteLogoBox } from "ente-base/components/EnteLogo";
import { LinkButton } from "ente-base/components/LinkButton";
import {
    RowButton,
    RowButtonDivider,
    RowButtonEndActivityIndicator,
    RowButtonGroup,
    RowButtonGroupHint,
    RowSwitch,
} from "ente-base/components/RowButton";
import { SpacedRow } from "ente-base/components/containers";
import { DialogCloseIconButton } from "ente-base/components/mui/DialogCloseIconButton";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import {
    SidebarDrawer,
    TitledNestedSidebarDrawer,
    type NestedSidebarDrawerVisibilityProps,
} from "ente-base/components/mui/SidebarDrawer";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import { isHTTPErrorWithStatus } from "ente-base/http";
import {
    getLocaleInUse,
    pt,
    setLocaleInUse,
    supportedLocales,
    ut,
    type SupportedLocale,
} from "ente-base/i18n";
import log from "ente-base/log";
import { savedLogs } from "ente-base/log-web";
import { customAPIHost } from "ente-base/origins";
import { saveStringAsFile } from "ente-base/utils/web";
import {
    isHLSGenerationSupported,
    toggleHLSGeneration,
} from "ente-gallery/services/video";
import { DeleteAccount } from "ente-new/photos/components/DeleteAccount";
import { DropdownInput } from "ente-new/photos/components/DropdownInput";
import { MLSettings } from "ente-new/photos/components/sidebar/MLSettings";
import { TwoFactorSettings } from "ente-new/photos/components/sidebar/TwoFactorSettings";
import {
    confirmDisableMapsDialogAttributes,
    confirmEnableMapsDialogAttributes,
} from "ente-new/photos/components/utils/dialog-attributes";
import { downloadAppDialogAttributes } from "ente-new/photos/components/utils/download";
import {
    useHLSGenerationStatusSnapshot,
    useSettingsSnapshot,
    useUserDetailsSnapshot,
} from "ente-new/photos/components/utils/use-snapshot";
import {
    PseudoCollectionID,
    type CollectionSummaries,
} from "ente-new/photos/services/collection-summary";
import exportService from "ente-new/photos/services/export";
import { isMLSupported } from "ente-new/photos/services/ml";
import {
    isDevBuildAndUser,
    pullSettings,
    updateCFProxyDisabledPreference,
    updateCustomDomain,
    updateMapEnabled,
} from "ente-new/photos/services/settings";
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
    pullUserDetails,
    redirectToCustomerPortal,
    userDetailsAddOnBonuses,
    type UserDetails,
} from "ente-new/photos/services/user-details";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { initiateEmail, openURL } from "ente-new/photos/utils/web";
import { wait } from "ente-utils/promise";
import { useFormik } from "formik";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useState,
    type MouseEventHandler,
} from "react";
import { Trans } from "react-i18next";
import { testUpload } from "../../tests/upload.test";
import { SubscriptionCard } from "./SubscriptionCard";

type SidebarProps = ModalVisibilityProps & {
    /**
     * Information about non-hidden collections and pseudo-collections.
     *
     * These are used to obtain data about the archive, hidden and trash
     * "section" entries shown within the shortcut section of the sidebar.
     */
    normalCollectionSummaries: CollectionSummaries;
    /**
     * The ID of the collection summary that should be shown when the user
     * activates the "Uncategorized" section shortcut.
     */
    uncategorizedCollectionSummaryID: number;
    /**
     * Called when the plan selection modal should be shown.
     */
    onShowPlanSelector: () => void;
    /**
     * Called when the collection summary with the given {@link collectionID}
     * should be shown.
     *
     * @param collectionSummaryID The ID of the {@link CollectionSummary} to
     * switch to.
     *
     * @param isHiddenCollectionSummary If `true`, then any reauthentication as
     * appropriate before switching to the hidden section of the app is
     * performed first before showing the collection summary.
     *
     * @return A promise that fullfills after any needed reauthentication has
     * been peformed (The view transition might still be in progress).
     */
    onShowCollectionSummary: (
        collectionSummaryID: number,
        isHiddenCollectionSummary?: boolean,
    ) => Promise<void>;
    /**
     * Called when the export dialog should be shown.
     */
    onShowExport: () => void;
    /**
     * Called when the user should be authenticated again.
     *
     * This will be invoked before sensitive actions, and the action will only
     * proceed if the promise returned by this function is fulfilled.
     *
     * On errors or if the user cancels the reauthentication, the promise will
     * not settle.
     */
    onAuthenticateUser: () => Promise<void>;
};

export const Sidebar: React.FC<SidebarProps> = ({
    open,
    onClose,
    normalCollectionSummaries,
    uncategorizedCollectionSummaryID,
    onShowPlanSelector,
    onShowCollectionSummary,
    onShowExport,
    onAuthenticateUser,
}) => (
    <RootSidebarDrawer open={open} onClose={onClose}>
        <HeaderSection onCloseSidebar={onClose} />
        <UserDetailsSection sidebarOpen={open} {...{ onShowPlanSelector }} />
        <Stack sx={{ gap: 0.5, mb: 3 }}>
            <ShortcutSection
                onCloseSidebar={onClose}
                {...{
                    normalCollectionSummaries,
                    uncategorizedCollectionSummaryID,
                    onShowCollectionSummary,
                }}
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
    <SpacedRow sx={{ mt: "6px", pl: "12px" }}>
        <EnteLogoBox>
            <EnteLogo height={16} />
        </EnteLogoBox>
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
    const {
        show: showManageMemberSubscription,
        props: manageMemberSubscriptionVisibilityProps,
    } = useModalVisibility();

    useEffect(() => {
        if (sidebarOpen) void pullUserDetails();
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
            showManageMemberSubscription();
        } else {
            if (
                userDetails &&
                isSubscriptionStripe(userDetails.subscription) &&
                isSubscriptionPastDue(userDetails.subscription)
            ) {
                // TODO: This makes an API request, so the UI should indicate
                // the await.
                //
                // eslint-disable-next-line @typescript-eslint/no-floating-promises
                redirectToCustomerPortal();
            } else {
                onShowPlanSelector();
            }
        }
    };

    return (
        <>
            <Box sx={{ px: 0.5, mt: 1.5, pb: 1.5, mb: 1 }}>
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
            {isNonAdminFamilyMember && userDetails && (
                <ManageMemberSubscription
                    {...manageMemberSubscriptionVisibilityProps}
                    {...{ userDetails }}
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

    const handleClick: MouseEventHandler<HTMLSpanElement> = useCallback(
        (e) => {
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
                    // eslint-disable-next-line @typescript-eslint/no-floating-promises
                    redirectToCustomerPortal();
                } else {
                    onShowPlanSelector();
                }
            }
        },
        [onShowPlanSelector, userDetails],
    );

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
                    date: userDetails.subscription.expiryTime,
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
                onClick={handleClick}
                sx={{ color: "text.muted" }}
            >
                {message}
            </Typography>
        </Box>
    );
};

type ManageMemberSubscriptionProps = ModalVisibilityProps & {
    userDetails: UserDetails;
};

const ManageMemberSubscription: React.FC<ManageMemberSubscriptionProps> = ({
    open,
    onClose,
    userDetails,
}) => {
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
                <Stack sx={{ alignItems: "center", mx: 2 }}>
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
                    <FocusVisibleButton
                        fullWidth
                        variant="outlined"
                        color="critical"
                        onClick={confirmLeaveFamily}
                    >
                        {t("leave_family_plan")}
                    </FocusVisibleButton>
                </Stack>
            </DialogContent>
        </Dialog>
    );
};

type ShortcutSectionProps = SectionProps &
    Pick<
        SidebarProps,
        | "normalCollectionSummaries"
        | "uncategorizedCollectionSummaryID"
        | "onShowCollectionSummary"
    >;

const ShortcutSection: React.FC<ShortcutSectionProps> = ({
    onCloseSidebar,
    normalCollectionSummaries,
    uncategorizedCollectionSummaryID,
    onShowCollectionSummary,
}) => {
    const handleOpenUncategorizedSection = () =>
        void onShowCollectionSummary(uncategorizedCollectionSummaryID).then(
            onCloseSidebar,
        );

    const handleOpenTrashSection = () =>
        void onShowCollectionSummary(PseudoCollectionID.trash).then(
            onCloseSidebar,
        );

    const handleOpenArchiveSection = () =>
        void onShowCollectionSummary(PseudoCollectionID.archiveItems).then(
            onCloseSidebar,
        );

    const handleOpenHiddenSection = () =>
        void onShowCollectionSummary(PseudoCollectionID.hiddenItems, true)
            // See: [Note: Workarounds for unactionable ARIA warnings]
            .then(() => wait(10))
            .then(onCloseSidebar);

    const summaryCaption = (summaryID: number) =>
        normalCollectionSummaries.get(summaryID)?.fileCount.toString();

    return (
        <>
            <RowButton
                startIcon={<CategoryIcon />}
                label={t("section_uncategorized")}
                caption={summaryCaption(uncategorizedCollectionSummaryID)}
                onClick={handleOpenUncategorizedSection}
            />
            <RowButton
                startIcon={<ArchiveOutlinedIcon />}
                label={t("section_archive")}
                caption={summaryCaption(PseudoCollectionID.archiveItems)}
                onClick={handleOpenArchiveSection}
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
                onClick={handleOpenHiddenSection}
            />
            <RowButton
                startIcon={<DeleteOutlineIcon />}
                label={t("section_trash")}
                caption={summaryCaption(PseudoCollectionID.trash)}
                onClick={handleOpenTrashSection}
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
                        <RowButtonEndActivityIndicator />
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
    const [appVersion, setAppVersion] = useState("");
    const [host, setHost] = useState<string | undefined>("");

    useEffect(() => {
        void globalThis.electron?.appVersion().then(setAppVersion);
        void customAPIHost().then(setHost);
    }, []);

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
        <TitledNestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("account")}
        >
            <Stack sx={{ px: 2, py: 1, gap: 3 }}>
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
                    <RowButton label={t("passkeys")} onClick={handlePasskeys} />
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
        </TitledNestedSidebarDrawer>
    );
};

const Preferences: React.FC<NestedSidebarDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const { show: showDomainSettings, props: domainSettingsVisibilityProps } =
        useModalVisibility();
    const { show: showMapSettings, props: mapSettingsVisibilityProps } =
        useModalVisibility();
    const {
        show: showAdvancedSettings,
        props: advancedSettingsVisibilityProps,
    } = useModalVisibility();
    const { show: showMLSettings, props: mlSettingsVisibilityProps } =
        useModalVisibility();

    const hlsGenStatusSnapshot = useHLSGenerationStatusSnapshot();
    const isHLSGenerationEnabled = !!hlsGenStatusSnapshot?.enabled;

    useEffect(() => {
        if (open) void pullSettings();
    }, [open]);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    return (
        <TitledNestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("preferences")}
        >
            <Stack sx={{ px: 2, py: 1, gap: 3 }}>
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
                {
                    /* TODO: CD */ process.env.NEXT_PUBLIC_ENTE_WIP_CD && (
                        <RowButton
                            label={pt("Custom domains")}
                            endIcon={
                                <Stack
                                    direction="row"
                                    sx={{
                                        alignSelf: "stretch",
                                        alignItems: "center",
                                    }}
                                >
                                    <Box
                                        sx={{
                                            width: "8px",
                                            bgcolor: "stroke.faint",
                                            alignSelf: "stretch",
                                            mr: 0.5,
                                        }}
                                    />
                                    <Box
                                        sx={{
                                            width: "8px",
                                            bgcolor: "stroke.muted",
                                            alignSelf: "stretch",
                                            mr: 0.5,
                                        }}
                                    />
                                    <Box
                                        sx={{
                                            width: "8px",
                                            bgcolor: "stroke.base",
                                            alignSelf: "stretch",
                                            opacity: 0.3,
                                            mr: 1.5,
                                        }}
                                    />
                                    <ChevronRightIcon />
                                </Stack>
                            }
                            onClick={showDomainSettings}
                        />
                    )
                }
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
                {isHLSGenerationSupported && (
                    <RowButtonGroup>
                        <RowSwitch
                            label={t("streamable_videos")}
                            checked={isHLSGenerationEnabled}
                            onClick={() => void toggleHLSGeneration()}
                        />
                    </RowButtonGroup>
                )}
            </Stack>
            <DomainSettings
                {...domainSettingsVisibilityProps}
                onRootClose={onRootClose}
            />
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
        </TitledNestedSidebarDrawer>
    );
};

const LanguageSelector = () => {
    const locale = getLocaleInUse();

    const updateCurrentLocale = (newLocale: SupportedLocale) => {
        void setLocaleInUse(newLocale).then(() => {
            // [Note: Changing locale causes a full reload]
            //
            // A full reload is needed because we use the global `t` instance
            // instead of the useTranslation hook.
            //
            // We also rely on this behaviour by caching various formatters in
            // module static variables that not get updated if the i18n.language
            // changes unless there is a full reload.
            window.location.reload();
        });
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
        case "ar-SA":
            return "اَلْعَرَبِيَّةُ";
        case "tr-TR":
            return "Türkçe";
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

const DomainSettings: React.FC<NestedSidebarDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    return (
        <TitledNestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            // TODO: CD: Translations
            title={pt("Custom domains")}
            // caption={pt("Your albums, your domain")}
            caption="Use your own domain when sharing"
        >
            <DomainSettingsContents />
        </TitledNestedSidebarDrawer>
    );
};

// Separate component to reset state on back.
const DomainSettingsContents: React.FC = () => {
    const { customDomain, customDomainCNAME } = useSettingsSnapshot();

    const formik = useFormik({
        initialValues: { domain: customDomain ?? "" },
        onSubmit: async (values, { setFieldError }) => {
            const domain = values.domain;
            const setValueFieldError = (message: string) =>
                setFieldError("domain", message);

            try {
                await updateCustomDomain(domain);
            } catch (e) {
                log.error(`Failed to submit input ${domain}`, e);
                if (isHTTPErrorWithStatus(e, 400)) {
                    setValueFieldError(pt("Invalid domain"));
                } else if (isHTTPErrorWithStatus(e, 409)) {
                    setValueFieldError(pt("Domain already linked by a user"));
                } else {
                    setValueFieldError(t("generic_error"));
                }
            }
        },
    });

    // TODO: CD: help

    return (
        <Stack sx={{ px: 2, py: "12px" }}>
            <DomainItem title={pt("Link your domain")} ordinal={pt("1")}>
                <form onSubmit={formik.handleSubmit}>
                    <TextField
                        name="domain"
                        value={formik.values.domain}
                        onChange={formik.handleChange}
                        type={"text"}
                        fullWidth
                        autoFocus={true}
                        margin="dense"
                        disabled={formik.isSubmitting}
                        error={!!formik.errors.domain}
                        helperText={
                            formik.errors.domain ??
                            pt("Any domain or subdomain you own")
                        }
                        label={t("Domain")}
                        placeholder={ut("photos.example.org")}
                        sx={{ mb: 2 }}
                    />
                    <LoadingButton
                        fullWidth
                        type="submit"
                        loading={formik.isSubmitting}
                        color="accent"
                    >
                        {customDomain ? pt("Update") : pt("Save")}
                    </LoadingButton>
                </form>
            </DomainItem>
            <Divider sx={{ mt: 4, mb: 2, opacity: 0.5 }} />
            <DomainItem title={pt("Add DNS entry")} ordinal={pt("2")}>
                <Typography sx={{ color: "text.muted" }}>
                    On your DNS provider, add a CNAME from your domain to{" "}
                    <Typography
                        component="span"
                        sx={{ fontWeight: "bold", color: "text.base" }}
                    >
                        {customDomainCNAME}
                    </Typography>
                </Typography>
            </DomainItem>
            <Divider sx={{ mt: 5, mb: 2, opacity: 0.5 }} />
            <DomainItem title={ut("🎉")} ordinal={pt("3")} isEmoji>
                <Typography sx={{ color: "text.muted", mt: 2 }}>
                    Within 1 hour, your public albums will be accessible via
                    your domain!
                </Typography>
                <Typography sx={{ color: "text.muted", mt: 3 }}>
                    For more information, see
                    <Typography component="span" sx={{ color: "accent.main" }}>
                        {" help "}
                    </Typography>
                </Typography>
            </DomainItem>
        </Stack>
    );
};

interface DomainSectionProps {
    title: string;
    ordinal: string;
    isEmoji?: boolean;
}

const DomainItem: React.FC<React.PropsWithChildren<DomainSectionProps>> = ({
    title,
    ordinal,
    isEmoji,
    children,
}) => (
    <Stack>
        <Stack
            direction="row"
            sx={{ alignItems: "center", justifyContent: "space-between" }}
        >
            <Typography variant={isEmoji ? "h3" : "h6"}>{title}</Typography>
            <Typography
                variant="h1"
                sx={{
                    minWidth: "28px",
                    textAlign: "center",
                    color: "stroke.faint",
                }}
            >
                {ordinal}
            </Typography>
        </Stack>
        {children}
    </Stack>
);

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
        <TitledNestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("map")}
        >
            <Stack sx={{ px: 2, py: "20px" }}>
                <RowButtonGroup>
                    <RowSwitch
                        label={t("enabled")}
                        checked={mapEnabled}
                        onClick={confirmToggle}
                    />
                </RowButtonGroup>
            </Stack>
        </TitledNestedSidebarDrawer>
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
        <TitledNestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("advanced")}
        >
            <Stack sx={{ px: 2, py: "20px", gap: 3 }}>
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
        </TitledNestedSidebarDrawer>
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

    const viewLogs = async () => {
        log.info("Viewing logs");
        const electron = globalThis.electron;
        if (electron) {
            await electron.openLogDirectory();
        } else {
            saveStringAsFile(savedLogs(), `ente-web-logs-${Date.now()}.txt`);
        }
    };

    return (
        <TitledNestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("help")}
        >
            <Stack sx={{ px: 2, py: 1, gap: 3 }}>
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
        </TitledNestedSidebarDrawer>
    );
};
