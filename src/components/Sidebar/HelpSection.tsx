import React, { useContext, useState } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
import ExportModal from 'components/ExportModal';
import exportService from 'services/exportService';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import isElectron from 'is-electron';
import { initiateEmail } from 'utils/common';
import { AppContext } from 'pages/_app';
import EnteSpinner from 'components/EnteSpinner';
import { getDownloadAppMessage } from 'utils/ui';

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
            setDialogMessage(getDownloadAppMessage());
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
