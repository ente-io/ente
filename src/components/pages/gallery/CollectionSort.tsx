import React, { useState } from 'react';
import { COLLECTION_SORT_BY } from 'constants/collection';
import Menu from '@mui/material/Menu';
import { IconButton, MenuItem } from '@mui/material';
import SortIcon from 'components/icons/SortIcon';
import TickIcon from 'components/icons/TickIcon';
import constants from 'utils/strings/constants';
import { ListItemIcon, ListItemText, MenuList, Paper } from '@mui/material';

interface Props {
    setCollectionSortBy: (sortBy: COLLECTION_SORT_BY) => void;
    activeSortBy: COLLECTION_SORT_BY;
}

interface OptionProps extends Props {
    close: () => void;
}

const SortByOptionCreator =
    ({ setCollectionSortBy, activeSortBy, close }: OptionProps) =>
    (props: { sortBy: COLLECTION_SORT_BY; children: any }) => {
        const handleClick = () => {
            setCollectionSortBy(props.sortBy);
            close();
        };
        return (
            <MenuItem onClick={handleClick}>
                <ListItemIcon
                    sx={{
                        minWidth: '30px',
                    }}>
                    {activeSortBy === props.sortBy && <TickIcon />}
                </ListItemIcon>

                <ListItemText>{props.children}</ListItemText>
            </MenuItem>
        );
    };

const CollectionSortOptions = (props: OptionProps) => {
    const SortByOption = SortByOptionCreator(props);

    return (
        <Paper sx={{ maxWidth: '100%' }}>
            <MenuList>
                <SortByOption sortBy={COLLECTION_SORT_BY.NAME}>
                    {constants.SORT_BY_NAME}
                </SortByOption>
                <SortByOption
                    sortBy={COLLECTION_SORT_BY.CREATION_TIME_DESCENDING}>
                    {constants.SORT_BY_CREATION_TIME_DESCENDING}
                </SortByOption>
                <SortByOption
                    sortBy={COLLECTION_SORT_BY.CREATION_TIME_ASCENDING}>
                    {constants.SORT_BY_CREATION_TIME_ASCENDING}
                </SortByOption>
                <SortByOption
                    sortBy={COLLECTION_SORT_BY.UPDATION_TIME_DESCENDING}>
                    {constants.SORT_BY_UPDATION_TIME_DESCENDING}
                </SortByOption>
            </MenuList>
        </Paper>
    );
};

export default function CollectionSort(props: Props) {
    const [sortByEl, setSortByEl] = useState(null);
    const handleClose = () => setSortByEl(null);
    return (
        <>
            <IconButton
                onClick={(event) => setSortByEl(event.currentTarget)}
                aria-controls={sortByEl ? 'collection-sort' : undefined}
                aria-haspopup="true"
                aria-expanded={sortByEl ? 'true' : undefined}>
                <SortIcon />
            </IconButton>
            <Menu
                id="collection-sort"
                anchorEl={sortByEl}
                open={Boolean(sortByEl)}
                onClose={handleClose}
                MenuListProps={{
                    'aria-labelledby': 'collection-sort',
                }}>
                <CollectionSortOptions {...props} close={handleClose} />
            </Menu>
        </>
    );
}
