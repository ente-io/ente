import { IconButton } from '@mui/material';
import debounce from 'debounce-promise';
import { AppContext } from 'pages/_app';
import React, { useContext, useEffect, useState } from 'react';
import { getAutoCompleteSuggestions } from 'services/searchService';
import { Bbox, DateValue, SearchOption, SuggestionType } from 'types/search';
import constants from 'utils/strings/constants';
import { ControlWithIcon } from './controlWithIcon';
import { SearchInputWrapper } from './styledComponents';
import { SelectStyles } from './styles';
import AsyncSelect from 'react-select/async';
import CloseIcon from '@mui/icons-material/Close';
import { SetSearch, SetSearchResultSummary } from 'types/gallery';
import { EnteFile } from 'types/file';
import { Collection } from 'types/collection';
import { OptionWithInfo } from './optionWithInfo';

interface Iprops {
    isOpen: boolean;
    setSearch: SetSearch;
    setOpen: (value: boolean) => void;
    files: EnteFile[];
    collections: Collection[];
    setActiveCollection: (id: number) => void;
    setSearchResultSummary: SetSearchResultSummary;
}

export default function SearchInput(props: Iprops) {
    const [value, setValue] = useState<SearchOption>(null);
    const appContext = useContext(AppContext);
    const handleChange = (value: SearchOption) => {
        setValue(value);
    };

    useEffect(() => search(value), [value]);

    const resetSearch = () => {
        if (props.isOpen) {
            appContext.startLoading();
            props.setSearch({});
            setTimeout(() => {
                appContext.finishLoading();
            }, 10);
            props.setOpen(false);
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
        switch (selectedOption.type) {
            case SuggestionType.DATE:
                props.setSearch({
                    date: selectedOption.value as DateValue,
                });
                props.setOpen(true);
                break;
            case SuggestionType.LOCATION:
                props.setSearch({
                    location: selectedOption.value as Bbox,
                });
                props.setOpen(true);
                break;
            case SuggestionType.COLLECTION:
                props.setActiveCollection(selectedOption.value as number);
                setValue(null);
                break;
            case SuggestionType.IMAGE:
            case SuggestionType.VIDEO:
                props.setSearch({ file: selectedOption.value as number });
                setValue(null);
                break;
        }
        props.setSearchResultSummary({
            optionName: selectedOption.label,
            fileCount: selectedOption.fileCount,
        });
    };

    return (
        <SearchInputWrapper>
            <AsyncSelect
                value={value}
                components={{
                    Option: OptionWithInfo,
                    Control: ControlWithIcon,
                }}
                placeholder={constants.SEARCH_HINT()}
                loadOptions={getOptions}
                onChange={handleChange}
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
