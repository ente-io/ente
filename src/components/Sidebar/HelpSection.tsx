import React, { useContext, useState } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
import ExportModal from 'components/ExportModal';
import InProgressIcon from 'components/icons/InProgressIcon';
import exportService from 'services/exportService';
import { convertBytesToHumanReadable } from 'utils/billing';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import isElectron from 'is-electron';
import { downloadApp, initiateEmail } from 'utils/common';
import { GalleryContext } from 'pages/gallery';

export default function HelpSection({ userDetails }) {
    const { setDialogMessage } = useContext(GalleryContext);

    const [exportModalView, setExportModalView] = useState(false);

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
                content: constants.DOWNLOAD_APP_MESSAGE(),
                staticBackdrop: true,
                proceed: {
                    text: constants.DOWNLOAD,
                    action: downloadApp,
                    variant: 'success',
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
                {constants.SUPPORT}
            </SidebarButton>
            <SidebarButton onClick={exportFiles}>
                <div style={{ display: 'flex' }}>
                    {constants.EXPORT}
                    <div style={{ width: '20px' }} />
                    {exportService.isExportInProgress() && <InProgressIcon />}
                </div>
            </SidebarButton>
            <ExportModal
                show={exportModalView}
                onHide={() => setExportModalView(false)}
                usage={convertBytesToHumanReadable(userDetails?.usage ?? 0)}
            />
        </>
    );
}
