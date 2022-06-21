import React, { useContext } from 'react';
import { MenuItem, ListItemIcon, ListItemText } from '@mui/material';
import { COLLECTION_SORT_BY } from 'constants/collection';
import TickIcon from '@mui/icons-material/Done';
import { CollectionSortProps } from '.';
import { OverflowMenuContext } from 'contexts/overflowMenu';

const SortByOptionCreator =
    ({ setCollectionSortBy, activeSortBy }: CollectionSortProps) =>
    (props: { sortBy: COLLECTION_SORT_BY; children: any }) => {
        const { close } = useContext(OverflowMenuContext);

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
