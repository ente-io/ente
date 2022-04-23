import React from 'react';
import { Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import { IconButton } from 'components/Container';
import OptionIcon from 'components/icons/OptionIcon-2';
import { CollectionSummary } from 'types/collection';
import { TwoScreenSpacedOptionsWithBodyPadding } from 'components/collection';
import styled from 'styled-components';

const InvertedIconButton = styled(IconButton)`
    background-color: ${({ theme }) => theme.palette.primary.main};
    color: ${({ theme }) => theme.palette.background.default};
    &:hover {
        background-color: ${({ theme }) => theme.palette.grey.A100};
    }
`;
interface Iprops {
    collectionSummary: CollectionSummary;
}
export default function collectionInfo(props: Iprops) {
    const { collectionSummary } = props;
    if (!collectionSummary) {
        return <></>;
    }

    return (
        <TwoScreenSpacedOptionsWithBodyPadding>
            <div>
                <Typography variant="h5">
                    <strong>{collectionSummary.collectionName}</strong>
                </Typography>
                <Typography variant="subtitle1">
                    {collectionSummary.fileCount} {constants.PHOTOS}
                </Typography>
            </div>
            <InvertedIconButton
                style={{
                    transform: 'rotate(90deg)',
                }}>
                <OptionIcon />
            </InvertedIconButton>
        </TwoScreenSpacedOptionsWithBodyPadding>
    );
}
