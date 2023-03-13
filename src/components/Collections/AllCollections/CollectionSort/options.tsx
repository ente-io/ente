import React from 'react';
import { COLLECTION_SORT_BY } from 'constants/collection';
import SortByOptionCreator from './optionCreator';
import { CollectionSortProps } from '.';
import { useTranslation } from 'react-i18next';

export default function CollectionSortOptions(props: CollectionSortProps) {
    const { t } = useTranslation();

    const SortByOption = SortByOptionCreator(props);

    return (
        <>
            <SortByOption sortBy={COLLECTION_SORT_BY.NAME}>
                {t('SORT_BY_NAME')}
            </SortByOption>
            <SortByOption sortBy={COLLECTION_SORT_BY.CREATION_TIME_ASCENDING}>
                {t('SORT_BY_CREATION_TIME_ASCENDING')}
            </SortByOption>
            <SortByOption sortBy={COLLECTION_SORT_BY.UPDATION_TIME_DESCENDING}>
                {t('SORT_BY_UPDATION_TIME_DESCENDING')}
            </SortByOption>
        </>
    );
}
