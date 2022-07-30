import { IconButton } from '@mui/material';
import { FluidContainer } from 'components/Container';
import React from 'react';
import { SearchMobileBox } from './styledComponents';
import SearchIcon from '@mui/icons-material/Search';

export function SearchBarMobile({ show, showSearchInput }) {
    if (!show) {
        return <></>;
    }
    return (
        <SearchMobileBox>
            <FluidContainer justifyContent="flex-end" ml={1.5}>
                <IconButton onClick={showSearchInput}>
                    <SearchIcon />
                </IconButton>
            </FluidContainer>
        </SearchMobileBox>
    );
}
