import { RecoveryKey } from "@/accounts/components/RecoveryKey";
import { openAccountsManagePasskeysPage } from "@/accounts/services/passkey";
import { isDesktop } from "@/base/app";
import { EnteLogo } from "@/base/components/EnteLogo";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { SpaceBetweenFlex } from "@/base/components/mui/Container";
import { SidebarDrawer } from "@/base/components/mui/SidebarDrawer";
import { useIsSmallWidth } from "@/base/components/utils/hooks";
import { useModalVisibility } from "@/base/components/utils/modal";
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
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import ArchiveOutlinedIcon from "@mui/icons-material/ArchiveOutlined";
import CategoryIcon from "@mui/icons-material/Category";
import CloseIcon from "@mui/icons-material/Close";
import DarkModeIcon from "@mui/icons-material/DarkMode";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import LightModeIcon from "@mui/icons-material/LightMode";
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
    ToggleButton,
    ToggleButtonGroup,
} from "@mui/material";
import Typography from "@mui/material/Typography";
import DeleteAccountModal from "components/DeleteAccountModal";
import { WatchFolder } from "components/WatchFolder";
import LinkButton from "components/pages/gallery/LinkButton";
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
import { testUpload } from "../../../tests/upload.test";
import { Preferences } from "./Preferences";
import { SubscriptionCard } from "./SubscriptionCard";

interface Iprops {
    collectionSummaries: CollectionSummaries;
    sidebarView: boolean;
    closeSidebar: () => void;
}

export default function Sidebar({
    collectionSummaries,
    sidebarView,
    closeSidebar,
}: Iprops) {
    return (
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
}

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
        <SpaceBetweenFlex
            sx={{ marginBlock: "4px 4px", paddingInlineStart: "12px" }}
        >
            <EnteLogo />
            <IconButton
                aria-label={t("close")}
                onClick={closeSidebar}
                color="secondary"
            >
                <CloseIcon fontSize="small" />
            </IconButton>
        </SpaceBetweenFlex>
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
            <SpaceBetweenFlex sx={{ p: "20px 8px 12px 16px" }}>
                <Stack>
                    <Typography
                        variant="h3"
                        sx={{
                            fontWeight: "bold",
                        }}
                    >
                        {t("subscription")}
                    </Typography>
                    <Typography sx={{ color: "text.muted" }}>
                        {t("family_plan")}
                    </Typography>
                </Stack>
                <DialogCloseIconButton {...{ onClose }} />
            </SpaceBetweenFlex>
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
            <EnteMenuItem
                startIcon={<CategoryIcon />}
                onClick={openUncategorizedSection}
                variant="captioned"
                label={t("section_uncategorized")}
                subText={collectionSummaries
                    .get(uncategorizedCollectionId)
                    ?.fileCount.toString()}
            />
            <EnteMenuItem
                startIcon={<ArchiveOutlinedIcon />}
                onClick={openArchiveSection}
                variant="captioned"
                label={t("section_archive")}
                subText={collectionSummaries
                    .get(ARCHIVE_SECTION)
                    ?.fileCount.toString()}
            />
            <EnteMenuItem
                startIcon={<VisibilityOffIcon />}
                onClick={openHiddenSection}
                variant="captioned"
                label={t("section_hidden")}
                subIcon={<LockOutlinedIcon />}
            />
            <EnteMenuItem
                startIcon={<DeleteOutlineIcon />}
                onClick={openTrashSection}
                variant="captioned"
                label={t("section_trash")}
                subText={collectionSummaries
                    .get(TRASH_SECTION)
                    ?.fileCount.toString()}
            />
        </>
    );
};

interface UtilitySectionProps {
    closeSidebar: () => void;
}

const UtilitySection: React.FC<UtilitySectionProps> = ({ closeSidebar }) => {
    const router = useRouter();
    const {
        watchFolderView,
        setWatchFolderView,
        themeColor,
        setThemeColor,
        showMiniDialog,
    } = useAppContext();

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

    const redirectToChangeEmailPage = () => {
        closeSidebar();
        router.push(PAGES.CHANGE_EMAIL);
    };

    const redirectToAccountsPage = async () => {
        closeSidebar();
        await openAccountsManagePasskeysPage();
    };

    const handleDeduplicate = () => router.push("/duplicates");

    const toggleTheme = () =>
        setThemeColor(
            themeColor === THEME_COLOR.DARK
                ? THEME_COLOR.LIGHT
                : THEME_COLOR.DARK,
        );

    return (
        <>
            {isDesktop && (
                <EnteMenuItem
                    onClick={showWatchFolder}
                    variant="secondary"
                    label={t("watch_folders")}
                />
            )}
            <EnteMenuItem
                variant="secondary"
                onClick={showRecoveryKey}
                label={t("recovery_key")}
            />
            {isInternalUser() && (
                <EnteMenuItem
                    onClick={toggleTheme}
                    variant="secondary"
                    label={t("CHOSE_THEME")}
                    endIcon={
                        <ThemeSwitcher
                            themeColor={themeColor}
                            setThemeColor={setThemeColor}
                        />
                    }
                />
            )}
            <EnteMenuItem
                variant="secondary"
                onClick={showTwoFactor}
                label={t("two_factor")}
            />
            <EnteMenuItem
                variant="secondary"
                onClick={redirectToAccountsPage}
                label={t("passkeys")}
            />

            <EnteMenuItem
                variant="secondary"
                onClick={redirectToChangePasswordPage}
                label={t("change_password")}
            />
            <EnteMenuItem
                variant="secondary"
                onClick={redirectToChangeEmailPage}
                label={t("change_email")}
            />
            <EnteMenuItem
                variant="secondary"
                onClick={handleDeduplicate}
                label={t("deduplicate_files")}
            />
            <EnteMenuItem
                variant="secondary"
                onClick={showPreferences}
                label={t("preferences")}
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

interface ThemeSwitcherProps {
    themeColor: THEME_COLOR;
    setThemeColor: (themeColor: THEME_COLOR) => void;
}

const ThemeSwitcher: React.FC<ThemeSwitcherProps> = ({
    themeColor,
    setThemeColor,
}) => {
    const handleChange = (event, themeColor: THEME_COLOR) => {
        if (themeColor !== null) {
            setThemeColor(themeColor);
        }
    };

    return (
        <ToggleButtonGroup
            size="small"
            value={themeColor}
            exclusive
            onChange={handleChange}
        >
            <ToggleButton value={THEME_COLOR.LIGHT}>
                <LightModeIcon />
            </ToggleButton>
            <ToggleButton value={THEME_COLOR.DARK}>
                <DarkModeIcon />
            </ToggleButton>
        </ToggleButtonGroup>
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
            <EnteMenuItem
                onClick={requestFeature}
                label={t("request_feature")}
                variant="secondary"
            />
            <EnteMenuItem
                onClick={contactSupport}
                labelComponent={
                    <span title="support@ente.io">{t("support")}</span>
                }
                variant="secondary"
            />
            <EnteMenuItem
                onClick={handleExport}
                label={t("export_data")}
                endIcon={
                    exportService.isExportInProgress() && (
                        <ActivityIndicator size="20px" />
                    )
                }
                variant="secondary"
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
            <EnteMenuItem
                onClick={handleLogout}
                color="critical"
                label={t("logout")}
                variant="secondary"
            />
            <EnteMenuItem
                onClick={showDeleteAccount}
                color="critical"
                variant="secondary"
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
        else downloadString(savedLogs(), `debug_logs_${Date.now()}.txt`);
    };

    return (
        <>
            {isInternalUser() && (
                <EnteMenuItem
                    variant="secondary"
                    onClick={testUpload}
                    label={"Test Upload"}
                />
            )}
            <EnteMenuItem
                onClick={confirmLogDownload}
                variant="mini"
                label={t("debug_logs")}
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
