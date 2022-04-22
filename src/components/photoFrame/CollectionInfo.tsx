import React from 'react';
import { Typography } from '@mui/material';
import { CollectionSummary } from 'types/collection';
import styled from 'styled-components';
import { IMAGE_CONTAINER_MAX_WIDTH } from 'constants/gallery';
import constants from 'utils/strings/constants';
interface Iprops {
    collectionSummary: CollectionSummary;
}

const Wrapper = styled.div`
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * 4}px) {
        padding: 0 4px;
    }
`;
export default function collectionInfo(props: Iprops) {
    const { collectionSummary } = props;
    if (!collectionSummary) {
        return <></>;
    }
    return (
        <Wrapper>
            <Typography variant="h5">
                <strong>{collectionSummary.collectionName}</strong>
            </Typography>
            <Typography variant="subtitle1">
                {collectionSummary.fileCount} {constants.PHOTOS}
            </Typography>
        </Wrapper>
    );
}
