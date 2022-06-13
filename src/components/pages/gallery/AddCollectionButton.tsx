import { Typography } from '@mui/material';
import CollectionCard from 'components/Collections/CollectionCard';
import { CollectionSelectorTile } from 'components/Collections/styledComponents';
import React from 'react';
import { styled } from '@mui/material';
import constants from 'utils/strings/constants';

const ImageContainer = styled('div')`
    position: absolute;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 42px;
`;

export default function AddCollectionButton({
    showNextModal,
}: {
    showNextModal: () => void;
}) {
    return (
        <CollectionCard
            collectionTile={CollectionSelectorTile}
            onClick={() => showNextModal()}
            latestFile={null}>
            <Typography variant="body2" fontWeight={'bold'}>
                {constants.CREATE_COLLECTION}
            </Typography>
            <ImageContainer>+</ImageContainer>
        </CollectionCard>
    );
}
