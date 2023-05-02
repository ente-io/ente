import { useContext } from 'react';
import { t } from 'i18next';

import exportService from 'services/export';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import isElectron from 'is-electron';
import { AppContext } from 'pages/_app';
import EnteSpinner from 'components/EnteSpinner';
import { getDownloadAppMessage } from 'utils/ui';
import { NoStyleAnchor } from 'components/pages/sharedAlbum/GoToEnte';
import { openLink } from 'utils/common';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { Typography } from '@mui/material';
import { GalleryContext } from 'pages/gallery';

export default function HelpSection() {
    const { setDialogMessage } = useContext(AppContext);
    const { openExportModal } = useContext(GalleryContext);

    function openFeedbackURL() {
        const feedbackURL: string = `${getEndpoint()}/users/feedback?token=${encodeURIComponent(
            getToken()
        )}`;
        openLink(feedbackURL, true);
    }

    function handleExportOpen() {
        if (isElectron()) {
            openExportModal();
        } else {
            setDialogMessage(getDownloadAppMessage());
        }
    }

    return (
        <>
            <EnteMenuItem
                onClick={openFeedbackURL}
                label={t('REQUEST_FEATURE')}
                variant="secondary"
            />
            <EnteMenuItem
                onClick={() => openLink('mailto:contact@ente.io', true)}
                labelComponent={
                    <NoStyleAnchor href="mailto:contact@ente.io">
                        <Typography fontWeight={'bold'}>
                            {t('SUPPORT')}
                        </Typography>
                    </NoStyleAnchor>
                }
                variant="secondary"
            />
            <EnteMenuItem
                onClick={handleExportOpen}
                label={t('EXPORT')}
                endIcon={
                    exportService.isExportInProgress() && (
                        <EnteSpinner size="20px" />
                    )
                }
                variant="secondary"
            />
        </>
    );
}
