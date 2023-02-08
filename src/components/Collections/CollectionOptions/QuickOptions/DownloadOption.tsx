import { CollectionActions } from '..';
import React from 'react';
import FileDownloadOutlinedIcon from '@mui/icons-material/FileDownloadOutlined';
import { IconButton, Tooltip } from '@mui/material';
import constants from 'utils/strings/constants';

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
    tooltipTitle?: String;
}

export function DownloadOption({
    handleCollectionAction,
    tooltipTitle = constants.DOWNLOAD_COLLECTION,
}: Iprops) {
    return (
        <Tooltip title={tooltipTitle}>
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
