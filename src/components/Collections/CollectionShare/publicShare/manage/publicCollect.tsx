import { Box, Typography } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
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
    const { t } = useTranslation();
    const handleFileDownloadSetting = () => {
        updatePublicShareURLHelper({
            collectionID: collection.id,
            enableCollect: !publicShareProp.enableCollect,
        });
    };

    return (
        <Box>
            <Typography mb={0.5}>{t('PUBLIC_COLLECT')}</Typography>
            <PublicShareSwitch
                checked={publicShareProp?.enableCollect}
                onChange={handleFileDownloadSetting}
            />
        </Box>
    );
}
