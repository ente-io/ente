import React from 'react';
import { DialogTitle, IconButton, Typography } from '@mui/material';
import { TwoScreenSpacedOptions } from 'components/Container';
import CollectionSort from 'components/pages/gallery/CollectionSort';
import constants from 'utils/strings/constants';
import Close from '@mui/icons-material/Close';

export default function AllCollectionsHeader({
    onClose,
    collectionCount,
    collectionSortBy,
    setCollectionSortBy,
}) {
    return (
        <DialogTitle>
            <TwoScreenSpacedOptions>
                <Typography
                    css={`
                        font-family: Inter;
                        font-size: 24px;
                        font-weight: 600;
                        line-height: 36px;
                        letter-spacing: 0em;
                        text-align: left;
                    `}>
                    {constants.ALL_ALBUMS}
                </Typography>
                <IconButton onClick={onClose}>
                    <Close />
                </IconButton>
            </TwoScreenSpacedOptions>
            <TwoScreenSpacedOptions>
                <Typography
                    css={`
                        font-family: Inter;
                        font-size: 24px;
                        font-weight: 600;
                        line-height: 36px;
                        letter-spacing: 0em;
                        text-align: left;
                    `}
                    color={'text.secondary'}>
                    {`${collectionCount} ${constants.ALBUMS}`}
                </Typography>
                <CollectionSort
                    activeSortBy={collectionSortBy}
                    setCollectionSortBy={setCollectionSortBy}
                />
            </TwoScreenSpacedOptions>
        </DialogTitle>
    );
}
