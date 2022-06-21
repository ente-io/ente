import React from 'react';
import { MenuList } from '@mui/material';
import { COLLECTION_SORT_BY } from 'constants/collection';
import constants from 'utils/strings/constants';
import SortByOptionCreator from './optionCreator';
import { CollectionSortProps } from '.';

export default function CollectionSortOptions(props: CollectionSortProps) {
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
}
