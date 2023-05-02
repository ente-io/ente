import ScrollButton from 'components/Collections/CollectionListBar/ScrollButton';
import React, { memo, useContext, useEffect } from 'react';
import { ALL_SECTION, COLLECTION_SORT_BY } from 'constants/collection';
import { Box, IconButton, Typography } from '@mui/material';
import {
    CollectionListBarWrapper,
    ScrollContainer,
    CollectionListWrapper,
} from 'components/Collections/styledComponents';
import CollectionListBarCard from 'components/Collections/CollectionListBar/CollectionCard';
import useComponentScroll, { SCROLL_DIRECTION } from 'hooks/useComponentScroll';
import useWindowSize from 'hooks/useWindowSize';
import { IconButtonWithBG, SpaceBetweenFlex } from 'components/Container';
import ExpandMore from '@mui/icons-material/ExpandMore';
import { AppContext } from 'pages/_app';
import { CollectionSummary } from 'types/collection';
import CollectionSort from '../AllCollections/CollectionSort';
import { t } from 'i18next';

interface IProps {
    activeCollection?: number;
    setActiveCollection: (id?: number) => void;
    collectionSummaries: CollectionSummary[];
    showAllCollections: () => void;
    collectionSortBy: COLLECTION_SORT_BY;
    setCollectionSortBy: (v: COLLECTION_SORT_BY) => void;
}

const CollectionListBarCardWidth = 98;

const CollectionListBar = (props: IProps) => {
    const {
        activeCollection,
        setActiveCollection,
        collectionSummaries,
        showAllCollections,
    } = props;

    const appContext = useContext(AppContext);

    const windowSize = useWindowSize();

    const {
        componentRef: collectionScrollContainerRef,
        scrollComponent,
        onFarLeft,
        onFarRight,
    } = useComponentScroll({
        dependencies: [windowSize, collectionSummaries],
    });

    useEffect(() => {
        if (!collectionScrollContainerRef?.current) {
            return;
        }
        // scroll the active collection into view
        const activeCollectionIndex = collectionSummaries.findIndex(
            (item) => item.id === activeCollection
        );
        const desiredXPositionToKeepCollectionCardInCenterOfScreen =
            activeCollectionIndex * CollectionListBarCardWidth -
            collectionScrollContainerRef.current.clientWidth / 2;
        const isAlreadyInView =
            Math.abs(
                desiredXPositionToKeepCollectionCardInCenterOfScreen -
                    collectionScrollContainerRef.current.scrollLeft
            ) <=
            collectionScrollContainerRef.current.clientWidth / 2;

        if (isAlreadyInView) {
            return;
        }
        collectionScrollContainerRef.current.scrollLeft =
            desiredXPositionToKeepCollectionCardInCenterOfScreen;
    }, [activeCollection]);

    const clickHandler = (collectionID?: number) => () => {
        setActiveCollection(collectionID ?? ALL_SECTION);
    };

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
                    {!onFarLeft && (
                        <ScrollButton
                            scrollDirection={SCROLL_DIRECTION.LEFT}
                            onClick={scrollComponent(SCROLL_DIRECTION.LEFT)}
                        />
                    )}
                    <ScrollContainer ref={collectionScrollContainerRef}>
                        {collectionSummaries.map((item) => (
                            <CollectionListBarCard
                                key={item.id}
                                latestFile={item.latestFile}
                                active={activeCollection === item.id}
                                onClick={clickHandler(item.id)}
                                collectionType={item.type}
                                collectionName={item.name}
                            />
                        ))}
                    </ScrollContainer>
                    {!onFarRight && (
                        <ScrollButton
                            scrollDirection={SCROLL_DIRECTION.RIGHT}
                            onClick={scrollComponent(SCROLL_DIRECTION.RIGHT)}
                        />
                    )}
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

export default memo(CollectionListBar);
