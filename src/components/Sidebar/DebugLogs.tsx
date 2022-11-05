import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import { downloadAsFile } from 'utils/file';
import constants from 'utils/strings/constants';
import { addLogLine, getDebugLogs } from 'utils/logging';
import SidebarButton from './Button';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { User } from 'types/user';
import { getSentryUserID } from 'utils/user';
import isElectron from 'is-electron';
import ElectronService from 'services/electron/common';
import { testUpload } from 'tests/upload.test';

export default function DebugLogs() {
    const appContext = useContext(AppContext);
    const confirmLogDownload = () =>
        appContext.setDialogMessage({
            title: constants.DOWNLOAD_LOGS,
            content: constants.DOWNLOAD_LOGS_MESSAGE(),
            proceed: {
                text: constants.DOWNLOAD,
                variant: 'accent',
                action: downloadDebugLogs,
            },
            close: {
                text: constants.CANCEL,
            },
        });

    const downloadDebugLogs = () => {
        addLogLine(
            'latest commit id :' + process.env.NEXT_PUBLIC_LATEST_COMMIT_HASH
        );
        addLogLine(`user sentry id ${getSentryUserID()}`);
        addLogLine(`ente userID ${(getData(LS_KEYS.USER) as User)?.id}`);
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
            <SidebarButton onClick={testUpload}>test-upload</SidebarButton>
            <SidebarButton
                onClick={confirmLogDownload}
                typographyVariant="caption"
                sx={{ fontWeight: 'normal', color: 'text.secondary' }}>
                {constants.DOWNLOAD_UPLOAD_LOGS}
            </SidebarButton>
        </>
    );
}
