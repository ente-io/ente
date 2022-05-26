import { Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import React from 'react';
import CollectionCard from '../CollectionCard';
import { CollectionSummary } from 'types/collection';

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
            onClick={() =>
                onCollectionClick(collectionSummary.collectionAttributes.id)
            }>
            <div>
                <Typography
                    css={`
                        font-size: 14px;
                        font-weight: 600;
                        line-height: 20px;
                    `}>
                    {collectionSummary.collectionAttributes.name}
                </Typography>
                <Typography
                    css={`
                        font-size: 14px;
                        font-weight: 400;
                        line-height: 20px;
                    `}>
                    {collectionSummary.fileCount} {constants.PHOTOS}
                </Typography>
            </div>
        </CollectionCard>
    );
}
