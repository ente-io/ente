import log from "@/next/log";
import { savedLogs } from "@/next/log-web";
import {
    configurePasskeyRecovery,
    isPasskeyRecoveryEnabled,
} from "@ente/accounts/services/passkey";
import { APPS, CLIENT_PACKAGE_NAMES } from "@ente/shared/apps/constants";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import RecoveryKey from "@ente/shared/components/RecoveryKey";
import ThemeSwitcher from "@ente/shared/components/ThemeSwitcher";
import {
    ACCOUNTS_PAGES,
    PHOTOS_PAGES as PAGES,
} from "@ente/shared/constants/pages";
import { getRecoveryKey } from "@ente/shared/crypto/helpers";
import {
    encryptToB64,
    generateEncryptionKey,
} from "@ente/shared/crypto/internal/libsodium";
import { getAccountsURL } from "@ente/shared/network/api";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { downloadAsFile } from "@ente/shared/utils";
import ArchiveOutlined from "@mui/icons-material/ArchiveOutlined";
import CategoryIcon from "@mui/icons-material/Category";
import DeleteOutline from "@mui/icons-material/DeleteOutline";
import LockOutlined from "@mui/icons-material/LockOutlined";
import VisibilityOff from "@mui/icons-material/VisibilityOff";
import { Divider, Stack } from "@mui/material";
import Typography from "@mui/material/Typography";
import DeleteAccountModal from "components/DeleteAccountModal";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import TwoFactorModal from "components/TwoFactor/Modal";
import { WatchFolder } from "components/WatchFolder";
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
import { useContext, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { getUncategorizedCollection } from "services/collectionService";
import exportService from "services/export";
import { getAccountsToken } from "services/userService";
import { CollectionSummaries } from "types/collection";
import { openLink } from "utils/common";
import { getDownloadAppMessage } from "utils/ui";
import { isInternalUser } from "utils/user";
import { testUpload } from "../../../tests/upload.test";
import HeaderSection from "./Header";
import Preferences from "./Preferences";
import { DrawerSidebar } from "./styledComponents";
import UserDetailsSection from "./userDetailsSection";

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
            // check if the user has passkey recovery enabled
            const recoveryEnabled = await isPasskeyRecoveryEnabled();
            if (!recoveryEnabled) {
                // let's create the necessary recovery information
                const recoveryKey = await getRecoveryKey();

                const resetSecret = await generateEncryptionKey();

                const encryptionResult = await encryptToB64(
                    resetSecret,
                    recoveryKey,
                );

                await configurePasskeyRecovery(
                    resetSecret,
                    encryptionResult.encryptedData,
                    encryptionResult.nonce,
                );
            }

            const accountsToken = await getAccountsToken();

            window.open(
                `${getAccountsURL()}${
                    ACCOUNTS_PAGES.ACCOUNT_HANDOFF
                }?package=${CLIENT_PACKAGE_NAMES.get(
                    APPS.PHOTOS,
                )}&token=${accountsToken}`,
            );
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
        setThemeColor((themeColor) =>
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
                onClick={openTwoFactorModal}
                label={t("TWO_FACTOR")}
            />

            {isInternalUser() && (
                <EnteMenuItem
                    variant="secondary"
                    onClick={redirectToAccountsPage}
                    label={t("PASSKEYS")}
                />
            )}

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
                appContext={appContext}
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
            {isInternalUser() && (
                <EnteMenuItem
                    variant="secondary"
                    onClick={testUpload}
                    label={"Test Upload"}
                />
            )}
        </>
    );
};
