import log from "@/next/log";
import { savedLogs } from "@/next/log-web";
import { openAccountsManagePasskeysPage } from "@ente/accounts/services/passkey";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import { EnteLogo } from "@ente/shared/components/EnteLogo";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import RecoveryKey from "@ente/shared/components/RecoveryKey";
import ThemeSwitcher from "@ente/shared/components/ThemeSwitcher";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { downloadAsFile } from "@ente/shared/utils";
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
import { EnteDrawer } from "components/EnteDrawer";
import TwoFactorModal from "components/TwoFactor/Modal";
import { WatchFolder } from "components/WatchFolder";
import LinkButton from "components/pages/gallery/LinkButton";
import { NoStyleAnchor } from "components/pages/sharedAlbum/GoToEnte";
import {
    ARCHIVE_SECTION,
    DUMMY_UNCATEGORIZED_COLLECTION,
    TRASH_SECTION,
} from "constants/collection";
import { t } from "i18next";
import isElectron from "is-electron";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import {
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
import { CollectionSummaries } from "types/collection";
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
import { openLink } from "utils/common";
import { getDownloadAppMessage } from "utils/ui";
import { isFamilyAdmin, isPartOfFamily } from "utils/user/family";
import { testUpload } from "../../../tests/upload.test";
import { MemberSubscriptionManage } from "../MemberSubscriptionManage";
import Preferences from "./Preferences";
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
            setData(LS_KEYS.USER, {
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
                message = (
                    <Trans
                        i18nKey={"FREE_SUBSCRIPTION_INFO"}
                        values={{
                            date: userDetails.subscription?.expiryTime,
                        }}
                    />
                );
            } else if (isSubscriptionCancelled(userDetails.subscription)) {
                message = t("RENEWAL_CANCELLED_SUBSCRIPTION_INFO", {
                    date: userDetails.subscription?.expiryTime,
                });
            }
        } else {
            message = (
                <Trans
                    i18nKey={"SUBSCRIPTION_EXPIRED_MESSAGE"}
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
                i18nKey={"STORAGE_QUOTA_EXCEEDED_SUBSCRIPTION_INFO"}
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
                label={t("UNCATEGORIZED")}
                subText={collectionSummaries
                    .get(uncategorizedCollectionId)
                    ?.fileCount.toString()}
            />
            <EnteMenuItem
                startIcon={<ArchiveOutlined />}
                onClick={openArchiveSection}
                variant="captioned"
                label={t("ARCHIVE_SECTION_NAME")}
                subText={collectionSummaries
                    .get(ARCHIVE_SECTION)
                    ?.fileCount.toString()}
            />
            <EnteMenuItem
                startIcon={<VisibilityOff />}
                onClick={openHiddenSection}
                variant="captioned"
                label={t("HIDDEN")}
                subIcon={<LockOutlined />}
            />
            <EnteMenuItem
                startIcon={<DeleteOutline />}
                onClick={openTrashSection}
                variant="captioned"
                label={t("TRASH")}
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
        setDialogMessage,
        startLoading,
        watchFolderView,
        setWatchFolderView,
        themeColor,
        setThemeColor,
    } = appContext;

    const [recoverModalView, setRecoveryModalView] = useState(false);
    const [twoFactorModalView, setTwoFactorModalView] = useState(false);
    const [preferencesView, setPreferencesView] = useState(false);

    const openPreferencesOptions = () => setPreferencesView(true);
    const closePreferencesOptions = () => setPreferencesView(false);

    const openRecoveryKeyModal = () => setRecoveryModalView(true);
    const closeRecoveryKeyModal = () => setRecoveryModalView(false);

    const openTwoFactorModal = () => setTwoFactorModalView(true);
    const closeTwoFactorModal = () => setTwoFactorModalView(false);

    const openWatchFolder = () => {
        if (isElectron()) {
            setWatchFolderView(true);
        } else {
            setDialogMessage(getDownloadAppMessage());
        }
    };
    const closeWatchFolder = () => setWatchFolderView(false);

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

        try {
            await openAccountsManagePasskeysPage();
        } catch (e) {
            log.error("failed to redirect to accounts page", e);
        }
    };

    const redirectToDeduplicatePage = () => router.push(PAGES.DEDUPLICATE);

    const somethingWentWrong = () =>
        setDialogMessage({
            title: t("ERROR"),
            content: t("RECOVER_KEY_GENERATION_FAILED"),
            close: { variant: "critical" },
        });

    const toggleTheme = () => {
        setThemeColor(
            themeColor === THEME_COLOR.DARK
                ? THEME_COLOR.LIGHT
                : THEME_COLOR.DARK,
        );
    };

    return (
        <>
            {isElectron() && (
                <EnteMenuItem
                    onClick={openWatchFolder}
                    variant="secondary"
                    label={t("WATCH_FOLDERS")}
                />
            )}
            <EnteMenuItem
                variant="secondary"
                onClick={openRecoveryKeyModal}
                label={t("RECOVERY_KEY")}
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
                onClick={openTwoFactorModal}
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
                onClick={openPreferencesOptions}
                label={t("PREFERENCES")}
            />
            <RecoveryKey
                isMobile={appContext.isMobile}
                show={recoverModalView}
                onHide={closeRecoveryKeyModal}
                somethingWentWrong={somethingWentWrong}
            />
            <TwoFactorModal
                show={twoFactorModalView}
                onHide={closeTwoFactorModal}
                closeSidebar={closeSidebar}
                setLoading={startLoading}
            />
            {isElectron() && (
                <WatchFolder
                    open={watchFolderView}
                    onClose={closeWatchFolder}
                />
            )}
            <Preferences
                open={preferencesView}
                onClose={closePreferencesOptions}
                onRootClose={closeSidebar}
            />
        </>
    );
};

const HelpSection: React.FC = () => {
    const { setDialogMessage } = useContext(AppContext);
    const { openExportModal } = useContext(GalleryContext);

    const openRoadmap = () =>
        openLink("https://github.com/ente-io/ente/discussions", true);

    const contactSupport = () => openLink("mailto:support@ente.io", true);

    function openExport() {
        if (isElectron()) {
            openExportModal();
        } else {
            setDialogMessage(getDownloadAppMessage());
        }
    }

    return (
        <>
            <EnteMenuItem
                onClick={openRoadmap}
                label={t("REQUEST_FEATURE")}
                variant="secondary"
            />
            <EnteMenuItem
                onClick={contactSupport}
                labelComponent={
                    <NoStyleAnchor href="mailto:support@ente.io">
                        <Typography fontWeight={"bold"}>
                            {t("SUPPORT")}
                        </Typography>
                    </NoStyleAnchor>
                }
                variant="secondary"
            />
            <EnteMenuItem
                onClick={openExport}
                label={t("EXPORT")}
                endIcon={
                    exportService.isExportInProgress() && (
                        <EnteSpinner size="20px" />
                    )
                }
                variant="secondary"
            />
        </>
    );
};

const ExitSection: React.FC = () => {
    const { setDialogMessage, logout } = useContext(AppContext);

    const [deleteAccountModalView, setDeleteAccountModalView] = useState(false);

    const closeDeleteAccountModal = () => setDeleteAccountModalView(false);
    const openDeleteAccountModal = () => setDeleteAccountModalView(true);

    const confirmLogout = () => {
        setDialogMessage({
            title: t("LOGOUT_MESSAGE"),
            proceed: {
                text: t("LOGOUT"),
                action: logout,
                variant: "critical",
            },
            close: { text: t("CANCEL") },
        });
    };

    return (
        <>
            <EnteMenuItem
                onClick={confirmLogout}
                color="critical"
                label={t("LOGOUT")}
                variant="secondary"
            />
            <EnteMenuItem
                onClick={openDeleteAccountModal}
                color="critical"
                variant="secondary"
                label={t("DELETE_ACCOUNT")}
            />
            <DeleteAccountModal
                open={deleteAccountModalView}
                onClose={closeDeleteAccountModal}
            />
        </>
    );
};

const DebugSection: React.FC = () => {
    const appContext = useContext(AppContext);
    const [appVersion, setAppVersion] = useState<string | undefined>();

    const electron = globalThis.electron;

    useEffect(() => {
        electron?.appVersion().then((v) => setAppVersion(v));
    });

    const confirmLogDownload = () =>
        appContext.setDialogMessage({
            title: t("DOWNLOAD_LOGS"),
            content: <Trans i18nKey={"DOWNLOAD_LOGS_MESSAGE"} />,
            proceed: {
                text: t("DOWNLOAD"),
                variant: "accent",
                action: downloadLogs,
            },
            close: {
                text: t("CANCEL"),
            },
        });

    const downloadLogs = () => {
        log.info("Downloading logs");
        if (electron) electron.openLogDirectory();
        else downloadAsFile(`debug_logs_${Date.now()}.txt`, savedLogs());
    };

    return (
        <>
            <EnteMenuItem
                onClick={confirmLogDownload}
                variant="mini"
                label={t("DOWNLOAD_UPLOAD_LOGS")}
            />
            {appVersion && (
                <Typography
                    py={"14px"}
                    px={"16px"}
                    color="text.muted"
                    variant="mini"
                >
                    {appVersion}
                </Typography>
            )}
            {isInternalUserViaEmailCheck() && (
                <EnteMenuItem
                    variant="secondary"
                    onClick={testUpload}
                    label={"Test Upload"}
                />
            )}
        </>
    );
};

// TODO: Legacy synchronous check, use the one for feature-flags.ts instead.
const isInternalUserViaEmailCheck = () => {
    const userEmail = getData(LS_KEYS.USER)?.email;
    if (!userEmail) return false;

    return userEmail.endsWith("@ente.io");
};
