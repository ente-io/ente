import { OverflowMenuOption } from 'components/OverflowMenu/option';
import React from 'react';
import LogoutIcon from '@mui/icons-material/Logout';
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
            startIcon={<LogoutIcon />}
            onClick={handleCollectionAction(
                CollectionActions.CONFIRM_LEAVE_SHARED_ALBUM,
                false
            )}>
            {constants.LEAVE_ALBUM}
        </OverflowMenuOption>
    );
}
