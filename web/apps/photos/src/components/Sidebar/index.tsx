import log from "@/next/log";
import { savedLogs } from "@/next/log-web";
import { downloadAsFile } from "@ente/shared/utils";
import { Divider, Stack } from "@mui/material";
import Typography from "@mui/material/Typography";
import DeleteAccountModal from "components/DeleteAccountModal";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { CollectionSummaries } from "types/collection";
import { isInternalUser } from "utils/user";
import { testUpload } from "../../../tests/upload.test";
import HeaderSection from "./Header";
import HelpSection from "./HelpSection";
import ShortcutSection from "./ShortcutSection";
import UtilitySection from "./UtilitySection";
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
