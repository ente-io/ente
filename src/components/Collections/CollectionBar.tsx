import NavigationButton, {
    SCROLL_DIRECTION,
} from 'components/Collections/NavigationButton';
import React, { useEffect } from 'react';
import { Collection, CollectionSummaries } from 'types/collection';
import constants from 'utils/strings/constants';
import { ALL_SECTION } from 'constants/collection';
import { Link, Typography } from '@mui/material';
import {
    Hider,
    CollectionBarWrapper,
    ScrollContainer,
    TwoScreenSpacedOptionsWithBodyPadding,
} from 'components/Collections/styledComponents';
import CollectionCardWithActiveIndicator from 'components/Collections/CollectionCardWithActiveIndicator';
import useComponentScroll from 'hooks/useComponentScroll';
import useWindowSize from 'hooks/useWindowSize';

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
    const {
        componentRef,
        scrollComponent,
        hasScrollBar,
        onFarLeft,
        onFarRight,
    } = useComponentScroll({
        dependencies: [windowSize, collections],
    });

    const collectionChipsRef = props.collections.reduce(
        (refMap, collection) => {
            refMap[collection.id] = React.createRef();
            return refMap;
        },
        {}
    );

    useEffect(() => {
        collectionChipsRef[activeCollection]?.current.scrollIntoView({
            inline: 'center',
        });
    }, [activeCollection]);

    const clickHandler = (collectionID?: number) => () => {
        setActiveCollection(collectionID ?? ALL_SECTION);
    };

    return (
        <Hider hide={props.isInSearchMode}>
            <TwoScreenSpacedOptionsWithBodyPadding>
                <Typography>{constants.ALBUMS}</Typography>
                {hasScrollBar && (
                    <Link component="button" onClick={showAllCollections}>
                        {constants.VIEW_ALL_ALBUMS}
                    </Link>
                )}
            </TwoScreenSpacedOptionsWithBodyPadding>
            <CollectionBarWrapper>
                {!onFarLeft && (
                    <NavigationButton
                        scrollDirection={SCROLL_DIRECTION.LEFT}
                        onClick={scrollComponent(SCROLL_DIRECTION.LEFT)}
                    />
                )}
                <ScrollContainer ref={componentRef}>
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
                {!onFarRight && (
                    <NavigationButton
                        scrollDirection={SCROLL_DIRECTION.RIGHT}
                        onClick={scrollComponent(SCROLL_DIRECTION.RIGHT)}
                    />
                )}
            </CollectionBarWrapper>
        </Hider>
    );
}
