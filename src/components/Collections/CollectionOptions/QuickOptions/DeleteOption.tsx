import { CollectionActions } from '..';
import React from 'react';
import { IconButton, Tooltip } from '@mui/material';
import DeleteOutlinedIcon from '@mui/icons-material/DeleteOutlined';
import constants from 'utils/strings/constants';

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
}

export function DeleteOption({ handleCollectionAction }: Iprops) {
    return (
        <Tooltip title={constants.EMPTY_TRASH}>
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
