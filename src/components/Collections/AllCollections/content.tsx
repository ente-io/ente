import React from 'react';
import { DialogContent } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import AllCollectionCard from './collectionCard';
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
            <FlexWrapper flexWrap="wrap" gap={0.5}>
                {collectionSummaries.map((collectionSummary) => (
                    <AllCollectionCard
                        onCollectionClick={onCollectionClick}
                        collectionSummary={collectionSummary}
                        key={collectionSummary.id}
                    />
                ))}
            </FlexWrapper>
        </DialogContent>
    );
}
