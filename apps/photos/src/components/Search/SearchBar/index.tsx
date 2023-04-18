import { SearchBarMobile } from './searchBarMobile';
import React from 'react';
import { Collection } from 'types/collection';

import { EnteFile } from 'types/file';
import { SearchBarWrapper } from './styledComponents';
import SearchInput from './searchInput';
import { UpdateSearch } from 'types/search';

interface Props {
    updateSearch: UpdateSearch;
    collections: Collection[];
    setActiveCollection: (id: number) => void;
    files: EnteFile[];
    isInSearchMode: boolean;
    setIsInSearchMode: (v: boolean) => void;
}

export default function SearchBar({
    setIsInSearchMode,
    isInSearchMode,
    ...props
}: Props) {
    const showSearchInput = () => setIsInSearchMode(true);

    return (
        <SearchBarWrapper>
            <SearchInput
                {...props}
                isOpen={isInSearchMode}
                setIsOpen={setIsInSearchMode}
            />
            <SearchBarMobile
                show={!isInSearchMode}
                showSearchInput={showSearchInput}
            />
        </SearchBarWrapper>
    );
}
