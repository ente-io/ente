import { Collection, CollectionSummaries } from 'types/collection';
import CollectionBar from './CollectionBar';
import React, { useEffect, useRef, useState } from 'react';
import AllCollections from 'components/collection/AllCollections';
import CollectionInfo from 'components/photoFrame/CollectionInfo';
import { ALL_SECTION } from 'constants/collection';
import CollectionShare from 'components/CollectionShare';
import { SetCollectionNamerAttributes } from './CollectionNamer';
interface Iprops {
    collections: Collection[];
    activeCollectionID?: number;
    setActiveCollectionID: (id?: number) => void;
    isInSearchMode: boolean;
    collectionSummaries: CollectionSummaries;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
}

export function Collections(props: Iprops) {
    const {
        collections,
        isInSearchMode,
        activeCollectionID,
        setActiveCollectionID,
        collectionSummaries,
        setCollectionNamerAttributes,
    } = props;

    const [allCollectionView, setAllCollectionView] = useState(false);
    const [collectionShareModalView, setCollectionShareModalView] =
        useState(false);
    const collectionsMap = useRef<Map<number, Collection>>(new Map());
    const activeCollection = useRef<Collection>(null);

    useEffect(() => {
        collectionsMap.current = new Map(
            props.collections.map((collection) => [collection.id, collection])
        );
    }, [collections]);

    useEffect(() => {
        activeCollection.current =
            collectionsMap.current.get(activeCollectionID);
    }, [activeCollectionID, collections]);

    return (
        <>
            <CollectionBar
                collections={collections}
                isInSearchMode={isInSearchMode}
                activeCollection={activeCollectionID}
                setActiveCollection={setActiveCollectionID}
                collectionSummaries={collectionSummaries}
                showAllCollections={() => setAllCollectionView(true)}
            />

            <AllCollections
                isOpen={allCollectionView}
                close={() => setAllCollectionView(false)}
                collectionSummaries={collectionSummaries}
                setActiveCollection={setActiveCollectionID}
            />

            <CollectionInfo
                collectionSummary={collectionSummaries.get(activeCollectionID)}
                activeCollection={activeCollection.current}
                setCollectionNamerAttributes={setCollectionNamerAttributes}
                redirectToAll={() => setActiveCollectionID(ALL_SECTION)}
                showCollectionShareModal={() =>
                    setCollectionShareModalView(true)
                }
            />
            <CollectionShare
                show={collectionShareModalView}
                onHide={() => setCollectionShareModalView(false)}
                collection={activeCollection.current}
            />
        </>
    );
}
