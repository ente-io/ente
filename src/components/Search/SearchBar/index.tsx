import { SearchButton } from './searchButton';
import React from 'react';
import { Collection } from 'types/collection';

import { EnteFile } from 'types/file';
import { SearchBarWrapper } from './styledComponents';
import SearchInput from './searchInput';
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
    const showSearchInput = () => props.setOpen(true);
    return (
        <SearchBarWrapper>
            <SearchInput {...props} />
            <SearchButton
                isFirstFetch={isFirstFetch}
                show={!props.isOpen}
                openSearchInput={showSearchInput}
            />
        </SearchBarWrapper>
    );
}
