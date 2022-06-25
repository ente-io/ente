import React, { useContext, useMemo } from 'react';
import Divider from '@mui/material/Divider';
import { COLLECTION_SORT_BY } from 'constants/collection';
import { sortCollectionSummaries } from 'services/collectionService';
import {
    Transition,
    AllCollectionDialog,
} from 'components/Collections/AllCollections/dialog';
import { useLocalState } from 'hooks/useLocalState';
import { LS_KEYS } from 'utils/storage/localStorage';
import AllCollectionsHeader from './header';
import { CollectionSummaries } from 'types/collection';
import AllCollectionContent from './content';
import { isSystemCollection } from 'utils/collection';
import { AppContext } from 'pages/_app';

interface Iprops {
    open: boolean;
    onClose: () => void;
    collectionSummaries: CollectionSummaries;
    setActiveCollection: (id?: number) => void;
}

const LeftSlideTransition = Transition('up');

export default function AllCollections(props: Iprops) {
    const { collectionSummaries, open, onClose, setActiveCollection } = props;
    const { isMobile } = useContext(AppContext);
    const [collectionSortBy, setCollectionSortBy] =
        useLocalState<COLLECTION_SORT_BY>(
            LS_KEYS.COLLECTION_SORT_BY,
            COLLECTION_SORT_BY.UPDATION_TIME_DESCENDING
        );

    const sortedCollectionSummaries = useMemo(
        () =>
            sortCollectionSummaries(
                [...collectionSummaries.values()].filter(
                    (x) => !isSystemCollection(x.type)
                ),
                collectionSortBy
            ),
        [collectionSortBy, collectionSummaries]
    );

    const onCollectionClick = (collectionID: number) => {
        setActiveCollection(collectionID);
        onClose();
    };

    return (
        <AllCollectionDialog
            position="flex-end"
            TransitionComponent={LeftSlideTransition}
            onClose={onClose}
            open={open}
            fullScreen={isMobile}>
            <AllCollectionsHeader
                onClose={onClose}
                collectionCount={props.collectionSummaries.size}
                collectionSortBy={collectionSortBy}
                setCollectionSortBy={setCollectionSortBy}
            />
            <Divider />
            <AllCollectionContent
                collectionSummaries={sortedCollectionSummaries}
                onCollectionClick={onCollectionClick}
            />
        </AllCollectionDialog>
    );
}
