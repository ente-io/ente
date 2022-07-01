import { IconButton } from '@mui/material';
import { FluidContainer } from 'components/Container';
import { EnteLogo } from 'components/EnteLogo';
import React from 'react';
import { SearchMobileBox } from './styledComponents';
import SearchIcon from '@mui/icons-material/Search';

export function SearchBarMobile({ show, showSearchInput }) {
    if (!show) {
        return <></>;
    }
    return (
        <SearchMobileBox>
            <FluidContainer justifyContent="center" mr={1.5}>
                <EnteLogo />
            </FluidContainer>
            <IconButton onClick={showSearchInput}>
                <SearchIcon />
            </IconButton>
        </SearchMobileBox>
    );
}
