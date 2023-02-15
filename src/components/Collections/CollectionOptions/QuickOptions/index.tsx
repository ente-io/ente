import { CollectionActions } from '..';
import React from 'react';
import { CollectionSummaryType } from 'constants/collection';
import { FlexWrapper } from 'components/Container';
import { MoveToTrashOption } from './MoveToTrashOption';
import { DownloadOption } from './DownloadOption';
import { ShareOption } from './ShareOption';
import {
    showDownloadQuickOption,
    showShareQuickOption,
    showTrashQuickOption,
} from 'utils/collection';
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
        <FlexWrapper sx={{ gap: '16px' }}>
            {showTrashQuickOption(collectionSummaryType) && (
                <MoveToTrashOption
                    handleCollectionAction={handleCollectionAction}
                />
            )}
            {showDownloadQuickOption(collectionSummaryType) && (
                <DownloadOption
                    handleCollectionAction={handleCollectionAction}
                    collectionSummaryType={collectionSummaryType}
                />
            )}
            {showShareQuickOption(collectionSummaryType) && (
                <ShareOption
                    handleCollectionAction={handleCollectionAction}
                    collectionSummaryType={collectionSummaryType}
                />
            )}
        </FlexWrapper>
    );
}
