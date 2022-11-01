import React, { useContext, useState } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
import ExportModal from 'components/ExportModal';
import exportService from 'services/exportService';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import isElectron from 'is-electron';
import { AppContext } from 'pages/_app';
import EnteSpinner from 'components/EnteSpinner';
import { getDownloadAppMessage } from 'utils/ui';
import { NoStyleAnchor } from 'components/pages/sharedAlbum/GoToEnte';
import { openLink } from 'utils/common';

export default function HelpSection() {
    const [exportModalView, setExportModalView] = useState(false);

    const { setDialogMessage } = useContext(AppContext);

    function openFeedbackURL() {
        const feedbackURL: string = `${getEndpoint()}/users/feedback?token=${encodeURIComponent(
            getToken()
        )}`;
        openLink(feedbackURL, true);
    }

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
            <SidebarButton
                LinkComponent={NoStyleAnchor}
                href="mailto:contact@ente.io">
                {constants.SUPPORT}
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
