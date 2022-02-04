import React, { useRef, useEffect, useContext } from 'react';
import { VariableSizeList as List } from 'react-window';
import styled from 'styled-components';
import { EnteFile } from 'types/file';
import {
    IMAGE_CONTAINER_MAX_WIDTH,
    IMAGE_CONTAINER_MAX_HEIGHT,
    MIN_COLUMNS,
    DATE_CONTAINER_HEIGHT,
    GAP_BTW_TILES,
    SPACE_BTW_DATES,
} from 'constants/gallery';
import constants from 'utils/strings/constants';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
import { ENTE_WEBSITE_LINK } from 'constants/publicCollection';
import { getVariantColor, ButtonVariant } from './pages/gallery/LinkButton';

const A_DAY = 24 * 60 * 60 * 1000;
const NO_OF_PAGES = 2;

enum ITEM_TYPE {
    TIME = 'TIME',
    TILE = 'TILE',
    OTHER = 'OTHER',
}

interface TimeStampListItem {
    itemType: ITEM_TYPE;
    items?: EnteFile[];
    itemStartIndex?: number;
    date?: string;
    dates?: {
        date: string;
        span: number;
    }[];
    groups?: number[];
    item?: any;
    id?: string;
    height?: number;
}

const ListItem = styled.div`
    display: flex;
    justify-content: center;
`;

const getTemplateColumns = (columns: number, groups?: number[]): string => {
    if (groups) {
        const sum = groups.reduce((acc, item) => acc + item, 0);
        if (sum < columns) {
            groups[groups.length - 1] += columns - sum;
        }
        return groups
            .map((x) => `repeat(${x}, 1fr)`)
            .join(` ${SPACE_BTW_DATES}px `);
    } else {
        return `repeat(${columns}, 1fr)`;
    }
};

const ListContainer = styled.div<{ columns: number; groups?: number[] }>`
    user-select: none;
    display: grid;
    grid-template-columns: ${({ columns, groups }) =>
        getTemplateColumns(columns, groups)};
    grid-column-gap: ${GAP_BTW_TILES}px;
    padding: 0 24px;
    width: 100%;
    color: #fff;

    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * 4}px) {
        padding: 0 4px;
    }
`;

const DateContainer = styled.div<{ span: number }>`
    user-select: none;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    grid-column: span ${(props) => props.span};
    display: flex;
    align-items: center;
    height: ${DATE_CONTAINER_HEIGHT}px;
`;

const BannerContainer = styled.div<{ span: number }>`
    color: #979797;
    text-align: center;
    grid-column: span ${(props) => props.span};
    display: flex;
    justify-content: center;
    align-items: flex-end;
    & > p {
        margin: 0;
    }
    margin: 1rem 0;
`;

const AlbumsFooterContainer = styled(BannerContainer)`
    margin: calc(2rem + 20px) 0 1rem 0;
`;

const NothingContainer = styled.div<{ span: number }>`
    color: #979797;
    text-align: center;
    grid-column: span ${(props) => props.span};
    display: flex;
    justify-content: center;
    align-items: center;
`;

interface Props {
    height: number;
    width: number;
    filteredData: EnteFile[];
    showAppDownloadBanner: boolean;
    getThumbnail: (files: EnteFile[], index: number) => JSX.Element;
    activeCollection: number;
    resetFetching: () => void;
}

export function PhotoList({
    height,
    width,
    filteredData,
    showAppDownloadBanner,
    getThumbnail,
    activeCollection,
    resetFetching,
}: Props) {
    const timeStampListRef = useRef([]);
    const timeStampList = timeStampListRef?.current ?? [];
    const filteredDataCopyRef = useRef([]);
    const filteredDataCopy = filteredDataCopyRef.current ?? [];
    const listRef = useRef(null);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext
    );
    let columns = Math.floor(width / IMAGE_CONTAINER_MAX_WIDTH);
    let listItemHeight = IMAGE_CONTAINER_MAX_HEIGHT;

    let skipMerge = false;
    if (columns < MIN_COLUMNS) {
        columns = MIN_COLUMNS;
        listItemHeight = width / MIN_COLUMNS;
        skipMerge = true;
    }

    const refreshList = () => {
        listRef.current?.resetAfterIndex(0);
        resetFetching();
    };

    useEffect(() => {
        let timeStampList: TimeStampListItem[] = [];
        let listItemIndex = 0;
        let currentDate = -1;

        filteredData.forEach((item, index) => {
            if (
                !isSameDay(
                    new Date(item.metadata.creationTime / 1000),
                    new Date(currentDate)
                )
            ) {
                currentDate = item.metadata.creationTime / 1000;
                const dateTimeFormat = new Intl.DateTimeFormat('en-IN', {
                    weekday: 'short',
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                });
                timeStampList.push({
                    itemType: ITEM_TYPE.TIME,
                    date: isSameDay(new Date(currentDate), new Date())
                        ? 'Today'
                        : isSameDay(
                              new Date(currentDate),
                              new Date(Date.now() - A_DAY)
                          )
                        ? 'Yesterday'
                        : dateTimeFormat.format(currentDate),
                    id: currentDate.toString(),
                });
                timeStampList.push({
                    itemType: ITEM_TYPE.TILE,
                    items: [item],
                    itemStartIndex: index,
                });
                listItemIndex = 1;
            } else if (listItemIndex < columns) {
                timeStampList[timeStampList.length - 1].items.push(item);
                listItemIndex++;
            } else {
                listItemIndex = 1;
                timeStampList.push({
                    itemType: ITEM_TYPE.TILE,
                    items: [item],
                    itemStartIndex: index,
                });
            }
        });

        if (!skipMerge) {
            timeStampList = mergeTimeStampList(timeStampList, columns);
        }
        if (timeStampList.length === 0) {
            timeStampList.push(getEmptyListItem());
        }
        if (
            showAppDownloadBanner ||
            publicCollectionGalleryContext.accessedThroughSharedURL
        ) {
            timeStampList.push(getVacuumItem(timeStampList));
            if (publicCollectionGalleryContext.accessedThroughSharedURL) {
                timeStampList.push(getAlbumsFooter());
            } else {
                timeStampList.push(getAppDownloadFooter());
            }
        }

        timeStampListRef.current = timeStampList;
        filteredDataCopyRef.current = filteredData;
        refreshList();
    }, [
        width,
        height,
        filteredData,
        showAppDownloadBanner,
        publicCollectionGalleryContext.accessedThroughSharedURL,
    ]);

    const isSameDay = (first, second) =>
        first.getFullYear() === second.getFullYear() &&
        first.getMonth() === second.getMonth() &&
        first.getDate() === second.getDate();

    const getEmptyListItem = () => {
        return {
            itemType: ITEM_TYPE.OTHER,
            item: (
                <NothingContainer span={columns}>
                    <div>{constants.NOTHING_HERE}</div>
                </NothingContainer>
            ),
            id: 'empty-list-banner',
            height: height - 48,
        };
    };
    const getVacuumItem = (timeStampList) => {
        const photoFrameHeight = (() => {
            let sum = 0;
            const getCurrentItemSize = getItemSize(timeStampList);
            for (let i = 0; i < timeStampList.length; i++) {
                sum += getCurrentItemSize(i);
                if (height - sum <= 70) {
                    break;
                }
            }
            return sum;
        })();
        return {
            itemType: ITEM_TYPE.OTHER,
            item: <></>,
            height: Math.max(height - photoFrameHeight - 70, 0),
        };
    };
    const getAppDownloadFooter = () => {
        return {
            itemType: ITEM_TYPE.OTHER,
            item: (
                <BannerContainer span={columns}>
                    <p>{constants.INSTALL_MOBILE_APP()}</p>
                </BannerContainer>
            ),
        };
    };

    const getAlbumsFooter = () => {
        return {
            itemType: ITEM_TYPE.OTHER,
            item: (
                <AlbumsFooterContainer span={columns}>
                    <p>
                        {constants.PRESERVED_BY}{' '}
                        <a
                            target="_blank"
                            style={{
                                color: getVariantColor(ButtonVariant.success),
                            }}
                            href={ENTE_WEBSITE_LINK}
                            rel="noreferrer">
                            {constants.ENTE_IO}
                        </a>
                    </p>
                </AlbumsFooterContainer>
            ),
        };
    };
    /**
     * Checks and merge multiple dates into a single row.
     *
     * @param items
     * @param columns
     * @returns
     */
    const mergeTimeStampList = (
        items: TimeStampListItem[],
        columns: number
    ): TimeStampListItem[] => {
        const newList: TimeStampListItem[] = [];
        let index = 0;
        let newIndex = 0;
        while (index < items.length) {
            const currItem = items[index];
            // If the current item is of type time, then it is not part of an ongoing date.
            // So, there is a possibility of merge.
            if (currItem.itemType === ITEM_TYPE.TIME) {
                // If new list pointer is not at the end of list then
                // we can add more items to the same list.
                if (newList[newIndex]) {
                    // Check if items can be added to same list
                    if (
                        newList[newIndex + 1].items.length +
                            items[index + 1].items.length <=
                        columns
                    ) {
                        newList[newIndex].dates.push({
                            date: currItem.date,
                            span: items[index + 1].items.length,
                        });
                        newList[newIndex + 1].items = newList[
                            newIndex + 1
                        ].items.concat(items[index + 1].items);
                        index += 2;
                    } else {
                        // Adding items would exceed the number of columns.
                        // So, move new list pointer to the end. Hence, in next iteration,
                        // items will be added to a new list.
                        newIndex += 2;
                    }
                } else {
                    // New list pointer was at the end of list so simply add new items to the list.
                    newList.push({
                        ...currItem,
                        date: null,
                        dates: [
                            {
                                date: currItem.date,
                                span: items[index + 1].items.length,
                            },
                        ],
                    });
                    newList.push(items[index + 1]);
                    index += 2;
                }
            } else {
                // Merge cannot happen. Simply add all items to new list
                // and set new list point to the end of list.
                newList.push(currItem);
                index++;
                newIndex = newList.length;
            }
        }
        for (let i = 0; i < newList.length; i++) {
            const currItem = newList[i];
            const nextItem = newList[i + 1];
            if (currItem.itemType === ITEM_TYPE.TIME) {
                if (currItem.dates.length > 1) {
                    currItem.groups = currItem.dates.map((item) => item.span);
                    nextItem.groups = currItem.groups;
                }
            }
        }
        return newList;
    };

    const getItemSize = (timeStampList) => (index) => {
        switch (timeStampList[index].itemType) {
            case ITEM_TYPE.TIME:
                return DATE_CONTAINER_HEIGHT;
            case ITEM_TYPE.TILE:
                return listItemHeight;
            default:
                return timeStampList[index].height;
        }
    };

    const extraRowsToRender = Math.ceil(
        (NO_OF_PAGES * height) / IMAGE_CONTAINER_MAX_HEIGHT
    );

    const generateKey = (index) => {
        switch (timeStampList[index].itemType) {
            case ITEM_TYPE.TILE:
                return `${timeStampList[index].items[0].id}-${
                    timeStampList[index].items.slice(-1)[0].id
                }`;
            default:
                return `${timeStampList[index].id}-${index}`;
        }
    };

    const renderListItem = (listItem: TimeStampListItem) => {
        switch (listItem.itemType) {
            case ITEM_TYPE.TIME:
                return listItem.dates ? (
                    listItem.dates.map((item) => (
                        <>
                            <DateContainer key={item.date} span={item.span}>
                                {item.date}
                            </DateContainer>
                            <div />
                        </>
                    ))
                ) : (
                    <DateContainer span={columns}>
                        {listItem.date}
                    </DateContainer>
                );
            case ITEM_TYPE.OTHER:
                return listItem.item;
            default: {
                const ret = listItem.items.map((item, idx) =>
                    getThumbnail(
                        filteredDataCopy,
                        listItem.itemStartIndex + idx
                    )
                );
                if (listItem.groups) {
                    let sum = 0;
                    for (let i = 0; i < listItem.groups.length - 1; i++) {
                        sum = sum + listItem.groups[i];
                        ret.splice(sum, 0, <div />);
                        sum += 1;
                    }
                }
                return ret;
            }
        }
    };
    if (!timeStampList?.length) {
        return <></>;
    }

    return (
        <List
            key={`${activeCollection}`}
            ref={listRef}
            itemSize={getItemSize(timeStampList)}
            height={height}
            width={width}
            itemCount={timeStampList.length}
            itemKey={generateKey}
            overscanCount={extraRowsToRender}>
            {({ index, style }) => (
                <ListItem style={style}>
                    <ListContainer
                        columns={columns}
                        groups={timeStampList[index].groups}>
                        {renderListItem(timeStampList[index])}
                    </ListContainer>
                </ListItem>
            )}
        </List>
    );
}
