import { Collection, CollectionSummaries } from 'types/collection';
import CollectionListBar from 'components/Collections/CollectionListBar';
import { useEffect, useMemo, useState } from 'react';
import AllCollections from 'components/Collections/AllCollections';
import CollectionInfoWithOptions from 'components/Collections/CollectionInfoWithOptions';
import { ALL_SECTION, COLLECTION_LIST_SORT_BY } from 'constants/collection';
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
    activeCollection: Collection;
    activeCollectionID?: number;
    setActiveCollectionID: (id?: number) => void;
    isInSearchMode: boolean;
    collectionSummaries: CollectionSummaries;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setPhotoListHeader: (value: TimeStampListItem) => void;
}

export default function Collections(props: Iprops) {
    const {
        activeCollection,
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

    const [collectionListSortBy, setCollectionListSortBy] =
        useLocalState<COLLECTION_LIST_SORT_BY>(
            LS_KEYS.COLLECTION_SORT_BY,
            COLLECTION_LIST_SORT_BY.UPDATION_TIME_DESCENDING
        );

    const shouldBeHidden = useMemo(
        () =>
            isInSearchMode ||
            (!hasNonSystemCollections(collectionSummaries) &&
                activeCollectionID === ALL_SECTION),
        [isInSearchMode, collectionSummaries, activeCollectionID]
    );

    const sortedCollectionSummaries = useMemo(
        () =>
            sortCollectionSummaries(
                [...collectionSummaries.values()],
                collectionListSortBy
            ),
        [collectionListSortBy, collectionSummaries]
    );

    useEffect(() => {
        if (isInSearchMode) {
            return;
        }
        setPhotoListHeader({
            item: (
                <CollectionInfoWithOptions
                    collectionSummary={collectionSummaries.get(
                        activeCollectionID
                    )}
                    activeCollection={activeCollection}
                    setCollectionNamerAttributes={setCollectionNamerAttributes}
                    redirectToAll={() => setActiveCollectionID(ALL_SECTION)}
                    showCollectionShareModal={() =>
                        setCollectionShareModalView(true)
                    }
                />
            ),
            itemType: ITEM_TYPE.HEADER,
            height: 68,
        });
    }, [collectionSummaries, activeCollectionID, isInSearchMode]);

    if (shouldBeHidden) {
        return <></>;
    }

    const closeAllCollections = () => setAllCollectionView(false);
    const openAllCollections = () => setAllCollectionView(true);
    const closeCollectionShare = () => setCollectionShareModalView(false);

    return (
        <>
            <CollectionListBar
                activeCollectionID={activeCollectionID}
                setActiveCollectionID={setActiveCollectionID}
                collectionSummaries={sortedCollectionSummaries.filter((x) =>
                    shouldBeShownOnCollectionBar(x.type)
                )}
                showAllCollections={openAllCollections}
                setCollectionListSortBy={setCollectionListSortBy}
                collectionListSortBy={collectionListSortBy}
            />

            <AllCollections
                open={allCollectionView}
                onClose={closeAllCollections}
                collectionSummaries={sortedCollectionSummaries.filter(
                    (x) => !isSystemCollection(x.type)
                )}
                setActiveCollectionID={setActiveCollectionID}
                setCollectionListSortBy={setCollectionListSortBy}
                collectionListSortBy={collectionListSortBy}
            />

            <CollectionShare
                collectionSummary={collectionSummaries.get(activeCollectionID)}
                open={collectionShareModalView}
                onClose={closeCollectionShare}
                collection={activeCollection}
            />
        </>
    );
}
