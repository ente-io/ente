import React from 'react';
import { MenuItem, ListItemIcon, ListItemText } from '@mui/material';
import { COLLECTION_SORT_BY } from 'constants/collection';
import TickIcon from '@mui/icons-material/Done';
import { CollectionSortProps } from '.';

export interface SortOptionProps extends CollectionSortProps {
    close: () => void;
}

const SortByOptionCreator =
    ({ setCollectionSortBy, activeSortBy, close }: SortOptionProps) =>
    (props: { sortBy: COLLECTION_SORT_BY; children: any }) => {
        const handleClick = () => {
            setCollectionSortBy(props.sortBy);
            close();
        };
        return (
            <MenuItem onClick={handleClick} style={{ paddingLeft: '5px' }}>
                <ListItemIcon style={{ minWidth: '25px' }}>
                    {activeSortBy === props.sortBy && (
                        <TickIcon sx={{ fontSize: 16 }} />
                    )}
                </ListItemIcon>
                <ListItemText>{props.children}</ListItemText>
            </MenuItem>
        );
    };

export default SortByOptionCreator;
