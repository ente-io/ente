import React, { useContext, useState } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
import ExportModal from 'components/ExportModal';
import exportService from 'services/exportService';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import isElectron from 'is-electron';
import { downloadApp, initiateEmail } from 'utils/common';
import { AppContext } from 'pages/_app';
import EnteSpinner from 'components/EnteSpinner';

export default function HelpSection() {
    const [exportModalView, setExportModalView] = useState(true);

    const { setDialogMessage } = useContext(AppContext);

    function openFeedbackURL() {
        const feedbackURL: string = `${getEndpoint()}/users/feedback?token=${encodeURIComponent(
            getToken()
        )}`;
        const win = window.open(feedbackURL, '_blank');
        win.focus();
    }

    const initToSupportMail = () => initiateEmail('contact@ente.io');

    function exportFiles() {
        if (isElectron()) {
            setExportModalView(true);
        } else {
            setDialogMessage({
                title: constants.DOWNLOAD_APP,
                content: constants.DOWNLOAD_APP_MESSAGE,

                proceed: {
                    text: constants.DOWNLOAD,
                    action: downloadApp,
                    variant: 'accent',
                },
                close: {
                    text: constants.CLOSE,
                },
            });
        }
    }

    return (
        <>
            <SidebarButton onClick={openFeedbackURL}>
                {constants.REQUEST_FEATURE}
            </SidebarButton>
            <SidebarButton onClick={initToSupportMail}>
                <a
                    style={{ textDecoration: 'none', color: 'inherit' }}
                    href="mailto:contact@ente.io">
                    {constants.SUPPORT}
                </a>
            </SidebarButton>
            <SidebarButton onClick={exportFiles}>
                <div style={{ display: 'flex' }}>
                    {constants.EXPORT}
                    <div style={{ width: '20px' }} />
                    {exportService.isExportInProgress() && <EnteSpinner />}
                </div>
            </SidebarButton>
            <ExportModal
                show={exportModalView}
                onHide={() => setExportModalView(false)}
            />
        </>
    );
}
