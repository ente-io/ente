import { OverflowMenuOption } from 'components/OverflowMenu/option';
import React from 'react';

import DeleteOutlinedIcon from '@mui/icons-material/DeleteOutlined';
import constants from 'utils/strings/constants';
import { CollectionActions } from '.';

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
}

export function SharedCollectionOption({ handleCollectionAction }: Iprops) {
    return (
        <OverflowMenuOption
            color="danger"
            startIcon={<DeleteOutlinedIcon />}
            onClick={handleCollectionAction(
                CollectionActions.CONFIRM_EMPTY_TRASH,
                false
            )}>
            {constants.LEAVE}
        </OverflowMenuOption>
    );
}
