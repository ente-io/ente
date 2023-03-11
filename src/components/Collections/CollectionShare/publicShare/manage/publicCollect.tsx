import { EnteMenuItem } from 'components/Menu/menuItem';
import React from 'react';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import constants from 'utils/strings/constants';

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
        <EnteMenuItem
            onClick={handleFileDownloadSetting}
            color="primary"
            hasSwitch={true}
            checked={publicShareProp?.enableCollect}>
            {constants.PUBLIC_COLLECT}
        </EnteMenuItem>
    );
}
