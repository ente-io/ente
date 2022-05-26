import React from 'react';
import { DialogContent } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import AllCollectionCard from './CollectionCard';
import { CollectionSummary } from 'types/collection';

interface Iprops {
    collectionSummaries: CollectionSummary[];
    onCollectionClick: (id?: number) => void;
}
export default function AllCollectionContent({
    collectionSummaries,
    onCollectionClick,
}: Iprops) {
    return (
        <DialogContent>
            <FlexWrapper
                style={{
                    flexWrap: 'wrap',
                }}>
                {collectionSummaries.map(
                    ({ latestFile, collectionAttributes, fileCount }) => (
                        <AllCollectionCard
                            onCollectionClick={onCollectionClick}
                            collectionAttributes={collectionAttributes}
                            key={collectionAttributes.id}
                            latestFile={latestFile}
                            fileCount={fileCount}
                        />
                    )
                )}
            </FlexWrapper>
        </DialogContent>
    );
}
