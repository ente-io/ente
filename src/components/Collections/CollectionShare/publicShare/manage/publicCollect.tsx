import { Stack } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import React from 'react';
import { t } from 'i18next';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';

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
            <MenuItemGroup>
                <EnteMenuItem
                    onClick={handleFileDownloadSetting}
                    variant="toggle"
                    checked={publicShareProp?.enableCollect}
                    label={t('PUBLIC_COLLECT')}
                />
            </MenuItemGroup>
            <MenuSectionTitle title={t('PUBLIC_COLLECT_SUBTEXT')} />
        </Stack>
    );
}
