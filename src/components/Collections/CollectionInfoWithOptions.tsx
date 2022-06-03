import { CollectionInfo } from './CollectionInfo';
import React from 'react';
import { Collection, CollectionSummary } from 'types/collection';
import { PaddedSpaceBetweenFlex } from 'components/Collections/styledComponents';
import CollectionOptions from 'components/Collections/CollectionOptions';
import { SetCollectionNamerAttributes } from 'components/Collections/CollectionNamer';
import { CollectionType } from 'constants/collection';

interface Iprops {
    activeCollection: Collection;
    collectionSummary: CollectionSummary;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    showCollectionShareModal: () => void;
    redirectToAll: () => void;
}
export default function collectionInfoWithOptions({
    collectionSummary,
    ...props
}: Iprops) {
    if (!collectionSummary) {
        return <></>;
    }

    const { name, type, fileCount } = collectionSummary;

    return (
        <PaddedSpaceBetweenFlex>
            <CollectionInfo name={name} fileCount={fileCount} />
            {type !== CollectionType.system && <CollectionOptions {...props} />}
        </PaddedSpaceBetweenFlex>
    );
}
