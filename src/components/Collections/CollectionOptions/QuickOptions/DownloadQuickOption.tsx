import { CollectionActions } from '..';
import React from 'react';
import FileDownloadOutlinedIcon from '@mui/icons-material/FileDownloadOutlined';
import { IconButton, Tooltip } from '@mui/material';
import constants from 'utils/strings/constants';
import { CollectionSummaryType } from 'constants/collection';
interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
    collectionSummaryType: CollectionSummaryType;
}

export function DownloadQuickOption({
    handleCollectionAction,
    collectionSummaryType,
}: Iprops) {
    return (
        <Tooltip
            title={
                collectionSummaryType === CollectionSummaryType.favorites
                    ? constants.DOWNLOAD_FAVORITES
                    : collectionSummaryType ===
                      CollectionSummaryType.uncategorized
                    ? constants.DOWNLOAD_UNCATEGORIZED
                    : constants.DOWNLOAD_COLLECTION
            }>
            <IconButton
                onClick={handleCollectionAction(
                    CollectionActions.CONFIRM_DOWNLOAD,
                    false
                )}>
                <FileDownloadOutlinedIcon />
            </IconButton>
        </Tooltip>
    );
}
