import SearchIcon from '@mui/icons-material/Search';
import { IconButton } from '@mui/material';
import React from 'react';
import { SearchButtonWrapper } from './styledComponents';

export function SearchButton({ isFirstFetch, show, openSearchInput }) {
    if (!show) {
        return <></>;
    }
    return (
        <SearchButtonWrapper>
            <IconButton onClick={() => !isFirstFetch && openSearchInput()}>
                <SearchIcon />
            </IconButton>
        </SearchButtonWrapper>
    );
}
