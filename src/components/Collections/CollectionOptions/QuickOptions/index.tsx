import { CollectionActions } from '..';
import React from 'react';
import { CollectionSummaryType } from 'constants/collection';
import { FlexWrapper } from 'components/Container';
import constants from 'utils/strings/constants';
import { DeleteOption } from './DeleteOption';
import { DownloadOption } from './DownloadOption';
import { ShareOption } from './ShareOption';
import { onlyDownloadQuickOption } from 'utils/collection';
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
            {collectionSummaryType === CollectionSummaryType.trash ? (
                <DeleteOption handleCollectionAction={handleCollectionAction} />
            ) : onlyDownloadQuickOption(collectionSummaryType) ? (
                <DownloadOption
                    handleCollectionAction={handleCollectionAction}
                    tooltipTitle={
                        collectionSummaryType ===
                        CollectionSummaryType.favorites
                            ? constants.DOWNLOAD_FAVORITES
                            : collectionSummaryType ===
                              CollectionSummaryType.uncategorized
                            ? constants.DOWNLOAD_UNCATEGORIZED
                            : constants.DOWNLOAD_COLLECTION
                    }
                />
            ) : (
                <>
                    <DownloadOption
                        handleCollectionAction={handleCollectionAction}
                    />
                    <ShareOption
                        handleCollectionAction={handleCollectionAction}
                        tooltipTitle={
                            /*: collectionSummaryType ===
                    CollectionSummaryType.incomingShare
                  ? constants.SHARING_DETAILS*/
                            collectionSummaryType ===
                                CollectionSummaryType.outgoingShare ||
                            collectionSummaryType ===
                                CollectionSummaryType.sharedOnlyViaLink
                                ? constants.MODIFY_SHARING
                                : constants.SHARE_COLLECTION
                        }
                    />
                </>
            )}
        </FlexWrapper>
    );
}
