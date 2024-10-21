import { RecoveryKey } from "@/accounts/components/RecoveryKey";
import { openAccountsManagePasskeysPage } from "@/accounts/services/passkey";
import { isDesktop } from "@/base/app";
import { EnteDrawer } from "@/base/components/EnteDrawer";
import { EnteLogo } from "@/base/components/EnteLogo";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { useModalVisibility } from "@/base/components/utils/modal";
import log from "@/base/log";
import { savedLogs } from "@/base/log-web";
import { customAPIHost } from "@/base/origins";
import { downloadString } from "@/base/utils/web";
import { downloadAppDialogAttributes } from "@/new/photos/components/utils/download";
import {
    ARCHIVE_SECTION,
    DUMMY_UNCATEGORIZED_COLLECTION,
    TRASH_SECTION,
} from "@/new/photos/services/collection";
import type { CollectionSummaries } from "@/new/photos/services/collection/ui";
import { AppContext, useAppContext } from "@/new/photos/types/context";
import { initiateEmail, openURL } from "@/new/photos/utils/web";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import ThemeSwitcher from "@ente/shared/components/ThemeSwitcher";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import {
    LS_KEYS,
    getData,
    setData,
    setLSUser,
} from "@ente/shared/storage/localStorage";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import ArchiveOutlined from "@mui/icons-material/ArchiveOutlined";
import CategoryIcon from "@mui/icons-material/Category";
import CloseIcon from "@mui/icons-material/Close";
import DeleteOutline from "@mui/icons-material/DeleteOutline";
import LockOutlined from "@mui/icons-material/LockOutlined";
import VisibilityOff from "@mui/icons-material/VisibilityOff";
import {
    Box,
    Divider,
    IconButton,
    Skeleton,
    Stack,
    styled,
} from "@mui/material";
import Typography from "@mui/material/Typography";
import DeleteAccountModal from "components/DeleteAccountModal";
import TwoFactorModal from "components/TwoFactor/Modal";
import { WatchFolder } from "components/WatchFolder";
import LinkButton from "components/pages/gallery/LinkButton";
import { t } from "i18next";
import isElectron from "is-electron";
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
import billingService from "services/billingService";
import { getUncategorizedCollection } from "services/collectionService";
import exportService from "services/export";
import { getUserDetailsV2 } from "services/userService";
import { UserDetails } from "types/user";
import {
    hasAddOnBonus,
    hasExceededStorageQuota,
    hasPaidSubscription,
    hasStripeSubscription,
    isOnFreePlan,
    isSubscriptionActive,
    isSubscriptionCancelled,
    isSubscriptionPastDue,
} from "utils/billing";
import { isFamilyAdmin, isPartOfFamily } from "utils/user/family";
import { testUpload } from "../../../tests/upload.test";
import { MemberSubscriptionManage } from "../MemberSubscriptionManage";
import { Preferences } from "./Preferences";
import SubscriptionCard from "./SubscriptionCard";

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
        <DrawerSidebar open={sidebarView} onClose={closeSidebar}>
            <HeaderSection closeSidebar={closeSidebar} />
            <Divider />
            <UserDetailsSection sidebarView={sidebarView} />
            <Stack spacing={0.5} mb={3}>
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
        </DrawerSidebar>
    );
}

const DrawerSidebar = styled(EnteDrawer)(({ theme }) => ({
    "& .MuiPaper-root": {
        padding: theme.spacing(1.5),
    },
}));

DrawerSidebar.defaultProps = { anchor: "left" };

interface HeaderSectionProps {
    closeSidebar: () => void;
}

const HeaderSection: React.FC<HeaderSectionProps> = ({ closeSidebar }) => {
    return (
        <SpaceBetweenFlex mt={0.5} mb={1} pl={1.5}>
            <EnteLogo />
            <IconButton
                aria-label="close"
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

    const [userDetails, setUserDetails] = useLocalState<
        UserDetails | undefined
    >(LS_KEYS.USER_DETAILS, undefined);
    const [memberSubscriptionManageView, setMemberSubscriptionManageView] =
        useState(false);

    const openMemberSubscriptionManage = () =>
        setMemberSubscriptionManageView(true);
    const closeMemberSubscriptionManage = () =>
        setMemberSubscriptionManageView(false);

    useEffect(() => {
        if (!sidebarView) {
            return;
        }
        const main = async () => {
            const userDetails = await getUserDetailsV2();
            setUserDetails(userDetails);
            setData(LS_KEYS.SUBSCRIPTION, userDetails.subscription);
            setData(LS_KEYS.FAMILY_DATA, userDetails.familyData);
            await setLSUser({
                ...getData(LS_KEYS.USER),
                email: userDetails.email,
            });
        };
        main();
    }, [sidebarView]);

    const isMemberSubscription = useMemo(
        () =>
            userDetails &&
            isPartOfFamily(userDetails.familyData) &&
            !isFamilyAdmin(userDetails.familyData),
        [userDetails],
    );

    const handleSubscriptionCardClick = () => {
        if (isMemberSubscription) {
            openMemberSubscriptionManage();
        } else {
            if (
                userDetails &&
                hasStripeSubscription(userDetails.subscription) &&
                isSubscriptionPastDue(userDetails.subscription)
            ) {
                billingService.redirectToCustomerPortal();
            } else {
                galleryContext.showPlanSelectorModal();
            }
        }
    };

    return (
        <>
            <Box px={0.5} mt={2} pb={1.5} mb={1}>
                <Typography px={1} pb={1} color="text.muted">
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
                <SubscriptionStatus userDetails={userDetails} />
            </Box>
            {isMemberSubscription && (
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
        if (!userDetails) {
            return false;
        }
        if (
            isPartOfFamily(userDetails.familyData) &&
            !isFamilyAdmin(userDetails.familyData)
        ) {
            return false;
        }
        if (
            hasPaidSubscription(userDetails.subscription) &&
            !isSubscriptionCancelled(userDetails.subscription)
        ) {
            return false;
        }
        return true;
    }, [userDetails]);

    const handleClick = useMemo(() => {
        const eventHandler: MouseEventHandler<HTMLSpanElement> = (e) => {
            e.stopPropagation();
            if (userDetails) {
                if (isSubscriptionActive(userDetails.subscription)) {
                    if (hasExceededStorageQuota(userDetails)) {
                        showPlanSelectorModal();
                    }
                } else {
                    if (
                        hasStripeSubscription(userDetails.subscription) &&
                        isSubscriptionPastDue(userDetails.subscription)
                    ) {
                        billingService.redirectToCustomerPortal();
                    } else {
                        showPlanSelectorModal();
                    }
                }
            }
        };
        return eventHandler;
    }, [userDetails]);

    if (!hasAMessage) {
        return <></>;
    }

    let message: React.ReactNode;
    if (!hasAddOnBonus(userDetails.bonusData)) {
        if (isSubscriptionActive(userDetails.subscription)) {
            if (isOnFreePlan(userDetails.subscription)) {
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
        <Box px={1} pt={0.5}>
            <Typography
                variant="small"
                color={"text.muted"}
                onClick={handleClick && handleClick}
                sx={{ cursor: handleClick && "pointer" }}
            >
                {message}
            </Typography>
        </Box>
    );
};

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
                startIcon={<ArchiveOutlined />}
                onClick={openArchiveSection}
                variant="captioned"
                label={t("section_archive")}
                subText={collectionSummaries
                    .get(ARCHIVE_SECTION)
                    ?.fileCount.toString()}
            />
            <EnteMenuItem
                startIcon={<VisibilityOff />}
                onClick={openHiddenSection}
                variant="captioned"
                label={t("section_hidden")}
                subIcon={<LockOutlined />}
            />
            <EnteMenuItem
                startIcon={<DeleteOutline />}
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
    const appContext = useContext(AppContext);
    const {
        startLoading,
        watchFolderView,
        setWatchFolderView,
        themeColor,
        setThemeColor,
        showMiniDialog,
    } = appContext;

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

    const redirectToDeduplicatePage = () => router.push(PAGES.DEDUPLICATE);

    const toggleTheme = () =>
        setThemeColor(
            themeColor === THEME_COLOR.DARK
                ? THEME_COLOR.LIGHT
                : THEME_COLOR.DARK,
        );

    return (
        <>
            {isElectron() && (
                <EnteMenuItem
                    onClick={showWatchFolder}
                    variant="secondary"
                    label={t("WATCH_FOLDERS")}
                />
            )}
            <EnteMenuItem
                variant="secondary"
                onClick={showRecoveryKey}
                label={t("recovery_key")}
            />
            {isInternalUserViaEmailCheck() && (
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
                label={t("TWO_FACTOR")}
            />
            <EnteMenuItem
                variant="secondary"
                onClick={redirectToAccountsPage}
                label={t("passkeys")}
            />

            <EnteMenuItem
                variant="secondary"
                onClick={redirectToChangePasswordPage}
                label={t("CHANGE_PASSWORD")}
            />
            <EnteMenuItem
                variant="secondary"
                onClick={redirectToChangeEmailPage}
                label={t("CHANGE_EMAIL")}
            />
            <EnteMenuItem
                variant="secondary"
                onClick={redirectToDeduplicatePage}
                label={t("DEDUPLICATE_FILES")}
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
            <TwoFactorModal
                {...twoFactorVisibilityProps}
                closeSidebar={closeSidebar}
                setLoading={startLoading}
            />
            {isElectron() && (
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
                label={t("EXPORT")}
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
            {isInternalUserViaEmailCheck() && (
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
            <Stack py={"14px"} px={"16px"} gap={"24px"} color="text.muted">
                {appVersion && (
                    <Typography variant="mini">{appVersion}</Typography>
                )}
                {host && <Typography variant="mini">{host}</Typography>}
            </Stack>
        </>
    );
};

// TODO: Legacy synchronous check, use the one for feature-flags.ts instead.
const isInternalUserViaEmailCheck = () => {
    const userEmail = getData(LS_KEYS.USER)?.email;
    if (!userEmail) return false;

    return userEmail.endsWith("@ente.io");
};
