import { AppContext } from 'pages/_app';
import React, { useContext, useEffect, useState } from 'react';
import { downloadAsFile } from 'utils/file';
import { Trans, useTranslation } from 'react-i18next';

import { addLogLine, getDebugLogs } from 'utils/logging';
import SidebarButton from './Button';
import isElectron from 'is-electron';
import ElectronService from 'services/electron/common';
import Typography from '@mui/material/Typography';
import { isInternalUser } from 'utils/user';
import { testUpload } from '../../../tests/upload.test';
import {
    testZipFileReading,
    testZipWithRootFileReadingTest,
} from '../../../tests/zip-file-reading.test';

export default function DebugSection() {
    const { t } = useTranslation();

    const appContext = useContext(AppContext);
    const [appVersion, setAppVersion] = useState<string>(null);

    useEffect(() => {
        const main = async () => {
            if (isElectron()) {
                const appVersion = await ElectronService.getAppVersion();
                setAppVersion(appVersion);
            }
        };
        main();
    });

    const confirmLogDownload = () =>
        appContext.setDialogMessage({
            title: t('DOWNLOAD_LOGS'),
            content: (
                <Trans i18nKey={'DOWNLOAD_LOGS_MESSAGE'}>
                    <p>
                        This will download debug logs, which you can email to us
                        to help debug your issue.
                    </p>
                    <p>
                        Please note that file names will be included to help
                        track issues with specific files.
                    </p>
                </Trans>
            ),
            proceed: {
                text: t('DOWNLOAD'),
                variant: 'accent',
                action: downloadDebugLogs,
            },
            close: {
                text: t('CANCEL'),
            },
        });

    const downloadDebugLogs = () => {
        addLogLine('exporting logs');
        if (isElectron()) {
            ElectronService.openLogDirectory();
        } else {
            const logs = getDebugLogs();

            downloadAsFile(`debug_logs_${Date.now()}.txt`, logs);
        }
    };

    return (
        <>
            <SidebarButton
                onClick={confirmLogDownload}
                typographyVariant="caption"
                sx={{ fontWeight: 'normal', color: 'text.secondary' }}>
                {t('DOWNLOAD_UPLOAD_LOGS')}
            </SidebarButton>
            {appVersion && (
                <Typography p={1.5} color="text.secondary" variant="caption">
                    {appVersion}
                </Typography>
            )}
            {isInternalUser() && (
                <>
                    <SidebarButton onClick={testUpload}>
                        Test Upload
                    </SidebarButton>
                    <SidebarButton onClick={testZipFileReading}>
                        Test Zip file reading
                    </SidebarButton>
                    <SidebarButton onClick={testZipWithRootFileReadingTest}>
                        Zip with Root file Test
                    </SidebarButton>
                </>
            )}
        </>
    );
}
