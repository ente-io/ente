import { Box, Tooltip } from "@mui/material";
import memoize from "memoize-one";
import React, { ReactElement } from "react";
import {
    FixedSizeList as List,
    ListChildComponentProps,
    ListItemKeySelector,
    areEqual,
} from "react-window";

export interface ItemListProps<T> {
    items: T[];
    generateItemKey: (item: T) => string | number;
    getItemTitle: (item: T) => string;
    renderListItem: (item: T) => JSX.Element;
    maxHeight?: number;
    itemSize?: number;
}

interface ItemData<T> {
    renderListItem: (item: T) => JSX.Element;
    getItemTitle: (item: T) => string;
    items: T[];
}

const createItemData: <T>(
    renderListItem: (item: T) => JSX.Element,
    getItemTitle: (item: T) => string,
    items: T[],
) => ItemData<T> = memoize((renderListItem, getItemTitle, items) => ({
    renderListItem,
    getItemTitle,
    items,
}));

// @ts-expect-error "TODO(MR): Understand and fix the type error here"
const Row: <T>({
    index,
    style,
    data,
}: ListChildComponentProps<ItemData<T>>) => ReactElement = React.memo(
    ({ index, style, data }) => {
        const { renderListItem, items, getItemTitle } = data;
        return (
            <Tooltip
                PopperProps={{
                    sx: {
                        ".MuiTooltip-tooltip.MuiTooltip-tooltip.MuiTooltip-tooltip":
                            {
                                marginTop: 0,
                            },
                    },
                }}
                title={getItemTitle(items[index])}
                placement="bottom-start"
                enterDelay={300}
                enterNextDelay={100}
            >
                <div style={style}>{renderListItem(items[index])}</div>
            </Tooltip>
        );
    },
    areEqual,
);

export default function ItemList<T>(props: ItemListProps<T>) {
    const itemData = createItemData(
        props.renderListItem,
        props.getItemTitle,
        props.items,
    );

    const getItemKey: ListItemKeySelector<ItemData<T>> = (index, data) => {
        const { items } = data;
        return props.generateItemKey(items[index]);
    };

    return (
        <Box pl={2}>
            <List
                itemData={itemData}
                height={Math.min(
                    props.itemSize * props.items.length,
                    props.maxHeight,
                )}
                width={"100%"}
                itemSize={props.itemSize}
                itemCount={props.items.length}
                itemKey={getItemKey}
            >
                {Row}
            </List>
        </Box>
    );
}
