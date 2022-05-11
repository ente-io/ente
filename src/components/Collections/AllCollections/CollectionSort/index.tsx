import React, { useState } from 'react';
import { COLLECTION_SORT_BY } from 'constants/collection';
import Menu from '@mui/material/Menu';
import { IconButton, styled } from '@mui/material';
import SortIcon from '@mui/icons-material/Sort';
import CollectionSortOptions from './options';

export interface CollectionSortProps {
    setCollectionSortBy: (sortBy: COLLECTION_SORT_BY) => void;
    activeSortBy: COLLECTION_SORT_BY;
}

const StyledMenu = styled(Menu)`
    & .MuiList-root {
        padding: 0;
    }
`;

export default function CollectionSort(props: CollectionSortProps) {
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
