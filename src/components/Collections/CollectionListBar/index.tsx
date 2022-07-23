import ScrollButton from 'components/Collections/CollectionListBar/ScrollButton';
import React, { useContext, useEffect } from 'react';
import constants from 'utils/strings/constants';
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

interface IProps {
    activeCollection?: number;
    setActiveCollection: (id?: number) => void;
    collectionSummaries: CollectionSummary[];
    showAllCollections: () => void;
    collectionSortBy: COLLECTION_SORT_BY;
    setCollectionSortBy: (v: COLLECTION_SORT_BY) => void;
}

export default function CollectionListBar(props: IProps) {
    const {
        activeCollection,
        setActiveCollection,
        collectionSummaries,
        showAllCollections,
    } = props;

    const appContext = useContext(AppContext);

    const windowSize = useWindowSize();

    const { componentRef, scrollComponent, onFarLeft, onFarRight } =
        useComponentScroll({
            dependencies: [windowSize, collectionSummaries],
        });

    const collectionChipsRef = collectionSummaries.reduce(
        (refMap, collectionSummary) => {
            refMap[collectionSummary.id] = React.createRef();
            return refMap;
        },
        {}
    );

    useEffect(() => {
        collectionChipsRef[activeCollection]?.current.scrollIntoView();
    }, [activeCollection]);

    const clickHandler = (collectionID?: number) => () => {
        setActiveCollection(collectionID ?? ALL_SECTION);
    };

    return (
        <CollectionListBarWrapper>
            <SpaceBetweenFlex mb={1}>
                <Typography>{constants.ALBUMS}</Typography>
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
                    <ScrollContainer ref={componentRef}>
                        {collectionSummaries.map((item) => (
                            <CollectionListBarCard
                                key={item.id}
                                latestFile={item.latestFile}
                                ref={collectionChipsRef[item.id]}
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
}
