import React from 'react';
import { COLLECTION_SORT_BY } from 'constants/collection';
import TickIcon from '@mui/icons-material/Done';
import { CollectionSortProps } from '.';
import { OverflowMenuOption } from 'components/OverflowMenu/option';
import { SvgIcon } from '@mui/material';

const SortByOptionCreator =
    ({ setCollectionSortBy, activeSortBy }: CollectionSortProps) =>
    (props: { sortBy: COLLECTION_SORT_BY; children: any }) => {
        const handleClick = () => {
            setCollectionSortBy(props.sortBy);
        };

        return (
            <OverflowMenuOption
                onClick={handleClick}
                endIcon={
                    activeSortBy === props.sortBy ? <TickIcon /> : <SvgIcon />
                }>
                {props.children}
            </OverflowMenuOption>
        );
    };

export default SortByOptionCreator;
