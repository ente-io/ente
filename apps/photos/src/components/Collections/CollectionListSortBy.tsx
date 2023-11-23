import React from 'react';
import { COLLECTION_LIST_SORT_BY } from 'constants/collection';
import SortIcon from '@mui/icons-material/Sort';
import OverflowMenu from '@ente/shared/components/OverflowMenu/menu';
import SvgIcon from '@mui/material/SvgIcon';
import TickIcon from '@mui/icons-material/Done';
import { OverflowMenuOption } from '@ente/shared/components/OverflowMenu/option';
import { t } from 'i18next';

interface CollectionSortProps {
    setSortBy: (sortBy: COLLECTION_LIST_SORT_BY) => void;
    activeSortBy: COLLECTION_LIST_SORT_BY;
    nestedInDialog?: boolean;
    disableBG?: boolean;
}

const SortByOptionCreator =
    ({ setSortBy, activeSortBy }: CollectionSortProps) =>
    (props: { sortBy: COLLECTION_LIST_SORT_BY; children: any }) => {
        const handleClick = () => {
            setSortBy(props.sortBy);
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

export default function CollectionListSortBy(props: CollectionSortProps) {
    const SortByOption = SortByOptionCreator(props);

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
            <SortByOption sortBy={COLLECTION_LIST_SORT_BY.NAME}>
                {t('SORT_BY_NAME')}
            </SortByOption>
            <SortByOption
                sortBy={COLLECTION_LIST_SORT_BY.CREATION_TIME_ASCENDING}>
                {t('SORT_BY_CREATION_TIME_ASCENDING')}
            </SortByOption>
            <SortByOption
                sortBy={COLLECTION_LIST_SORT_BY.UPDATION_TIME_DESCENDING}>
                {t('SORT_BY_UPDATION_TIME_DESCENDING')}
            </SortByOption>
        </OverflowMenu>
    );
}
