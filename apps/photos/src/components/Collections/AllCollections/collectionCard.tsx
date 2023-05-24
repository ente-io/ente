import { Typography } from '@mui/material';
import React from 'react';
import CollectionCard from '../CollectionCard';
import { CollectionSummary } from 'types/collection';
import { AllCollectionTile, AllCollectionTileText } from '../styledComponents';
import { t } from 'i18next';

interface Iprops {
    collectionSummary: CollectionSummary;
    onCollectionClick: (collectionID: number) => void;
    isScrolling?: boolean;
}

export default function AllCollectionCard({
    onCollectionClick,
    collectionSummary,
    isScrolling,
}: Iprops) {
    return (
        <CollectionCard
            collectionTile={AllCollectionTile}
            latestFile={collectionSummary.latestFile}
            onClick={() => onCollectionClick(collectionSummary.id)}
            isScrolling={isScrolling}>
            <AllCollectionTileText>
                <Typography>{collectionSummary.name}</Typography>
                <Typography variant="small" color="text.muted">
                    {t('photos_count', { count: collectionSummary.fileCount })}
                </Typography>
            </AllCollectionTileText>
        </CollectionCard>
    );
}
