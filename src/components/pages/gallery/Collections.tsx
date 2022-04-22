import { SetDialogMessage } from 'components/MessageDialog';
import NavigationButton, {
    SCROLL_DIRECTION,
} from 'components/NavigationButton';
import React, { useEffect, useRef, useState } from 'react';
import styled from 'styled-components';
import { IMAGE_CONTAINER_MAX_WIDTH } from 'constants/gallery';
import { Collection, CollectionAndItsLatestFile } from 'types/collection';
import constants from 'utils/strings/constants';
import { SetCollectionNamerAttributes } from './CollectionNamer';
import { ALL_SECTION } from 'constants/collection';
import { Link } from '@mui/material';

interface CollectionProps {
    collections: Collection[];
    collectionAndTheirLatestFile: CollectionAndItsLatestFile[];
    activeCollection?: number;
    setActiveCollection: (id?: number) => void;
    setDialogMessage: SetDialogMessage;
    syncWithRemote: () => Promise<void>;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    startLoading: () => void;
    finishLoading: () => void;
    isInSearchMode: boolean;
    collectionFilesCount: Map<number, number>;
}

const SAMPLE_URL =
    'https://images.unsplash.com/photo-1615789591457-74a63395c990?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MXx8YmFieSUyMGNhdHxlbnwwfHwwfHw%3D&w=1000&q=80';

const CollectionContainer = styled.div`
    overflow: hidden;
    height: 86px;
    display: flex;
    position: relative;
`;

const ScrollWrapper = styled.div`
    width: calc(100%- 80px);
    height: 100px;
    overflow: auto;
    max-width: 100%;
    scroll-behavior: smooth;
    display: flex;
`;

const CollectionBar = styled.div`
    width: 100%;
    margin: 10px auto;
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * 4}px) {
        padding: 0 4px;
    }
    border-bottom: 1px solid ${({ theme }) => theme.palette.grey.A400};
`;

const EmptyCollectionTile = styled.div`
    flex-shrink: 0;
    display: flex;
    width: 80px;
    height: 64px;
    border-radius: 4px;
    padding: 4px 6px;
    align-items: flex-end;
    border: 1px dashed ${({ theme }) => theme.palette.grey.A200};
    justify-content: space-between;
    user-select: none;
    cursor: pointer;
`;

const CollectionTile = styled(EmptyCollectionTile)<{ coverImgURL: string }>`
    background-image: url(${({ coverImgURL }) => coverImgURL});
    background-size: cover;
    border: none;
`;

const CollectionTileWrapper = styled.div`
    margin-right: 6px;
`;

const ActiveIndicator = styled.div`
    height: 3px;
    background-color: ${({ theme }) => theme.palette.text.primary};
    margin-top: 18px;
    border-radius: 2px;
`;

const Hider = styled.div<{ hide: boolean }>`
    opacity: ${(props) => (props.hide ? '0' : '100')};
    height: ${(props) => (props.hide ? '0' : 'auto')};
`;

const Header = styled.div`
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8px;
`;
const CollectionTileWithActiveIndicator = React.forwardRef(
    (
        props: {
            children;

            active: boolean;
            coverImgURL: string;
            onClick: () => void;
        },
        ref: any
    ) => {
        return (
            <CollectionTileWrapper ref={ref}>
                <CollectionTile
                    coverImgURL={props.coverImgURL}
                    onClick={props.onClick}>
                    {props.children}
                </CollectionTile>
                {props.active && <ActiveIndicator />}
            </CollectionTileWrapper>
        );
    }
);

export default function Collections(props: CollectionProps) {
    const { activeCollection, collections, setActiveCollection } = props;
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
            <CollectionBar>
                <Header>
                    {constants.ALBUMS}
                    {scrollObj.scrollWidth > scrollObj.clientWidth && (
                        <Link component="button">{constants.ALL_ALBUMS}</Link>
                    )}
                </Header>
                <CollectionContainer>
                    {/* {scrollObj.scrollLeft > 0 && ( */}
                    <NavigationButton
                        scrollDirection={SCROLL_DIRECTION.LEFT}
                        onClick={scrollCollection(SCROLL_DIRECTION.LEFT)}
                    />
                    {/* )} */}
                    <ScrollWrapper
                        ref={collectionWrapperRef}
                        onScroll={updateScrollObj}>
                        <CollectionTileWithActiveIndicator
                            coverImgURL={SAMPLE_URL}
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
                                ref={collectionChipsRef[item.id]}
                                active={activeCollection === item.id}
                                onClick={clickHandler(item.id)}
                                coverImgURL={SAMPLE_URL}>
                                {item.name}
                            </CollectionTileWithActiveIndicator>
                        ))}
                        <EmptyCollectionTile>
                            <div>{constants.NEW} </div>
                            <div>{'+'}</div>
                        </EmptyCollectionTile>
                    </ScrollWrapper>
                    {/* {scrollObj.scrollLeft < */}
                    {/* scrollObj.scrollWidth - scrollObj.clientWidth && ( */}
                    <NavigationButton
                        scrollDirection={SCROLL_DIRECTION.RIGHT}
                        onClick={scrollCollection(SCROLL_DIRECTION.RIGHT)}
                    />
                    {/* )}  */}
                </CollectionContainer>
            </CollectionBar>
        </Hider>
    );
}
