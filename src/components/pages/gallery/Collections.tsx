import { Collection, CollectionSummaries } from 'types/collection';
import CollectionBar from './CollectionBar';
import React, { useState } from 'react';
import AllCollections from 'components/collection/AllCollections';
interface Iprops {
    collections: Collection[];
    activeCollection?: number;
    setActiveCollection: (id?: number) => void;
    isInSearchMode: boolean;
    collectionSummaries: CollectionSummaries;
}
export function Collections(props: Iprops) {
    const {
        collections,
        isInSearchMode,
        activeCollection,
        setActiveCollection,
        collectionSummaries,
    } = props;

    const [allCollectionView, setAllCollectionView] = useState(false);
    return (
        <>
            <CollectionBar
                collections={collections}
                isInSearchMode={isInSearchMode}
                activeCollection={activeCollection}
                setActiveCollection={setActiveCollection}
                collectionSummaries={collectionSummaries}
                showAllCollections={() => setAllCollectionView(true)}
            />

            <AllCollections
                isOpen={allCollectionView}
                close={() => setAllCollectionView(false)}
                collectionSummaries={collectionSummaries}
                setActiveCollection={setActiveCollection}
            />
        </>
    );
}
