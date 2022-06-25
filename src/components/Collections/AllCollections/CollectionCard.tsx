import { Box } from '@mui/material';
import constants from 'utils/strings/constants';
import React from 'react';
import CollectionCard from '../CollectionCard';
import { CollectionSummary } from 'types/collection';
import { AllCollectionTileText } from '../styledComponents';

interface Iprops {
    collectionTile: any;
    collectionSummary: CollectionSummary;
    onCollectionClick: (collectionID: number) => void;
}

export default function AllCollectionCard({
    collectionTile,
    onCollectionClick,
    collectionSummary,
}: Iprops) {
    return (
        <CollectionCard
            collectionTile={collectionTile}
            latestFile={collectionSummary.latestFile}
            onClick={() => onCollectionClick(collectionSummary.id)}>
            <AllCollectionTileText zIndex={1}>
                <Box fontWeight={'bold'}>{collectionSummary.name}</Box>
                <Box>{constants.PHOTO_COUNT(collectionSummary.fileCount)}</Box>
            </AllCollectionTileText>
        </CollectionCard>
    );
}
