import React, { useContext, useEffect } from 'react';
import { ALL_SECTION, COLLECTION_SORT_BY } from 'constants/collection';
import { Box, IconButton, Typography } from '@mui/material';
import {
    CollectionListBarWrapper,
    CollectionListWrapper,
} from 'components/Collections/styledComponents';
import CollectionListBarCard from 'components/Collections/CollectionListBar/CollectionCard';
import { IconButtonWithBG, SpaceBetweenFlex } from 'components/Container';
import ExpandMore from '@mui/icons-material/ExpandMore';
import { AppContext } from 'pages/_app';
import { CollectionSummary } from 'types/collection';
import CollectionSort from '../AllCollections/CollectionSort';
import { t } from 'i18next';
import { FixedSizeList as List, areEqual } from 'react-window';
import AutoSizer from 'react-virtualized-auto-sizer';
import memoize from 'memoize-one';

interface IProps {
    activeCollection?: number;
    setActiveCollection: (id?: number) => void;
    collectionSummaries: CollectionSummary[];
    showAllCollections: () => void;
    collectionSortBy: COLLECTION_SORT_BY;
    setCollectionSortBy: (v: COLLECTION_SORT_BY) => void;
}

const CollectionListBarCardWidth = 94;

const createItemData = memoize((items, activeCollection, clickHandler) => ({
    items,
    activeCollection,
    clickHandler,
}));

const CollectionCardContainer = React.memo(
    ({ data, index, style, isScrolling }: any) => {
        const { items, activeCollection, clickHandler } = data;
        const item = items[index];

        return (
            <div style={style}>
                <CollectionListBarCard
                    isScrolling={isScrolling}
                    key={item.id}
                    latestFile={item.latestFile}
                    active={activeCollection === item.id}
                    onClick={clickHandler(item.id)}
                    collectionType={item.type}
                    collectionName={item.name}
                />
            </div>
        );
    },
    areEqual
);

const CollectionListBar = (props: IProps) => {
    const {
        activeCollection,
        setActiveCollection,
        collectionSummaries,
        showAllCollections,
    } = props;

    const appContext = useContext(AppContext);

    const collectionListRef = React.useRef(null);

    useEffect(() => {
        if (!collectionListRef.current) {
            return;
        }
        // scroll the active collection into view
        const activeCollectionIndex = collectionSummaries.findIndex(
            (item) => item.id === activeCollection
        );
        collectionListRef.current.scrollToItem(activeCollectionIndex, 'smart');
    }, [activeCollection]);

    const clickHandler = (collectionID?: number) => () => {
        setActiveCollection(collectionID ?? ALL_SECTION);
    };

    const itemData = createItemData(
        collectionSummaries,
        activeCollection,
        clickHandler
    );

    return (
        <CollectionListBarWrapper>
            <SpaceBetweenFlex mb={1}>
                <Typography>{t('ALBUMS')}</Typography>
                {appContext.isMobile && (
                    <Box display="flex" alignItems={'center'} gap={1}>
                        <CollectionSort
                            setCollectionSortBy={props.setCollectionSortBy}
                            activeSortBy={props.collectionSortBy}
                            disableBG
                        />
                        <IconButton onClick={showAllCollections}>
                            <ExpandMore />
                        </IconButton>
                    </Box>
                )}
            </SpaceBetweenFlex>
            <Box display="flex" alignItems="flex-start" gap={2}>
                <CollectionListWrapper>
                    {/* {!onFarLeft && (
                        <ScrollButton
                            scrollDirection={SCROLL_DIRECTION.LEFT}
                            onClick={scrollComponent(SCROLL_DIRECTION.LEFT)}
                        />
                    )} */}
                    <AutoSizer disableHeight>
                        {({ width }) => (
                            <List
                                ref={collectionListRef}
                                itemData={itemData}
                                layout="horizontal"
                                width={width}
                                height={110}
                                itemCount={collectionSummaries.length}
                                itemSize={CollectionListBarCardWidth}
                                useIsScrolling>
                                {CollectionCardContainer}
                            </List>
                        )}
                    </AutoSizer>
                    {/* {!onFarRight && (
                        <ScrollButton
                            scrollDirection={SCROLL_DIRECTION.RIGHT}
                            onClick={scrollComponent(SCROLL_DIRECTION.RIGHT)}
                        />
                    )} */}
                </CollectionListWrapper>
                {!appContext.isMobile && (
                    <Box
                        display="flex"
                        alignItems={'center'}
                        gap={1}
                        height={'64px'}>
                        <CollectionSort
                            setCollectionSortBy={props.setCollectionSortBy}
                            activeSortBy={props.collectionSortBy}
                        />
                        <IconButtonWithBG onClick={showAllCollections}>
                            <ExpandMore />
                        </IconButtonWithBG>
                    </Box>
                )}
            </Box>
        </CollectionListBarWrapper>
    );
};

export default CollectionListBar;
