import { Stack } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/menuItem';
import React from 'react';
import { t } from 'i18next';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';

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
    const handleFileDownloadSetting = () => {
        updatePublicShareURLHelper({
            collectionID: collection.id,
            enableCollect: !publicShareProp.enableCollect,
        });
    };

    return (
        <Stack>
            <EnteMenuItem
                onClick={handleFileDownloadSetting}
                color="primary"
                hasSwitch
                checked={publicShareProp?.enableCollect}>
                {t('PUBLIC_COLLECT')}
            </EnteMenuItem>
            <MenuSectionTitle title={t('PUBLIC_COLLECT_SUBTEXT')} />
        </Stack>
    );
}
