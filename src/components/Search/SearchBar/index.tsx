import React from 'react';
import SearchIcon from '@mui/icons-material/Search';
import { Collection } from 'types/collection';

import { EnteFile } from 'types/file';
import { SearchBarWrapper, SearchButtonWrapper } from './styledComponents';
import SearchInput from './searchInput';
import { Search } from 'types/search';
import { SetSearchResultSummary } from 'types/gallery';
import { IconButton } from '@mui/material';

interface Props {
    isOpen: boolean;
    isFirstFetch: boolean;
    setOpen: (value: boolean) => void;
    setSearch: (search: Search) => void;
    setSearchResultSummary: SetSearchResultSummary;
    collections: Collection[];
    setActiveCollection: (id: number) => void;
    files: EnteFile[];
}
export default function SearchBar({ isFirstFetch, ...props }: Props) {
    return (
        <>
            <SearchBarWrapper isOpen={props.isOpen}>
                <SearchInput {...props} />
            </SearchBarWrapper>
            {!props.isOpen && (
                <SearchButtonWrapper>
                    <IconButton
                        onClick={() => !isFirstFetch && props.setOpen(true)}>
                        <SearchIcon />
                    </IconButton>
                </SearchButtonWrapper>
            )}
        </>
    );
}
