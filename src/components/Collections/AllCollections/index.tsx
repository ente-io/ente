import React, { useMemo } from 'react';
import Divider from '@mui/material/Divider';
import { CollectionType, COLLECTION_SORT_BY } from 'constants/collection';
import { sortCollectionSummaries } from 'services/collectionService';
import {
    Transition,
    FloatingDrawer,
} from 'components/Collections/FloatingDrawer';
import { useLocalState } from 'hooks/useLocalState';
import { LS_KEYS } from 'utils/storage/localStorage';
import AllCollectionsHeader from './header';
import { CollectionSummaries } from 'types/collection';
import AllCollectionContent from './content';
import { AllCollectionTile } from '../styledComponents';

interface Iprops {
    isOpen: boolean;
    close: () => void;
    collectionSummaries: CollectionSummaries;
    setActiveCollection: (id?: number) => void;
}

const LeftSlideTransition = Transition('up');

export default function AllCollections(props: Iprops) {
    const { collectionSummaries, isOpen, close, setActiveCollection } = props;

    const [collectionSortBy, setCollectionSortBy] =
        useLocalState<COLLECTION_SORT_BY>(
            LS_KEYS.COLLECTION_SORT_BY,
            COLLECTION_SORT_BY.UPDATION_TIME_DESCENDING
        );

    const sortedCollectionSummaries = useMemo(
        () =>
            sortCollectionSummaries(
                [...collectionSummaries.values()].filter(
                    (x) => x.collectionAttributes.type !== CollectionType.system
                ),
                collectionSortBy
            ),
        [collectionSortBy, collectionSummaries]
    );

    const onCollectionClick = (collectionID: number) => {
        setActiveCollection(collectionID);
        close();
    };

    return (
        <FloatingDrawer
            TransitionComponent={LeftSlideTransition}
            onClose={close}
            open={isOpen}>
            <AllCollectionsHeader
                onClose={close}
                collectionCount={props.collectionSummaries.size}
                collectionSortBy={collectionSortBy}
                setCollectionSortBy={setCollectionSortBy}
            />
            <Divider />
            <AllCollectionContent
                collectionTile={AllCollectionTile}
                collectionSummaries={sortedCollectionSummaries}
                onCollectionClick={onCollectionClick}
            />
        </FloatingDrawer>
    );
}
