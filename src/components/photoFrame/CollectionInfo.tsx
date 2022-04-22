import React from 'react';
import { Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import { Header } from 'components/collection';
import { IconButton } from 'components/Container';
import OptionIcon from 'components/icons/OptionIcon-2';
import { CollectionSummary } from 'types/collection';

interface Iprops {
    collectionSummary: CollectionSummary;
}
export default function collectionInfo(props: Iprops) {
    const { collectionSummary } = props;
    if (!collectionSummary) {
        return <></>;
    }

    return (
        <Header>
            <div>
                <Typography variant="h5">
                    <strong>{collectionSummary.collectionName}</strong>
                </Typography>
                <Typography variant="subtitle1">
                    {collectionSummary.fileCount} {constants.PHOTOS}
                </Typography>
            </div>
            <IconButton>
                <OptionIcon style={{ transform: 'rotate(90deg)' }} />
            </IconButton>
        </Header>
    );
}
