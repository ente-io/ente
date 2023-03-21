import React from 'react';
import { CollectionInfo } from 'components/Collections/CollectionInfo';
import { Typography } from '@mui/material';
import { SearchResultSummary } from 'types/search';
import { CollectionInfoBarWrapper } from 'components/Collections/styledComponents';
import { t } from 'i18next';

interface Iprops {
    searchResultSummary: SearchResultSummary;
}
export default function SearchResultInfo({ searchResultSummary }: Iprops) {
    if (!searchResultSummary) {
        return <></>;
    }

    const { optionName, fileCount } = searchResultSummary;

    return (
        <CollectionInfoBarWrapper>
            <Typography variant="subtitle" color="text.secondary">
                {t('SEARCH_RESULTS')}
            </Typography>
            <CollectionInfo name={optionName} fileCount={fileCount} />
        </CollectionInfoBarWrapper>
    );
}
