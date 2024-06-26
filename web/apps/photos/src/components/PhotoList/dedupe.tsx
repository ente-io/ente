import { EnteFile } from "@/new/photos/types/file";
import { FlexWrapper } from "@ente/shared/components/Container";
import { Box, styled } from "@mui/material";
import {
    DATE_CONTAINER_HEIGHT,
    GAP_BTW_TILES,
    IMAGE_CONTAINER_MAX_HEIGHT,
    IMAGE_CONTAINER_MAX_WIDTH,
    MIN_COLUMNS,
    SIZE_AND_COUNT_CONTAINER_HEIGHT,
    SPACE_BTW_DATES,
} from "constants/gallery";
import { t } from "i18next";
import memoize from "memoize-one";
import React, { useEffect, useMemo, useRef, useState } from "react";
import {
    VariableSizeList as List,
    ListChildComponentProps,
    areEqual,
} from "react-window";
import { Duplicate } from "services/deduplicationService";
import { formattedByteSize } from "utils/units";

export enum ITEM_TYPE {
    TIME = "TIME",
    FILE = "FILE",
    SIZE_AND_COUNT = "SIZE_AND_COUNT",
    HEADER = "HEADER",
    FOOTER = "FOOTER",
    MARKETING_FOOTER = "MARKETING_FOOTER",
    OTHER = "OTHER",
}

export interface TimeStampListItem {
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
    fileSize?: number;
    fileCount?: number;
}

const ListItem = styled("div")`
    display: flex;
    justify-content: center;
`;

const getTemplateColumns = (
    columns: number,
    shrinkRatio: number,
    groups?: number[],
): string => {
    if (groups) {
        // need to confirm why this was there
        // const sum = groups.reduce((acc, item) => acc + item, 0);
        // if (sum < columns) {
        //     groups[groups.length - 1] += columns - sum;
        // }
        return groups
            .map(
                (x) =>
                    `repeat(${x}, ${IMAGE_CONTAINER_MAX_WIDTH * shrinkRatio}px)`,
            )
            .join(` ${SPACE_BTW_DATES}px `);
    } else {
        return `repeat(${columns},${
            IMAGE_CONTAINER_MAX_WIDTH * shrinkRatio
        }px)`;
    }
};

function getFractionFittableColumns(width: number): number {
    return (
        (width - 2 * getGapFromScreenEdge(width) + GAP_BTW_TILES) /
        (IMAGE_CONTAINER_MAX_WIDTH + GAP_BTW_TILES)
    );
}

function getGapFromScreenEdge(width: number) {
    if (width > MIN_COLUMNS * IMAGE_CONTAINER_MAX_WIDTH) {
        return 24;
    } else {
        return 4;
    }
}

function getShrinkRatio(width: number, columns: number) {
    return (
        (width -
            2 * getGapFromScreenEdge(width) -
            (columns - 1) * GAP_BTW_TILES) /
        (columns * IMAGE_CONTAINER_MAX_WIDTH)
    );
}

const ListContainer = styled(Box)<{
    columns: number;
    shrinkRatio: number;
    groups?: number[];
}>`
    display: grid;
    grid-template-columns: ${({ columns, shrinkRatio, groups }) =>
        getTemplateColumns(columns, shrinkRatio, groups)};
    grid-column-gap: ${GAP_BTW_TILES}px;
    width: 100%;
    color: #fff;
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * MIN_COLUMNS}px) {
        padding: 0 4px;
    }
`;

const ListItemContainer = styled(FlexWrapper)<{ span: number }>`
    grid-column: span ${(props) => props.span};
`;

const DateContainer = styled(ListItemContainer)`
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    height: ${DATE_CONTAINER_HEIGHT}px;
    color: ${({ theme }) => theme.colors.text.muted};
`;

const SizeAndCountContainer = styled(DateContainer)`
    margin-top: 1rem;
    height: ${SIZE_AND_COUNT_CONTAINER_HEIGHT}px;
`;

interface Props {
    height: number;
    width: number;
    duplicates: Duplicate[];
    showAppDownloadBanner: boolean;
    getThumbnail: (
        file: EnteFile,
        index: number,
        isScrolling?: boolean,
    ) => JSX.Element;
    activeCollectionID: number;
}

interface ItemData {
    timeStampList: TimeStampListItem[];
    columns: number;
    shrinkRatio: number;
    renderListItem: (
        timeStampListItem: TimeStampListItem,
        isScrolling?: boolean,
    ) => JSX.Element;
}

const createItemData = memoize(
    (
        timeStampList: TimeStampListItem[],
        columns: number,
        shrinkRatio: number,
        renderListItem: (
            timeStampListItem: TimeStampListItem,
            isScrolling?: boolean,
        ) => JSX.Element,
    ): ItemData => ({
        timeStampList,
        columns,
        shrinkRatio,
        renderListItem,
    }),
);
const PhotoListRow = React.memo(
    ({
        index,
        style,
        isScrolling,
        data,
    }: ListChildComponentProps<ItemData>) => {
        const { timeStampList, columns, shrinkRatio, renderListItem } = data;
        return (
            <ListItem style={style}>
                <ListContainer
                    columns={columns}
                    shrinkRatio={shrinkRatio}
                    groups={timeStampList[index].groups}
                >
                    {renderListItem(timeStampList[index], isScrolling)}
                </ListContainer>
            </ListItem>
        );
    },
    areEqual,
);

const getTimeStampListFromDuplicates = (duplicates: Duplicate[], columns) => {
    const timeStampList: TimeStampListItem[] = [];
    for (let index = 0; index < duplicates.length; index++) {
        const dupes = duplicates[index];
        timeStampList.push({
            itemType: ITEM_TYPE.SIZE_AND_COUNT,
            fileSize: dupes.size,
            fileCount: dupes.files.length,
        });
        let lastIndex = 0;
        while (lastIndex < dupes.files.length) {
            timeStampList.push({
                itemType: ITEM_TYPE.FILE,
                items: dupes.files.slice(lastIndex, lastIndex + columns),
                itemStartIndex: index,
            });
            lastIndex += columns;
        }
    }
    return timeStampList;
};

export function DedupePhotoList({
    height,
    width,
    duplicates,
    getThumbnail,
    activeCollectionID,
}: Props) {
    const [timeStampList, setTimeStampList] = useState<TimeStampListItem[]>([]);
    const refreshInProgress = useRef(false);
    const shouldRefresh = useRef(false);
    const listRef = useRef(null);

    const columns = useMemo(() => {
        const fittableColumns = getFractionFittableColumns(width);
        let columns = Math.floor(fittableColumns);
        if (columns < MIN_COLUMNS) {
            columns = MIN_COLUMNS;
        }
        return columns;
    }, [width]);

    const shrinkRatio = getShrinkRatio(width, columns);
    const listItemHeight =
        IMAGE_CONTAINER_MAX_HEIGHT * shrinkRatio + GAP_BTW_TILES;

    const refreshList = () => {
        listRef.current?.resetAfterIndex(0);
    };

    useEffect(() => {
        const main = () => {
            if (refreshInProgress.current) {
                shouldRefresh.current = true;
                return;
            }
            refreshInProgress.current = true;
            const timeStampList = getTimeStampListFromDuplicates(
                duplicates,
                columns,
            );
            setTimeStampList(timeStampList);
            refreshInProgress.current = false;
            if (shouldRefresh.current) {
                shouldRefresh.current = false;
                setTimeout(main, 0);
            }
        };
        main();
    }, [columns, duplicates]);

    useEffect(() => {
        refreshList();
    }, [timeStampList]);

    const getItemSize = (timeStampList) => (index) => {
        switch (timeStampList[index].itemType) {
            case ITEM_TYPE.TIME:
                return DATE_CONTAINER_HEIGHT;
            case ITEM_TYPE.SIZE_AND_COUNT:
                return SIZE_AND_COUNT_CONTAINER_HEIGHT;
            case ITEM_TYPE.FILE:
                return listItemHeight;
            default:
                return timeStampList[index].height;
        }
    };

    const generateKey = (index) => {
        switch (timeStampList[index].itemType) {
            case ITEM_TYPE.FILE:
                return `${timeStampList[index].items[0].id}-${
                    timeStampList[index].items.slice(-1)[0].id
                }`;
            default:
                return `${timeStampList[index].id}-${index}`;
        }
    };

    const renderListItem = (
        listItem: TimeStampListItem,
        isScrolling: boolean,
    ) => {
        switch (listItem.itemType) {
            case ITEM_TYPE.SIZE_AND_COUNT:
                return (
                    /*TODO: Translate the full phrase instead of piecing
                      together parts like this See:
                      https://crowdin.com/editor/ente-photos-web/9/enus-de?view=comfortable&filter=basic&value=0#8104
                      */
                    <SizeAndCountContainer span={columns}>
                        {listItem.fileCount} {t("FILES")},{" "}
                        {formattedByteSize(listItem.fileSize || 0)} {t("EACH")}
                    </SizeAndCountContainer>
                );
            case ITEM_TYPE.FILE: {
                const ret = listItem.items.map((item, idx) =>
                    getThumbnail(
                        item,
                        listItem.itemStartIndex + idx,
                        isScrolling,
                    ),
                );
                if (listItem.groups) {
                    let sum = 0;
                    for (let i = 0; i < listItem.groups.length - 1; i++) {
                        sum = sum + listItem.groups[i];
                        ret.splice(
                            sum,
                            0,
                            <div key={`${listItem.items[0].id}-gap-${i}`} />,
                        );
                        sum += 1;
                    }
                }
                return ret;
            }
            default:
                return listItem.item;
        }
    };

    if (!timeStampList?.length) {
        return <></>;
    }

    const itemData = createItemData(
        timeStampList,
        columns,
        shrinkRatio,
        renderListItem,
    );

    return (
        <List
            key={`${activeCollectionID}`}
            itemData={itemData}
            ref={listRef}
            itemSize={getItemSize(timeStampList)}
            height={height}
            width={width}
            itemCount={timeStampList.length}
            itemKey={generateKey}
            overscanCount={3}
            useIsScrolling
        >
            {PhotoListRow}
        </List>
    );
}
