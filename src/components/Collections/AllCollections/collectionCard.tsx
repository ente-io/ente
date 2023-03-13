import { Typography } from '@mui/material';
import React from 'react';
import CollectionCard from '../CollectionCard';
import { CollectionSummary } from 'types/collection';
import { AllCollectionTile, AllCollectionTileText } from '../styledComponents';
import { useTranslation } from 'react-i18next';

interface Iprops {
    collectionSummary: CollectionSummary;
    onCollectionClick: (collectionID: number) => void;
}

export default function AllCollectionCard({
    onCollectionClick,
    collectionSummary,
}: Iprops) {
    const { t } = useTranslation();
    return (
        <CollectionCard
            collectionTile={AllCollectionTile}
            latestFile={collectionSummary.latestFile}
            onClick={() => onCollectionClick(collectionSummary.id)}>
            <AllCollectionTileText>
                <Typography>{collectionSummary.name}</Typography>
                <Typography variant="body2" color="text.secondary">
                    {t('photos_count', { count: collectionSummary.fileCount })}
                </Typography>
            </AllCollectionTileText>
        </CollectionCard>
    );
}
