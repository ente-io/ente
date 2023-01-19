import { CollectionActions } from '.';
import React from 'react';
import { CollectionSummaryType } from 'constants/collection';
import PeopleIcon from '@mui/icons-material/People';
import FileDownloadOutlinedIcon from '@mui/icons-material/FileDownloadOutlined';
import { FlexWrapper } from 'components/Container';
import { IconButton } from '@mui/material';
interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
    collectionSummaryType: CollectionSummaryType;
}

export function QuickOptions({
    handleCollectionAction,
    collectionSummaryType,
}: Iprops) {
    return (
        <FlexWrapper>
            {!(collectionSummaryType === CollectionSummaryType.trash) && (
                <IconButton>
                    <PeopleIcon
                        onClick={handleCollectionAction(
                            CollectionActions.SHOW_SHARE_DIALOG,
                            false
                        )}
                    />
                </IconButton>
            )}
            {!(
                collectionSummaryType === CollectionSummaryType.incomingShare ||
                collectionSummaryType === CollectionSummaryType.trash
            ) && (
                <IconButton>
                    <FileDownloadOutlinedIcon
                        onClick={handleCollectionAction(
                            CollectionActions.CONFIRM_DOWNLOAD,
                            false
                        )}
                    />
                </IconButton>
            )}
        </FlexWrapper>
    );
}
