import NavigationButton, {
    SCROLL_DIRECTION,
} from 'components/Collections/NavigationButton';
import React, { useEffect, useRef, useState } from 'react';
import { Collection, CollectionSummaries } from 'types/collection';
import constants from 'utils/strings/constants';
import { ALL_SECTION } from 'constants/collection';
import { Link, Typography } from '@mui/material';
import {
    Hider,
    CollectionBarWrapper,
    CollectionWithNavigationContainer,
    ScrollContainer,
    TwoScreenSpacedOptionsWithBodyPadding,
} from 'components/Collections/styledComponents';
import CollectionCardWithActiveIndicator from 'components/Collections/CollectionCardWithActiveIndicator';
import { useWindowSize } from 'hooks/useWindowSize';

interface IProps {
    collections: Collection[];
    activeCollection?: number;
    setActiveCollection: (id?: number) => void;
    isInSearchMode: boolean;
    collectionSummaries: CollectionSummaries;
    showAllCollections: () => void;
}

export default function CollectionBar(props: IProps) {
    const {
        activeCollection,
        collections,
        setActiveCollection,
        collectionSummaries,
        showAllCollections,
    } = props;

    const windowSize = useWindowSize();
    const collectionWrapperRef = useRef<HTMLDivElement>(null);
    const collectionChipsRef = props.collections.reduce(
        (refMap, collection) => {
            refMap[collection.id] = React.createRef();
            return refMap;
        },
        {}
    );

    const [scrollObj, setScrollObj] = useState<{
        scrollLeft?: number;
        scrollWidth?: number;
        clientWidth?: number;
    }>({});

    const updateScrollObj = () => {
        if (collectionWrapperRef.current) {
            const { scrollLeft, scrollWidth, clientWidth } =
                collectionWrapperRef.current;
            setScrollObj({ scrollLeft, scrollWidth, clientWidth });
        }
    };

    useEffect(() => {
        updateScrollObj();
    }, [collectionWrapperRef.current, windowSize]);

    useEffect(() => {
        if (!collectionWrapperRef?.current) {
            return;
        }
        collectionWrapperRef.current.scrollLeft = 0;
    }, [collections]);

    useEffect(() => {
        collectionChipsRef[activeCollection]?.current.scrollIntoView({
            inline: 'center',
        });
    }, [activeCollection]);

    const clickHandler = (collectionID?: number) => () => {
        setActiveCollection(collectionID ?? ALL_SECTION);
    };

    const scrollCollection = (direction: SCROLL_DIRECTION) => () => {
        collectionWrapperRef.current.scrollBy(250 * direction, 0);
    };

    return (
        <Hider hide={props.isInSearchMode}>
            <TwoScreenSpacedOptionsWithBodyPadding>
                <Typography>{constants.ALBUMS}</Typography>
                {scrollObj.scrollWidth > scrollObj.clientWidth && (
                    <Link component="button" onClick={showAllCollections}>
                        {constants.VIEW_ALL_ALBUMS}
                    </Link>
                )}
            </TwoScreenSpacedOptionsWithBodyPadding>
            <CollectionBarWrapper>
                <CollectionWithNavigationContainer>
                    {scrollObj.scrollLeft > 0 && (
                        <NavigationButton
                            scrollDirection={SCROLL_DIRECTION.LEFT}
                            onClick={scrollCollection(SCROLL_DIRECTION.LEFT)}
                        />
                    )}
                    <ScrollContainer
                        ref={collectionWrapperRef}
                        onScroll={updateScrollObj}>
                        <CollectionCardWithActiveIndicator
                            latestFile={null}
                            active={activeCollection === ALL_SECTION}
                            onClick={clickHandler(ALL_SECTION)}>
                            {constants.ALL_SECTION_NAME}
                        </CollectionCardWithActiveIndicator>
                        {collections.map((item) => (
                            <CollectionCardWithActiveIndicator
                                key={item.id}
                                latestFile={
                                    collectionSummaries.get(item.id)?.latestFile
                                }
                                ref={collectionChipsRef[item.id]}
                                active={activeCollection === item.id}
                                onClick={clickHandler(item.id)}>
                                {item.name}
                            </CollectionCardWithActiveIndicator>
                        ))}
                    </ScrollContainer>
                    {scrollObj.scrollLeft <
                        scrollObj.scrollWidth - scrollObj.clientWidth && (
                        <NavigationButton
                            scrollDirection={SCROLL_DIRECTION.RIGHT}
                            onClick={scrollCollection(SCROLL_DIRECTION.RIGHT)}
                        />
                    )}
                </CollectionWithNavigationContainer>
            </CollectionBarWrapper>
        </Hider>
    );
}
