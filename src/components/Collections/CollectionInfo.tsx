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
                    css={`
                        font-size: 24px;
                        font-weight: 600;
                        line-height: 36px;
                    `}>
                    {collectionAttributes.name}
                </Typography>
                <Typography
                    css={`
                        font-size: 14px;
                        line-height: 20px;
                    `}>
                    {fileCount} {constants.PHOTOS}
                </Typography>
            </div>
            <CollectionOptions {...props} />
        </TwoScreenSpacedOptionsWithBodyPadding>
    );
}
