import { AppContext } from 'pages/_app';
import React, { useContext, useEffect, useState } from 'react';
import { downloadAsFile } from 'utils/file';
import { Trans } from 'react-i18next';
import { t } from 'i18next';

import { addLogLine, getDebugLogs } from 'utils/logging';
import isElectron from 'is-electron';
import ElectronService from 'services/electron/common';
import Typography from '@mui/material/Typography';
import { isInternalUser } from 'utils/user';
import { testUpload } from '../../../tests/upload.test';
import {
    testZipFileReading,
    testZipWithRootFileReadingTest,
} from '../../../tests/zip-file-reading.test';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';

export default function DebugSection() {
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
            content: <Trans i18nKey={'DOWNLOAD_LOGS_MESSAGE'} />,
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
            <EnteMenuItem
                onClick={confirmLogDownload}
                variant="mini"
                label={t('DOWNLOAD_UPLOAD_LOGS')}
            />
            {appVersion && (
                <Typography
                    py={'14px'}
                    px={'16px'}
                    color="text.muted"
                    variant="mini">
                    {appVersion}
                </Typography>
            )}
            {isInternalUser() && (
                <>
                    <EnteMenuItem
                        variant="secondary"
                        onClick={testUpload}
                        label={'Test Upload'}
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
