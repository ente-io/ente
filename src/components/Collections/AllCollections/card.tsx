import { Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import React from 'react';
import CollectionCard from '../CollectionCard';
import { LargerCollectionTile } from '../styledComponents';

export default function AllCollectionCard({
    onCollectionClick,
    collectionAttributes,
    latestFile,
    fileCount,
}) {
    return (
        <CollectionCard
            latestFile={latestFile}
            onClick={() => onCollectionClick(collectionAttributes.id)}
            customCollectionTile={LargerCollectionTile}>
            <div>
                <Typography
                    css={`
                        font-family: Inter;
                        font-size: 14px;
                        font-weight: 600;
                        line-height: 20px;
                        letter-spacing: 0em;
                        text-align: left;
                    `}>
                    {collectionAttributes.name}
                </Typography>
                <Typography
                    css={`
                        font-size: 14px;
                        font-weight: 400;
                        line-height: 20px;
                        letter-spacing: -0.15399999916553497px;
                        text-align: left;
                    `}>
                    {fileCount} {constants.PHOTOS}
                </Typography>
            </div>
        </CollectionCard>
    );
}
