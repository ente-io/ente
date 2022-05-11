import React, { useState } from 'react';
import { COLLECTION_SORT_BY } from 'constants/collection';
import Menu from '@mui/material/Menu';
import { IconButton, MenuItem, styled } from '@mui/material';
import constants from 'utils/strings/constants';
import { ListItemIcon, ListItemText, MenuList } from '@mui/material';
import SortIcon from '@mui/icons-material/Sort';
import { default as TickIcon } from '@mui/icons-material/Done';

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
            <MenuItem onClick={handleClick} style={{ paddingLeft: '5px' }}>
                <ListItemIcon style={{ minWidth: '25px' }}>
                    {activeSortBy === props.sortBy && (
                        <TickIcon
                            css={`
                                height: 16px;
                                width: 16px;
                            `}
                        />
                    )}
                </ListItemIcon>
                <ListItemText>{props.children}</ListItemText>
            </MenuItem>
        );
    };

const CollectionSortOptions = (props: OptionProps) => {
    const SortByOption = SortByOptionCreator(props);

    return (
        <MenuList>
            <SortByOption sortBy={COLLECTION_SORT_BY.NAME}>
                {constants.SORT_BY_NAME}
            </SortByOption>
            <SortByOption sortBy={COLLECTION_SORT_BY.CREATION_TIME_DESCENDING}>
                {constants.SORT_BY_CREATION_TIME_DESCENDING}
            </SortByOption>
            <SortByOption sortBy={COLLECTION_SORT_BY.CREATION_TIME_ASCENDING}>
                {constants.SORT_BY_CREATION_TIME_ASCENDING}
            </SortByOption>
            <SortByOption sortBy={COLLECTION_SORT_BY.UPDATION_TIME_DESCENDING}>
                {constants.SORT_BY_UPDATION_TIME_DESCENDING}
            </SortByOption>
        </MenuList>
    );
};

const StyledMenu = styled(Menu)`
    & .MuiList-root {
        padding: 0;
    }
`;

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
            <StyledMenu
                id="collection-sort"
                anchorEl={sortByEl}
                open={Boolean(sortByEl)}
                onClose={handleClose}
                MenuListProps={{
                    'aria-labelledby': 'collection-sort',
                }}>
                <CollectionSortOptions {...props} close={handleClose} />
            </StyledMenu>
        </>
    );
}
