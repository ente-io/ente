import { Collection, CollectionSummaries } from 'types/collection';
import CollectionListBar from 'components/Collections/CollectionListBar';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import AllCollections from 'components/Collections/AllCollections';
import CollectionInfoWithOptions from 'components/Collections/CollectionInfoWithOptions';
import { ALL_SECTION, COLLECTION_SORT_BY } from 'constants/collection';
import CollectionShare from 'components/Collections/CollectionShare';
import { SetCollectionNamerAttributes } from 'components/Collections/CollectionNamer';
import { ITEM_TYPE, TimeStampListItem } from 'components/PhotoList';
import {
    hasNonSystemCollections,
    isSystemCollection,
    shouldBeShownOnCollectionBar,
} from 'utils/collection';
import { useLocalState } from 'hooks/useLocalState';
import { sortCollectionSummaries } from 'services/collectionService';
import { LS_KEYS } from 'utils/storage/localStorage';

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

    const [collectionSortBy, setCollectionSortBy] =
        useLocalState<COLLECTION_SORT_BY>(
            LS_KEYS.COLLECTION_SORT_BY,
            COLLECTION_SORT_BY.UPDATION_TIME_DESCENDING
        );
    const collectionsMap = useRef<Map<number, Collection>>(new Map());
    const activeCollection = useRef<Collection>(null);

    const shouldBeHidden =
        isInSearchMode || !hasNonSystemCollections(collectionSummaries);

    useEffect(() => {
        collectionsMap.current = new Map(
            props.collections.map((collection) => [collection.id, collection])
        );
    }, [collections]);

    useEffect(() => {
        activeCollection.current =
            collectionsMap.current.get(activeCollectionID);
    }, [activeCollectionID, collections]);

    const sortedCollectionSummaries = useMemo(
        () =>
            sortCollectionSummaries(
                [...collectionSummaries.values()],
                collectionSortBy
            ),
        [collectionSortBy, collectionSummaries]
    );

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
                        activeCollectionID={activeCollectionID}
                        setCollectionNamerAttributes={
                            setCollectionNamerAttributes
                        }
                        redirectToAll={() => setActiveCollectionID(ALL_SECTION)}
                        showCollectionShareModal={() =>
                            setCollectionShareModalView(true)
                        }
                    />
                ),
                itemType: ITEM_TYPE.OTHER,
                height: 68,
            }),
        [collectionSummaries, activeCollectionID, shouldBeHidden]
    );

    if (shouldBeHidden) {
        return <></>;
    }

    const closeAllCollections = () => setAllCollectionView(false);
    const openAllCollections = () => setAllCollectionView(true);
    const closeCollectionShare = () => setCollectionShareModalView(false);

    return (
        <>
            <CollectionListBar
                activeCollection={activeCollectionID}
                setActiveCollection={setActiveCollectionID}
                collectionSummaries={sortedCollectionSummaries.filter((x) =>
                    shouldBeShownOnCollectionBar(x.type)
                )}
                showAllCollections={openAllCollections}
                setCollectionSortBy={setCollectionSortBy}
                collectionSortBy={collectionSortBy}
            />

            <AllCollections
                open={allCollectionView}
                onClose={closeAllCollections}
                collectionSummaries={sortedCollectionSummaries.filter(
                    (x) => !isSystemCollection(x.type)
                )}
                setActiveCollection={setActiveCollectionID}
                setCollectionSortBy={setCollectionSortBy}
                collectionSortBy={collectionSortBy}
            />

            <CollectionShare
                open={collectionShareModalView}
                onClose={closeCollectionShare}
                collection={activeCollection.current}
            />
        </>
    );
}
