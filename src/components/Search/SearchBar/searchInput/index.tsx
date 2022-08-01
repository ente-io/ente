import { IconButton } from '@mui/material';
import debounce from 'debounce-promise';
import { AppContext } from 'pages/_app';
import React, { useContext, useEffect, useRef, useState } from 'react';
import { getAutoCompleteSuggestions } from 'services/searchService';
import {
    Bbox,
    DateValue,
    Search,
    SearchOption,
    SuggestionType,
} from 'types/search';
import constants from 'utils/strings/constants';
import { ValueContainerWithIcon } from './valueContainerWithIcon';
import { SelectStyles } from '../../../../styles/search';
import AsyncSelect from 'react-select/async';
import CloseIcon from '@mui/icons-material/Close';
import { UpdateSearch } from 'types/search';
import { EnteFile } from 'types/file';
import { Collection } from 'types/collection';
import { OptionWithInfo } from './optionWithInfo';
import { SearchInputWrapper } from '../styledComponents';
import MenuWithPeople from './MenuWithPeople';

interface Iprops {
    isOpen: boolean;
    updateSearch: UpdateSearch;
    setIsOpen: (value: boolean) => void;
    files: EnteFile[];
    collections: Collection[];
    setActiveCollection: (id: number) => void;
}

export default function SearchInput(props: Iprops) {
    const selectRef = useRef(null);
    const [value, setValue] = useState<SearchOption>(null);
    const appContext = useContext(AppContext);
    const handleChange = (value: SearchOption) => {
        setValue(value);
    };

    useEffect(() => search(value), [value]);

    const resetSearch = () => {
        if (props.isOpen) {
            appContext.startLoading();
            props.updateSearch(null, null);
            setTimeout(() => {
                appContext.finishLoading();
            }, 10);
            props.setIsOpen(false);
            setValue(null);
        }
    };

    const getOptions = debounce(
        getAutoCompleteSuggestions(props.files, props.collections),
        250
    );

    const search = (selectedOption: SearchOption) => {
        if (!selectedOption) {
            return;
        }
        let search: Search;
        switch (selectedOption.type) {
            case SuggestionType.DATE:
                search = {
                    date: selectedOption.value as DateValue,
                };
                props.setIsOpen(true);
                break;
            case SuggestionType.LOCATION:
                search = {
                    location: selectedOption.value as Bbox,
                };
                props.setIsOpen(true);
                break;
            case SuggestionType.COLLECTION:
                search = { collection: selectedOption.value as number };
                setValue(null);
                break;
            case SuggestionType.IMAGE:
            case SuggestionType.VIDEO:
                search = { file: selectedOption.value as number };
                setValue(null);
                break;
        }
        props.updateSearch(search, {
            optionName: selectedOption.label,
            fileCount: selectedOption.fileCount,
        });
    };

    // TODO: HACK as AsyncSelect does not support default options reloading on focus/click
    // unwanted side effect: placeholder is not shown on focus/click
    // https://github.com/JedWatson/react-select/issues/1879
    // for correct fix AsyncSelect can be extended to support default options reloading on focus/click
    const handleOnFocus = () => {
        if (appContext.mlSearchEnabled) {
            const emptySearch = ' ';
            selectRef.current.state.inputValue = emptySearch;
            selectRef.current.select.state.inputValue = emptySearch;
            selectRef.current.handleInputChange(emptySearch);
        }
    };

    return (
        <SearchInputWrapper isOpen={props.isOpen}>
            <AsyncSelect
                ref={selectRef}
                value={value}
                components={{
                    Option: OptionWithInfo,
                    ValueContainer: ValueContainerWithIcon,
                    Menu: (props) => (
                        <MenuWithPeople
                            {...props}
                            setValue={setValue}
                            selectRef={selectRef}
                        />
                    ),
                }}
                placeholder={constants.SEARCH_HINT()}
                loadOptions={getOptions}
                onChange={handleChange}
                onFocus={handleOnFocus}
                isClearable
                escapeClearsValue
                styles={SelectStyles}
                noOptionsMessage={() => null}
            />

            {props.isOpen && (
                <IconButton onClick={() => resetSearch()} sx={{ ml: 1 }}>
                    <CloseIcon />
                </IconButton>
            )}
        </SearchInputWrapper>
    );
}
