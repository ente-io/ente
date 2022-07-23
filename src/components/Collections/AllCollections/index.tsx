import React, { useContext } from 'react';
import Divider from '@mui/material/Divider';
import { COLLECTION_SORT_BY } from 'constants/collection';
import {
    Transition,
    AllCollectionDialog,
} from 'components/Collections/AllCollections/dialog';
import AllCollectionsHeader from './header';
import { CollectionSummary } from 'types/collection';
import AllCollectionContent from './content';
import { AppContext } from 'pages/_app';

interface Iprops {
    open: boolean;
    onClose: () => void;
    collectionSummaries: CollectionSummary[];
    setActiveCollection: (id?: number) => void;
    collectionSortBy: COLLECTION_SORT_BY;
    setCollectionSortBy: (v: COLLECTION_SORT_BY) => void;
}

const LeftSlideTransition = Transition('up');

export default function AllCollections(props: Iprops) {
    const {
        collectionSummaries,
        open,
        onClose,
        setActiveCollection,
        collectionSortBy,
        setCollectionSortBy,
    } = props;
    const { isMobile } = useContext(AppContext);

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
                collectionCount={props.collectionSummaries.length}
                collectionSortBy={collectionSortBy}
                setCollectionSortBy={setCollectionSortBy}
            />
            <Divider />
            <AllCollectionContent
                collectionSummaries={collectionSummaries}
                onCollectionClick={onCollectionClick}
            />
        </AllCollectionDialog>
    );
}
