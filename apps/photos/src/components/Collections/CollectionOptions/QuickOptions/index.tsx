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
import EnteSpinner from 'components/EnteSpinner';
interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
    collectionSummaryType: CollectionSummaryType;
    isDownloadInProgress: boolean;
}

export function QuickOptions({
    handleCollectionAction,
    collectionSummaryType,
    isDownloadInProgress,
}: Iprops) {
    return (
        <FlexWrapper sx={{ gap: '16px' }}>
            {showEmptyTrashQuickOption(collectionSummaryType) && (
                <EmptyTrashQuickOption
                    handleCollectionAction={handleCollectionAction}
                />
            )}
            {showDownloadQuickOption(collectionSummaryType) &&
                (!isDownloadInProgress ? (
                    <DownloadQuickOption
                        handleCollectionAction={handleCollectionAction}
                        collectionSummaryType={collectionSummaryType}
                    />
                ) : (
                    <EnteSpinner size="20px" sx={{ cursor: 'not-allowed' }} />
                ))}
            {showShareQuickOption(collectionSummaryType) && (
                <ShareQuickOption
                    handleCollectionAction={handleCollectionAction}
                    collectionSummaryType={collectionSummaryType}
                />
            )}
        </FlexWrapper>
    );
}
