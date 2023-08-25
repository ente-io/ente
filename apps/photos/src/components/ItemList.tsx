import { Box, Tooltip } from '@mui/material';
import React from 'react';
import {
    FixedSizeList as List,
    ListChildComponentProps,
    areEqual,
} from 'react-window';
import memoize from 'memoize-one';

interface Iprops {
    items: any[];
    generateItemKey: (item: any) => string;
    getItemTitle: (item: any) => string;
    renderListItem: (item: any) => JSX.Element;
    maxHeight?: number;
    itemSize?: number;
}

interface ItemData {
    renderListItem: (item: any) => JSX.Element;
    getItemTitle: (item: any) => string;
    items: any[];
}

const createItemData = memoize(
    (
        renderListItem: (item: any) => JSX.Element,
        getItemTitle: (item: any) => string,
        items: any[]
    ): ItemData => ({
        renderListItem,
        getItemTitle,
        items,
    })
);

const Row = React.memo(
    ({ index, style, data }: ListChildComponentProps<ItemData>) => {
        const { renderListItem, items, getItemTitle } = data;
        return (
            <Tooltip
                PopperProps={{
                    sx: {
                        '.MuiTooltip-tooltip.MuiTooltip-tooltip.MuiTooltip-tooltip':
                            {
                                marginTop: 0,
                            },
                    },
                }}
                title={getItemTitle(items[index])}
                placement="bottom-start"
                enterDelay={300}
                enterNextDelay={100}>
                <div style={style}>{renderListItem(items[index])}</div>
            </Tooltip>
        );
    },
    areEqual
);

export default function ItemList(props: Iprops) {
    const itemData = createItemData(
        props.renderListItem,
        props.getItemTitle,
        props.items
    );
    return (
        <Box pl={2}>
            <List
                itemData={itemData}
                height={Math.min(
                    props.itemSize * props.items.length,
                    props.maxHeight
                )}
                width={'100%'}
                itemSize={props.itemSize}
                itemCount={props.items.length}
                itemKey={props.generateItemKey}>
                {Row}
            </List>
        </Box>
    );
}
