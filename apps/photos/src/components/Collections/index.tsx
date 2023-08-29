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
    isInHiddenSection: boolean;
    collectionSummaries: CollectionSummaries;
    hiddenCollectionSummaries: CollectionSummaries;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setPhotoListHeader: (value: TimeStampListItem) => void;
}

export default function Collections(props: Iprops) {
    const {
        activeCollection,
        isInSearchMode,
        isInHiddenSection,
        activeCollectionID,
        setActiveCollectionID,
        collectionSummaries,
        hiddenCollectionSummaries,
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

    const toShowCollectionSummaries = useMemo(
        () =>
            isInHiddenSection ? hiddenCollectionSummaries : collectionSummaries,
        [isInHiddenSection, hiddenCollectionSummaries, collectionSummaries]
    );

    const shouldBeHidden = useMemo(
        () =>
            isInSearchMode ||
            (!hasNonSystemCollections(toShowCollectionSummaries) &&
                activeCollectionID === ALL_SECTION),
        [isInSearchMode, toShowCollectionSummaries, activeCollectionID]
    );

    const sortedCollectionSummaries = useMemo(
        () =>
            sortCollectionSummaries(
                [...toShowCollectionSummaries.values()],
                collectionListSortBy
            ),
        [collectionListSortBy, toShowCollectionSummaries]
    );

    const showCollectionShareModal = () => setCollectionShareModalView(true);

    useEffect(() => {
        if (isInSearchMode) {
            return;
        }
        setPhotoListHeader({
            item: (
                <CollectionInfoWithOptions
                    collectionSummary={toShowCollectionSummaries.get(
                        activeCollectionID
                    )}
                    activeCollection={activeCollection}
                    setCollectionNamerAttributes={setCollectionNamerAttributes}
                    setActiveCollectionID={setActiveCollectionID}
                    showCollectionShareModal={showCollectionShareModal}
                />
            ),
            itemType: ITEM_TYPE.HEADER,
            height: 68,
        });
    }, [toShowCollectionSummaries, activeCollectionID, isInSearchMode]);

    if (shouldBeHidden) {
        return <></>;
    }

    const closeAllCollections = () => setAllCollectionView(false);
    const openAllCollections = () => setAllCollectionView(true);
    const closeCollectionShare = () => setCollectionShareModalView(false);

    return (
        <>
            <CollectionListBar
                isInHiddenSection={isInHiddenSection}
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
                isInHiddenSection={isInHiddenSection}
            />

            <CollectionShare
                collectionSummary={toShowCollectionSummaries.get(
                    activeCollectionID
                )}
                open={collectionShareModalView}
                onClose={closeCollectionShare}
                collection={activeCollection}
            />
        </>
    );
}
