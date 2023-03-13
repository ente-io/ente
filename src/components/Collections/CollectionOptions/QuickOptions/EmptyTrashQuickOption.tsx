import { CollectionActions } from '..';
import React from 'react';
import { IconButton, Tooltip } from '@mui/material';
import DeleteOutlinedIcon from '@mui/icons-material/DeleteOutlined';
import { useTranslation } from 'react-i18next';

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
}

export function EmptyTrashQuickOption({ handleCollectionAction }: Iprops) {
    const { t } = useTranslation();

    return (
        <Tooltip title={t('EMPTY_TRASH')}>
            <IconButton
                onClick={handleCollectionAction(
                    CollectionActions.CONFIRM_EMPTY_TRASH,
                    false
                )}>
                <DeleteOutlinedIcon />
            </IconButton>
        </Tooltip>
    );
}
