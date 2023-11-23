import { OverflowMenuOption } from '@ente/shared/components/OverflowMenu/option';
import React from 'react';

import FileDownloadOutlinedIcon from '@mui/icons-material/FileDownloadOutlined';
import { CollectionActions } from '.';
import { t } from 'i18next';
import EnteSpinner from '@ente/shared/components/EnteSpinner';
interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
    downloadOptionText?: string;
    isDownloadInProgress?: boolean;
}

export function OnlyDownloadCollectionOption({
    handleCollectionAction,
    downloadOptionText = t('DOWNLOAD'),
    isDownloadInProgress,
}: Iprops) {
    return (
        <OverflowMenuOption
            startIcon={
                !isDownloadInProgress ? (
                    <FileDownloadOutlinedIcon />
                ) : (
                    <EnteSpinner size="20px" sx={{ cursor: 'not-allowed' }} />
                )
            }
            onClick={handleCollectionAction(CollectionActions.DOWNLOAD, false)}>
            {downloadOptionText}
        </OverflowMenuOption>
    );
}
