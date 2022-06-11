import React from 'react';
import { CollectionSummary } from 'types/collection';
import { CollectionInfo } from 'components/Collections/CollectionInfo';
import constants from 'utils/strings/constants';
import { Typography } from '@mui/material';
import { CollectionSectionWrapper } from 'components/Collections/styledComponents';

interface Iprops {
    searchResult: CollectionSummary;
}
export default function SearchResultInfo({ searchResult }: Iprops) {
    if (!searchResult) {
        return <></>;
    }

    const { name, fileCount } = searchResult;

    return (
        <CollectionSectionWrapper>
            <Typography variant="subtitle" color="text.secondary">
                {constants.SEARCH_RESULTS}
            </Typography>
            <CollectionInfo name={name} fileCount={fileCount} />
        </CollectionSectionWrapper>
    );
}
