import React from 'react';
import { Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import { Collection, CollectionSummary } from 'types/collection';
import { TwoScreenSpacedOptionsWithBodyPadding } from 'components/collection';
import CollectionOptions from 'components/pages/gallery/CollectionOptions';
import { SetCollectionNamerAttributes } from 'components/pages/gallery/CollectionNamer';
import { SetDialogMessage } from 'components/MessageDialog';

interface Iprops {
    collectionSummary: CollectionSummary;
    syncWithRemote: () => Promise<void>;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    collections: Collection[];
    activeCollection: number;
    setDialogMessage: SetDialogMessage;
    startLoading: () => void;
    finishLoading: () => void;
    redirectToAll: () => void;
}
export default function collectionInfo(props: Iprops) {
    const { collectionSummary } = props;
    if (!collectionSummary) {
        return <></>;
    }

    const showCollectionShareModal = () => null;
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
            <CollectionOptions
                {...props}
                showCollectionShareModal={showCollectionShareModal}
            />
        </TwoScreenSpacedOptionsWithBodyPadding>
    );
}
