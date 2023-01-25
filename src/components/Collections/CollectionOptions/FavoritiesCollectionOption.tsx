import { OverflowMenuOption } from 'components/OverflowMenu/option';
import React from 'react';

import FileDownloadOutlinedIcon from '@mui/icons-material/FileDownloadOutlined';
import constants from 'utils/strings/constants';
import { CollectionActions } from '.';

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
}

export function FavoritiesCollectionOption({ handleCollectionAction }: Iprops) {
    return (
        <OverflowMenuOption
            startIcon={<FileDownloadOutlinedIcon />}
            onClick={handleCollectionAction(
                CollectionActions.CONFIRM_DOWNLOAD,
                false
            )}>
            {constants.DOWNLOAD_COLLECTION}
        </OverflowMenuOption>
    );
}
