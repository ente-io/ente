import React from 'react';
import SearchIcon from '@mui/icons-material/Search';
import { Collection } from 'types/collection';

import { EnteFile } from 'types/file';
import { SearchBarWrapper, SearchButtonWrapper } from './styledComponents';
import SearchInput from './searchInput';
import { IconButton } from '@mui/material';
import { UpdateSearch } from 'types/search';

interface Props {
    isOpen: boolean;
    isFirstFetch: boolean;
    setOpen: (value: boolean) => void;
    updateSearch: UpdateSearch;
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
