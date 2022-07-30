import React from 'react';
import { CollectionInfo } from 'components/Collections/CollectionInfo';
import constants from 'utils/strings/constants';
import { Typography } from '@mui/material';
import { SearchResultSummary } from 'types/search';
import { CollectionInfoBarWrapper } from 'components/Collections/styledComponents';

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
                {constants.SEARCH_RESULTS}
            </Typography>
            <CollectionInfo name={optionName} fileCount={fileCount} />
        </CollectionInfoBarWrapper>
    );
}
