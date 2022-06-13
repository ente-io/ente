import ScrollButton from 'components/Collections/CollectionBar/ScrollButton';
import React, { useEffect, useMemo } from 'react';
import { CollectionSummaries } from 'types/collection';
import constants from 'utils/strings/constants';
import { ALL_SECTION, COLLECTION_SORT_BY } from 'constants/collection';
import { Typography } from '@mui/material';
import {
    CollectionListBarWrapper,
    ScrollContainer,
    CollectionListWrapper,
} from 'components/Collections/styledComponents';
import CollectionCardWithActiveIndicator from 'components/Collections/CollectionBar/CollectionCardWithActiveIndicator';
import useComponentScroll, { SCROLL_DIRECTION } from 'hooks/useComponentScroll';
import useWindowSize from 'hooks/useWindowSize';
import LinkButton from 'components/pages/gallery/LinkButton';
import { SpaceBetweenFlex } from 'components/Container';
import { sortCollectionSummaries } from 'services/collectionService';

interface IProps {
    activeCollection?: number;
    setActiveCollection: (id?: number) => void;
    collectionSummaries: CollectionSummaries;
    showAllCollections: () => void;
}

export default function CollectionBar(props: IProps) {
    const {
        activeCollection,
        setActiveCollection,
        collectionSummaries,
        showAllCollections,
    } = props;

    const sortedCollectionSummary = useMemo(
        () =>
            sortCollectionSummaries(
                [...collectionSummaries.values()].filter(
                    (c) => c.fileCount > 0
                ),
                COLLECTION_SORT_BY.UPDATION_TIME_DESCENDING
            ),
        [collectionSummaries]
    );

    const windowSize = useWindowSize();

    const {
        componentRef,
        scrollComponent,
        hasScrollBar,
        onFarLeft,
        onFarRight,
    } = useComponentScroll({
        dependencies: [windowSize, collectionSummaries],
    });

    const collectionChipsRef = sortedCollectionSummary.reduce(
        (refMap, collectionSummary) => {
            refMap[collectionSummary.id] = React.createRef();
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
        <CollectionListBarWrapper>
            <SpaceBetweenFlex mb={1}>
                <Typography>{constants.ALBUMS}</Typography>
                {hasScrollBar && (
                    <LinkButton onClick={showAllCollections}>
                        {constants.VIEW_ALL_ALBUMS}
                    </LinkButton>
                )}
            </SpaceBetweenFlex>

            <CollectionListWrapper>
                {!onFarLeft && (
                    <ScrollButton
                        scrollDirection={SCROLL_DIRECTION.LEFT}
                        onClick={scrollComponent(SCROLL_DIRECTION.LEFT)}
                    />
                )}
                <ScrollContainer ref={componentRef}>
                    {sortedCollectionSummary.map((item) => (
                        <CollectionCardWithActiveIndicator
                            key={item.id}
                            latestFile={item.latestFile}
                            ref={collectionChipsRef[item.id]}
                            active={activeCollection === item.id}
                            onClick={clickHandler(item.id)}
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
        </CollectionListBarWrapper>
    );
}
