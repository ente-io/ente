import log from "@/next/log";
import { savedLogs } from "@/next/log-web";
import { downloadAsFile } from "@ente/shared/utils";
import Typography from "@mui/material/Typography";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { isInternalUser } from "utils/user";
import { testUpload } from "../../../tests/upload.test";
import {
    testZipFileReading,
    testZipWithRootFileReadingTest,
} from "../../../tests/zip-file-reading.test";

export default function DebugSection() {
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
                <>
                    <EnteMenuItem
                        variant="secondary"
                        onClick={testUpload}
                        label={"Test Upload"}
                    />

                    <EnteMenuItem
                        variant="secondary"
                        onClick={testZipFileReading}
                        label="Test Zip file reading"
                    />

                    <EnteMenuItem
                        variant="secondary"
                        onClick={testZipWithRootFileReadingTest}
                        label="Zip with Root file Test"
                    />
                </>
            )}
        </>
    );
}
