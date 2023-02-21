import { CollectionActions } from '..';
import React from 'react';
import PeopleIcon from '@mui/icons-material/People';
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

export function ShareQuickOption({
    handleCollectionAction,
    collectionSummaryType,
}: Iprops) {
    return (
        <Tooltip
            title={
                /*: collectionSummaryType ===
      CollectionSummaryType.incomingShare
    ? constants.SHARING_DETAILS*/
                collectionSummaryType === CollectionSummaryType.outgoingShare ||
                collectionSummaryType ===
                    CollectionSummaryType.sharedOnlyViaLink
                    ? constants.MODIFY_SHARING
                    : constants.SHARE_COLLECTION
            }>
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
