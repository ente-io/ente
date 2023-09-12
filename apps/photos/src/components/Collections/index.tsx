import { Collection, CollectionSummaries } from 'types/collection';
import CollectionListBar from 'components/Collections/CollectionListBar';
import { useCallback, useEffect, useMemo, useState } from 'react';
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
import {
    CollectionDownloadProgress,
    CollectionDownloadProgressAttributes,
    isCollectionDownloadCancelled,
    isCollectionDownloadCompleted,
} from './CollectionDownloadProgress';
import { SetCollectionDownloadProgressAttributes } from 'types/gallery';

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

    const [
        collectionDownloadProgressAttributesList,
        setCollectionDownloadProgressAttributesList,
    ] = useState<CollectionDownloadProgressAttributes[]>([]);

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

    const setCollectionDownloadProgressAttributesCreator =
        (collectionID: number): SetCollectionDownloadProgressAttributes =>
        (value) => {
            setCollectionDownloadProgressAttributesList((prev) => {
                const attributes = prev?.find(
                    (attr) => attr.collectionID === collectionID
                );
                const updatedAttributes =
                    typeof value === 'function' ? value(attributes) : value;

                const updatedAttributesList = attributes
                    ? prev.map((attr) =>
                          attr.collectionID === collectionID
                              ? updatedAttributes
                              : attr
                      )
                    : [...prev, updatedAttributes];

                return updatedAttributesList;
            });
        };

    const isActiveCollectionDownloadInProgress = useCallback(() => {
        const attributes = collectionDownloadProgressAttributesList.find(
            (attr) => attr.collectionID === activeCollectionID
        );
        return (
            attributes &&
            !isCollectionDownloadCancelled(attributes) &&
            !isCollectionDownloadCompleted(attributes)
        );
    }, [activeCollectionID, collectionDownloadProgressAttributesList]);

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
                    showCollectionShareModal={() =>
                        setCollectionShareModalView(true)
                    }
                    setCollectionDownloadProgressAttributesCreator={
                        setCollectionDownloadProgressAttributesCreator
                    }
                    isActiveCollectionDownloadInProgress={
                        isActiveCollectionDownloadInProgress
                    }
                    setActiveCollectionID={setActiveCollectionID}
                />
            ),
            itemType: ITEM_TYPE.HEADER,
            height: 68,
        });
    }, [
        toShowCollectionSummaries,
        activeCollectionID,
        isInSearchMode,
        isActiveCollectionDownloadInProgress,
    ]);

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
            <CollectionDownloadProgress
                attributesList={collectionDownloadProgressAttributesList}
                setAttributesList={setCollectionDownloadProgressAttributesList}
            />
        </>
    );
}
