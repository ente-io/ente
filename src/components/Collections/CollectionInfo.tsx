import React from 'react';
import { Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import { Collection, CollectionSummary } from 'types/collection';
import { TwoScreenSpacedOptionsWithBodyPadding } from 'components/Collections/styledComponents';
import CollectionOptions from 'components/Collections/CollectionOptions';
import { SetCollectionNamerAttributes } from 'components/Collections/CollectionNamer';

interface Iprops {
    activeCollection: Collection;
    collectionSummary: CollectionSummary;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    showCollectionShareModal: () => void;
    redirectToAll: () => void;
}
export default function collectionInfo(props: Iprops) {
    if (!props.collectionSummary) {
        return <></>;
    }
    const {
        collectionSummary: { collectionAttributes, fileCount },
    } = props;

    return (
        <TwoScreenSpacedOptionsWithBodyPadding>
            <div>
                <Typography
                    fontSize={'24px'}
                    lineHeight="36px"
                    fontWeight="600">
                    {collectionAttributes.name}
                </Typography>
                <Typography fontSize={'14px'} lineHeight="20px">
                    {fileCount} {constants.PHOTOS}
                </Typography>
            </div>
            <CollectionOptions {...props} />
        </TwoScreenSpacedOptionsWithBodyPadding>
    );
}
