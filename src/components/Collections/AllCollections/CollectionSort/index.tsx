import React from 'react';
import { COLLECTION_SORT_BY } from 'constants/collection';
import SortIcon from '@mui/icons-material/Sort';
import CollectionSortOptions from './options';
import OverflowMenu from 'components/OverflowMenu/menu';

export interface CollectionSortProps {
    setCollectionSortBy: (sortBy: COLLECTION_SORT_BY) => void;
    activeSortBy: COLLECTION_SORT_BY;
    nestedInDialog?: boolean;
    disableBG?: boolean;
}

export default function CollectionSort(props: CollectionSortProps) {
    return (
        <OverflowMenu
            ariaControls="collection-sort"
            triggerButtonIcon={<SortIcon />}
            menuPaperProps={{
                sx: {
                    backgroundColor: (theme) =>
                        props.nestedInDialog &&
                        theme.colors.background.elevated2,
                },
            }}
            triggerButtonProps={{
                sx: {
                    background: (theme) =>
                        !props.disableBG && theme.colors.fill.faint,
                },
            }}>
            <CollectionSortOptions {...props} />
        </OverflowMenu>
    );
}
