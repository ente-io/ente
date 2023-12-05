import { IconButton } from '@mui/material';
import pDebounce from 'p-debounce';
import { AppContext } from 'pages/_app';
import React, {
    useCallback,
    useContext,
    useEffect,
    useRef,
    useState,
} from 'react';
import {
    getAutoCompleteSuggestions,
    getDefaultOptions,
} from 'services/searchService';
import {
    ClipSearchScores,
    DateValue,
    Search,
    SearchOption,
    SuggestionType,
} from 'types/search';
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
import { Person, Thing, WordGroup } from 'types/machineLearning';
import { t } from 'i18next';
import memoize from 'memoize-one';
import { LocationTagData } from 'types/entity';
import { FILE_TYPE } from 'constants/file';

interface Iprops {
    isOpen: boolean;
    updateSearch: UpdateSearch;
    setIsOpen: (value: boolean) => void;
    files: EnteFile[];
    collections: Collection[];
}

const createComponents = memoize((Option, ValueContainer, Menu) => ({
    Option,
    ValueContainer,
    Menu,
}));

export default function SearchInput(props: Iprops) {
    const selectRef = useRef(null);
    const [value, setValue] = useState<SearchOption>(null);
    const appContext = useContext(AppContext);
    const handleChange = (value: SearchOption) => {
        setValue(value);
    };
    const [defaultOptions, setDefaultOptions] = useState([]);

    useEffect(() => {
        search(value);
    }, [value]);

    useEffect(() => {
        refreshDefaultOptions();
    }, []);

    async function refreshDefaultOptions() {
        const defaultOptions = await getDefaultOptions(props.files);
        setDefaultOptions(defaultOptions);
    }

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

    const getOptions = pDebounce(
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
                    location: selectedOption.value as LocationTagData,
                };
                props.setIsOpen(true);
                break;
            case SuggestionType.COLLECTION:
                search = { collection: selectedOption.value as number };
                setValue(null);
                break;
            case SuggestionType.FILE_NAME:
                search = { files: selectedOption.value as number[] };
                break;
            case SuggestionType.FILE_CAPTION:
                search = { files: selectedOption.value as number[] };
                break;
            case SuggestionType.PERSON:
                search = { person: selectedOption.value as Person };
                break;
            case SuggestionType.THING:
                search = { thing: selectedOption.value as Thing };
                break;
            case SuggestionType.TEXT:
                search = { text: selectedOption.value as WordGroup };
                break;
            case SuggestionType.FILE_TYPE:
                search = { fileType: selectedOption.value as FILE_TYPE };
                break;
            case SuggestionType.CLIP:
                search = { clip: selectedOption.value as ClipSearchScores };
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
        refreshDefaultOptions();
    };

    const MemoizedMenuWithPeople = useCallback(
        (props) => (
            <MenuWithPeople
                {...props}
                setValue={setValue}
                selectRef={selectRef}
            />
        ),
        [setValue, selectRef]
    );

    const components = createComponents(
        OptionWithInfo,
        ValueContainerWithIcon,
        MemoizedMenuWithPeople
    );

    return (
        <SearchInputWrapper isOpen={props.isOpen}>
            <AsyncSelect
                ref={selectRef}
                value={value}
                components={components}
                placeholder={<span>{t('SEARCH_HINT')}</span>}
                loadOptions={getOptions}
                onChange={handleChange}
                onFocus={handleOnFocus}
                isClearable
                escapeClearsValue
                styles={SelectStyles}
                defaultOptions={
                    appContext.mlSearchEnabled ? defaultOptions : null
                }
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
