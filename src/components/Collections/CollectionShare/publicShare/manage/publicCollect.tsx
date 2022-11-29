import { Box, Typography } from '@mui/material';
import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import constants from 'utils/strings/constants';
import PublicShareSwitch from '../switch';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

export function ManagePublicCollect({
    publicShareProp,
    updatePublicShareURLHelper,
    collection,
}: Iprops) {
    const appContext = useContext(AppContext);

    const handleFileDownloadSetting = () => {
        if (!publicShareProp.enableCollect) {
            enablePublicCollect();
        } else {
            updatePublicShareURLHelper({
                collectionID: collection.id,
                enableCollect: false,
            });
        }
    };

    const enablePublicCollect = () => {
        appContext.setDialogMessage({
            title: constants.ENABLE_PUBLIC_COLLECT,
            content: constants.ENABLE_PUBLIC_COLLECT_MESSAGE(),
            close: { text: constants.CANCEL },
            proceed: {
                text: constants.ENABLE,
                action: () =>
                    updatePublicShareURLHelper({
                        collectionID: collection.id,
                        enableCollect: true,
                    }),
                variant: 'accent',
            },
        });
    };
    return (
        <Box>
            <Typography mb={0.5}>{constants.PUBLIC_COLLECT}</Typography>
            <PublicShareSwitch
                checked={publicShareProp?.enableCollect}
                onChange={handleFileDownloadSetting}
            />
        </Box>
    );
}
