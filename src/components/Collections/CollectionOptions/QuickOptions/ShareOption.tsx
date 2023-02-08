import { CollectionActions } from '..';
import React from 'react';
import PeopleIcon from '@mui/icons-material/People';
import { IconButton, Tooltip } from '@mui/material';
import constants from 'utils/strings/constants';

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
    tooltipTitle?: string;
}

export function ShareOption({
    handleCollectionAction,
    tooltipTitle = constants.SHARE_COLLECTION,
}: Iprops) {
    return (
        <Tooltip title={tooltipTitle}>
            <IconButton
                onClick={handleCollectionAction(
                    CollectionActions.SHOW_SHARE_DIALOG,
                    false
                )}>
                <PeopleIcon />
            </IconButton>
        </Tooltip>
    );
}
