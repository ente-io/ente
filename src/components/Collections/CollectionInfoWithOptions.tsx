import { CollectionInfo } from './CollectionInfo';
import React from 'react';
import { Collection, CollectionSummary } from 'types/collection';
import { CollectionSectionWrapper } from 'components/Collections/styledComponents';
import CollectionOptions from 'components/Collections/CollectionOptions';
import { SetCollectionNamerAttributes } from 'components/Collections/CollectionNamer';
import { CollectionType } from 'constants/collection';
import { SpaceBetweenFlex } from 'components/Container';

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
        <CollectionSectionWrapper>
            <SpaceBetweenFlex>
                <CollectionInfo name={name} fileCount={fileCount} />
                {type !== CollectionType.system &&
                    type !== CollectionType.favorites && (
                        <CollectionOptions {...props} />
                    )}
            </SpaceBetweenFlex>
        </CollectionSectionWrapper>
    );
}
