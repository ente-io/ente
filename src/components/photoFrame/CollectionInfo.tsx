import React from 'react';
import { Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import { Collection, CollectionSummary } from 'types/collection';
import { TwoScreenSpacedOptionsWithBodyPadding } from 'components/collection';
import CollectionOptions from 'components/pages/gallery/CollectionOptions';
import { SetCollectionNamerAttributes } from 'components/pages/gallery/CollectionNamer';

interface Iprops {
    activeCollection: Collection;
    collectionSummary: CollectionSummary;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    showCollectionShareModal: () => void;
    redirectToAll: () => void;
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
                    <strong>
                        {collectionSummary.collectionAttributes.name}
                    </strong>
                </Typography>
                <Typography variant="subtitle1">
                    {collectionSummary.fileCount} {constants.PHOTOS}
                </Typography>
            </div>
            <CollectionOptions {...props} />
        </TwoScreenSpacedOptionsWithBodyPadding>
    );
}
