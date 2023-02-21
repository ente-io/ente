import { CollectionActions } from '..';
import React from 'react';
import { CollectionSummaryType } from 'constants/collection';
import { FlexWrapper } from 'components/Container';
import { EmptyTrashQuickOption } from './EmptyTrashQuickOption';
import { DownloadQuickOption } from './DownloadQuickOption';
import { ShareQuickOption } from './ShareQuickOption';
import {
    showDownloadQuickOption,
    showShareQuickOption,
    showEmptyTrashQuickOption,
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
            {showEmptyTrashQuickOption(collectionSummaryType) && (
                <EmptyTrashQuickOption
                    handleCollectionAction={handleCollectionAction}
                />
            )}
            {showDownloadQuickOption(collectionSummaryType) && (
                <DownloadQuickOption
                    handleCollectionAction={handleCollectionAction}
                    collectionSummaryType={collectionSummaryType}
                />
            )}
            {showShareQuickOption(collectionSummaryType) && (
                <ShareQuickOption
                    handleCollectionAction={handleCollectionAction}
                    collectionSummaryType={collectionSummaryType}
                />
            )}
        </FlexWrapper>
    );
}
