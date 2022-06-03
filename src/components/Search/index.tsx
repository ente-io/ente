import React from 'react';
import SearchIcon from '@mui/icons-material/Search';
import { Collection } from 'types/collection';

import { IconButton } from '../Container';
import { EnteFile } from 'types/file';
import { SearchBarWrapper, SearchButtonWrapper } from './styledComponents';
import SearchInput from './input';
import { Search } from 'types/search';
import { SetSearchResultSummary } from 'types/gallery';

interface Props {
    isOpen: boolean;
    isFirstFetch: boolean;
    setOpen: (value: boolean) => void;
    setSearch: (search: Search) => void;
    setSearchResultInfo: SetSearchResultSummary;
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
