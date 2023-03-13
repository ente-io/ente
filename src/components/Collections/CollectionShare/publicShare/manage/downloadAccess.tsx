import { Box, Typography } from '@mui/material';
import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import { Trans, useTranslation } from 'react-i18next';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import PublicShareSwitch from '../switch';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

export function ManageDownloadAccess({
    publicShareProp,
    updatePublicShareURLHelper,
    collection,
}: Iprops) {
    const { t } = useTranslation();

    const appContext = useContext(AppContext);

    const handleFileDownloadSetting = () => {
        if (publicShareProp.enableDownload) {
            disableFileDownload();
        } else {
            updatePublicShareURLHelper({
                collectionID: collection.id,
                enableDownload: true,
            });
        }
    };

    const disableFileDownload = () => {
        appContext.setDialogMessage({
            title: t('DISABLE_FILE_DOWNLOAD'),
            content: (
                <Trans>
                    <p>
                        Are you sure that you want to disable the download
                        button for files?{' '}
                    </p>{' '}
                    <p>
                        Viewers can still take screenshots or save a copy of
                        your photos using external tools{' '}
                    </p>
                </Trans>
            ),
            close: { text: t('CANCEL') },
            proceed: {
                text: t('DISABLE'),
                action: () =>
                    updatePublicShareURLHelper({
                        collectionID: collection.id,
                        enableDownload: false,
                    }),
                variant: 'danger',
            },
        });
    };
    return (
        <Box>
            <Typography mb={0.5}>{t('FILE_DOWNLOAD')}</Typography>
            <PublicShareSwitch
                checked={publicShareProp?.enableDownload ?? true}
                onChange={handleFileDownloadSetting}
            />
        </Box>
    );
}
