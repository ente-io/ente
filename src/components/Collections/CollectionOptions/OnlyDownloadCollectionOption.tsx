import { OverflowMenuOption } from 'components/OverflowMenu/option';
import React from 'react';

import FileDownloadOutlinedIcon from '@mui/icons-material/FileDownloadOutlined';
import { CollectionActions } from '.';
import { t } from 'i18next';
interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
    downloadOptionText?: string;
}

export function OnlyDownloadCollectionOption({
    handleCollectionAction,
    downloadOptionText = t('DOWNLOAD'),
}: Iprops) {
    return (
        <OverflowMenuOption
            startIcon={<FileDownloadOutlinedIcon />}
            onClick={handleCollectionAction(
                CollectionActions.CONFIRM_DOWNLOAD,
                false
            )}>
            {downloadOptionText}
        </OverflowMenuOption>
    );
}
