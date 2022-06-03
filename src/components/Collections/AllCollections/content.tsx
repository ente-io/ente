import React from 'react';
import { DialogContent } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import AllCollectionCard from './CollectionCard';
import { CollectionSummary } from 'types/collection';

interface Iprops {
    collectionSummaries: CollectionSummary[];
    onCollectionClick: (id?: number) => void;
    collectionTile: any;
}
export default function AllCollectionContent({
    collectionSummaries,
    onCollectionClick,
    collectionTile,
}: Iprops) {
    return (
        <DialogContent>
            <FlexWrapper
                style={{
                    flexWrap: 'wrap',
                }}>
                {collectionSummaries.map((collectionSummary) => (
                    <AllCollectionCard
                        collectionTile={collectionTile}
                        onCollectionClick={onCollectionClick}
                        collectionSummary={collectionSummary}
                        key={collectionSummary.id}
                    />
                ))}
            </FlexWrapper>
        </DialogContent>
    );
}
