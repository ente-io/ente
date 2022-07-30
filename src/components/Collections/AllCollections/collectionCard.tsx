import { Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import React from 'react';
import CollectionCard from '../CollectionCard';
import { CollectionSummary } from 'types/collection';
import { AllCollectionTile, AllCollectionTileText } from '../styledComponents';

interface Iprops {
    collectionSummary: CollectionSummary;
    onCollectionClick: (collectionID: number) => void;
}

export default function AllCollectionCard({
    onCollectionClick,
    collectionSummary,
}: Iprops) {
    return (
        <CollectionCard
            collectionTile={AllCollectionTile}
            latestFile={collectionSummary.latestFile}
            onClick={() => onCollectionClick(collectionSummary.id)}>
            <AllCollectionTileText>
                <Typography>{collectionSummary.name}</Typography>
                <Typography variant="body2" color="text.secondary">
                    {constants.PHOTO_COUNT(collectionSummary.fileCount)}
                </Typography>
            </AllCollectionTileText>
        </CollectionCard>
    );
}
