import { Typography } from '@mui/material';
import CollectionCard from 'components/Collections/CollectionCard';
import {
    AllCollectionTile,
    AllCollectionTileText,
} from 'components/Collections/styledComponents';
import React from 'react';
import { styled } from '@mui/material';
import constants from 'utils/strings/constants';
import { CenteredFlex, Overlay } from 'components/Container';

const ImageContainer = styled(Overlay)`
    display: flex;
    font-size: 42px;
`;

interface Iprops {
    showNextModal: () => void;
}

export default function AddCollectionButton({ showNextModal }: Iprops) {
    return (
        <CollectionCard
            collectionTile={AllCollectionTile}
            onClick={() => showNextModal()}
            latestFile={null}>
            <AllCollectionTileText zIndex={1}>
                <Typography variant="body2" fontWeight={'bold'}>
                    {constants.CREATE_COLLECTION}
                </Typography>
            </AllCollectionTileText>
            <ImageContainer zIndex={0}>
                <CenteredFlex>+</CenteredFlex>
            </ImageContainer>
        </CollectionCard>
    );
}
