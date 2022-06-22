import { SearchButton } from './searchButton';
import React, { useState } from 'react';
import { Collection } from 'types/collection';

import { EnteFile } from 'types/file';
import { SearchBarWrapper } from './styledComponents';
import SearchInput from './searchInput';
import { UpdateSearch } from 'types/search';

interface Props {
    isFirstFetch: boolean;
    updateSearch: UpdateSearch;
    collections: Collection[];
    setActiveCollection: (id: number) => void;
    files: EnteFile[];
}
export default function SearchBar({ isFirstFetch, ...props }: Props) {
    const [isOpen, setIsOpen] = useState(false);
    const showSearchInput = () => setIsOpen(true);

    return (
        <SearchBarWrapper>
            <SearchInput {...props} isOpen={isOpen} setOpen={setIsOpen} />
            <SearchButton
                isFirstFetch={isFirstFetch}
                show={!isOpen}
                openSearchInput={showSearchInput}
            />
        </SearchBarWrapper>
    );
}
