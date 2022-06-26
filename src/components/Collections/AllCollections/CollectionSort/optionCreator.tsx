import React, { useContext } from 'react';
import { COLLECTION_SORT_BY } from 'constants/collection';
import TickIcon from '@mui/icons-material/Done';
import { CollectionSortProps } from '.';
import { OverflowMenuContext } from 'contexts/overflowMenu';
import { OverflowMenuOption } from 'components/OverflowMenu/option';
import { SvgIcon } from '@mui/material';

const SortByOptionCreator =
    ({ setCollectionSortBy, activeSortBy }: CollectionSortProps) =>
    (props: { sortBy: COLLECTION_SORT_BY; children: any }) => {
        const { close } = useContext(OverflowMenuContext);

        const handleClick = () => {
            setCollectionSortBy(props.sortBy);
            close();
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
