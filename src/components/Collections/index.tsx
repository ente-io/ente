import { Collection, CollectionSummaries } from 'types/collection';
import CollectionListBar from 'components/Collections/CollectionBar';
import React, { useEffect, useRef, useState } from 'react';
import AllCollections from 'components/Collections/AllCollections';
import CollectionInfoWithOptions from 'components/Collections/CollectionInfoWithOptions';
import { ALL_SECTION } from 'constants/collection';
import CollectionShare from 'components/Collections/CollectionShare';
import { SetCollectionNamerAttributes } from 'components/Collections/CollectionNamer';
import { ITEM_TYPE, TimeStampListItem } from 'components/PhotoList';

interface Iprops {
    collections: Collection[];
    activeCollectionID?: number;
    setActiveCollectionID: (id?: number) => void;
    isInSearchMode: boolean;
    collectionSummaries: CollectionSummaries;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setPhotoListHeader: (value: TimeStampListItem) => void;
}

export default function Collections(props: Iprops) {
    const {
        collections,
        isInSearchMode,
        activeCollectionID,
        setActiveCollectionID,
        collectionSummaries,
        setCollectionNamerAttributes,
        setPhotoListHeader,
    } = props;

    const [allCollectionView, setAllCollectionView] = useState(false);
    const [collectionShareModalView, setCollectionShareModalView] =
        useState(false);
    const collectionsMap = useRef<Map<number, Collection>>(new Map());
    const activeCollection = useRef<Collection>(null);

    const shouldBeHidden = isInSearchMode || collectionSummaries?.size <= 3;

    useEffect(() => {
        collectionsMap.current = new Map(
            props.collections.map((collection) => [collection.id, collection])
        );
    }, [collections]);

    useEffect(() => {
        activeCollection.current =
            collectionsMap.current.get(activeCollectionID);
    }, [activeCollectionID, collections]);

    useEffect(
        () =>
            !shouldBeHidden &&
            setPhotoListHeader({
                item: (
                    <CollectionInfoWithOptions
                        collectionSummary={collectionSummaries.get(
                            activeCollectionID
                        )}
                        activeCollection={activeCollection.current}
                        setCollectionNamerAttributes={
                            setCollectionNamerAttributes
                        }
                        redirectToAll={() => setActiveCollectionID(ALL_SECTION)}
                        showCollectionShareModal={() =>
                            setCollectionShareModalView(true)
                        }
                    />
                ),
                itemType: ITEM_TYPE.STATIC,
                height: 80,
            }),
        [collectionSummaries, activeCollectionID, shouldBeHidden]
    );

    if (shouldBeHidden) {
        return <></>;
    }

    return (
        <>
            <CollectionListBar
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

            <CollectionShare
                show={collectionShareModalView}
                onHide={() => setCollectionShareModalView(false)}
                collection={activeCollection.current}
            />
        </>
    );
}
