import { OverflowMenuOption } from 'components/OverflowMenu/option';
import React from 'react';

import DeleteOutlinedIcon from '@mui/icons-material/DeleteOutlined';
import { CollectionActions } from '.';
import { t } from 'i18next';

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
}

export function TrashCollectionOption({ handleCollectionAction }: Iprops) {
    return (
        <OverflowMenuOption
            color="critical"
            startIcon={<DeleteOutlinedIcon />}
            onClick={handleCollectionAction(
                CollectionActions.CONFIRM_EMPTY_TRASH,
                false
            )}>
            {t('EMPTY_TRASH')}
        </OverflowMenuOption>
    );
}
