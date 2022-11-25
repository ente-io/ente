import { Box, Typography } from '@mui/material';
import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import constants from 'utils/strings/constants';
import PublicShareSwitch from '../switch';
export function ManageDownloadAccess({
    publicShareProp,
    updatePublicShareURLHelper,
    collection,
}) {
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
            title: constants.DISABLE_FILE_DOWNLOAD,
            content: constants.DISABLE_FILE_DOWNLOAD_MESSAGE(),
            close: { text: constants.CANCEL },
            proceed: {
                text: constants.DISABLE,
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
            <Typography mb={0.5}>{constants.FILE_DOWNLOAD}</Typography>
            <PublicShareSwitch
                checked={publicShareProp?.enableDownload ?? false}
                onChange={handleFileDownloadSetting}
            />
        </Box>
    );
}
