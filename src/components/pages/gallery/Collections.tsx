import NavigationButton, {
    SCROLL_DIRECTION,
} from 'components/NavigationButton';
import React, { useContext, useEffect, useRef, useState } from 'react';
import { Collection, CollectionSummaries } from 'types/collection';
import constants from 'utils/strings/constants';
import { ALL_SECTION } from 'constants/collection';
import { Link, Typography } from '@mui/material';
import {
    CollectionTileWrapper,
    CollectionTile,
    ActiveIndicator,
    Hider,
    CollectionBarWrapper,
    Header,
    CollectionWithNavigationContainer,
    ScrollContainer,
    EmptyCollectionTile,
} from 'components/collection';
import { GalleryContext } from 'pages/gallery';
import downloadManager from 'services/downloadManager';
import { EnteFile } from 'types/file';

interface CollectionProps {
    collections: Collection[];
    activeCollection?: number;
    setActiveCollection: (id?: number) => void;
    isInSearchMode: boolean;
    collectionSummaries: CollectionSummaries;
}

const CollectionTileWithActiveIndicator = React.forwardRef(
    (
        props: {
            children;
            active: boolean;
            latestFile: EnteFile;
            onClick: () => void;
        },
        ref: any
    ) => {
        const [coverImageURL, setCoverImageURL] = useState(null);
        const galleryContext = useContext(GalleryContext);
        const { latestFile: file, onClick, active, children } = props;
        useEffect(() => {
            const main = async () => {
                if (!file) {
                    return;
                }
                if (!galleryContext.thumbs.has(file.id)) {
                    const url = await downloadManager.getThumbnail(file);
                    galleryContext.thumbs.set(file.id, url);
                }
                setCoverImageURL(galleryContext.thumbs.get(file.id));
            };
            main();
        }, [file]);
        return (
            <CollectionTileWrapper ref={ref}>
                <CollectionTile coverImgURL={coverImageURL} onClick={onClick}>
                    {children}
                </CollectionTile>
                {active && <ActiveIndicator />}
            </CollectionTileWrapper>
        );
    }
);

const CreateNewCollectionHookTile = () => {
    return (
        <EmptyCollectionTile>
            <div>{constants.NEW} </div>
            <div>{'+'}</div>
        </EmptyCollectionTile>
    );
};

export default function CollectionBar(props: CollectionProps) {
    const {
        activeCollection,
        collections,
        setActiveCollection,
        collectionSummaries,
    } = props;
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
    }, [collectionWrapperRef.current, props.isInSearchMode, collections]);

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
            <CollectionBarWrapper>
                <Header>
                    <Typography>{constants.ALBUMS}</Typography>
                    {scrollObj.scrollWidth > scrollObj.clientWidth && (
                        <Link component="button">{constants.ALL_ALBUMS}</Link>
                    )}
                </Header>
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
                        <CollectionTileWithActiveIndicator
                            latestFile={null}
                            active={activeCollection === ALL_SECTION}
                            onClick={clickHandler(ALL_SECTION)}>
                            {constants.ALL_SECTION_NAME}
                        </CollectionTileWithActiveIndicator>
                        {[
                            ...collections,
                            ...collections,
                            ...collections,
                            ...collections,
                            ...collections,
                            ...collections,
                            ...collections,
                            ...collections,
                            ...collections,
                            ...collections,
                            ...collections,
                            ...collections,
                        ].map((item) => (
                            <CollectionTileWithActiveIndicator
                                key={item.id}
                                latestFile={
                                    collectionSummaries.get(item.id)?.latestFile
                                }
                                ref={collectionChipsRef[item.id]}
                                active={activeCollection === item.id}
                                onClick={clickHandler(item.id)}>
                                {item.name}
                            </CollectionTileWithActiveIndicator>
                        ))}
                        <CreateNewCollectionHookTile />
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
