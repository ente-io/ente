import React from 'react';
import SearchIcon from '@mui/icons-material/Search';
import { Collection } from 'types/collection';

import { IconButton } from '../Container';
import { EnteFile } from 'types/file';
import { Search } from 'types/gallery';
import { SearchBarWrapper, SearchButtonWrapper } from './styledComponents';
import SearchInput from './input';
import { SelectionBar } from 'components/Navbar/SelectionBar';

interface Props {
    isOpen: boolean;
    isFirstFetch: boolean;
    setOpen: (value: boolean) => void;
    setSearch: (search: Search) => void;
    collections: Collection[];
    setActiveCollection: (id: number) => void;
    files: EnteFile[];
}
export default function SearchBar({ isFirstFetch, ...props }: Props) {
    return (
        <>
            <SearchBarWrapper>
                <SearchInput {...props} />
            </SearchBarWrapper>
            <SearchButtonWrapper>
                <IconButton
                    onClick={() => !isFirstFetch && props.setOpen(true)}>
                    <SearchIcon />
                </IconButton>
            </SearchButtonWrapper>
            {props.isOpen && (
                <SelectionBar>
                    <SearchInput {...props} />
                </SelectionBar>
            )}
        </>
    );
}
