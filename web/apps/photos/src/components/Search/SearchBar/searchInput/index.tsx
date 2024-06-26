import { FILE_TYPE } from "@/media/file-type";
import { EnteFile } from "@/new/photos/types/file";
import CloseIcon from "@mui/icons-material/Close";
import { IconButton } from "@mui/material";
import { t } from "i18next";
import memoize from "memoize-one";
import pDebounce from "p-debounce";
import { AppContext } from "pages/_app";
import { useCallback, useContext, useEffect, useRef, useState } from "react";
import { components } from "react-select";
import AsyncSelect from "react-select/async";
import { InputActionMeta } from "react-select/src/types";
import type { Person } from "services/face/people";
import { City } from "services/locationSearchService";
import {
    getAutoCompleteSuggestions,
    getDefaultOptions,
} from "services/searchService";
import { Collection } from "types/collection";
import { LocationTagData } from "types/entity";
import {
    ClipSearchScores,
    DateValue,
    Search,
    SearchOption,
    SuggestionType,
    UpdateSearch,
} from "types/search";
import { SelectStyles } from "../../../../styles/search";
import { SearchInputWrapper } from "../styledComponents";
import MenuWithPeople from "./MenuWithPeople";
import { OptionWithInfo } from "./optionWithInfo";
import { ValueContainerWithIcon } from "./valueContainerWithIcon";

interface Iprops {
    isOpen: boolean;
    updateSearch: UpdateSearch;
    setIsOpen: (value: boolean) => void;
    files: EnteFile[];
    collections: Collection[];
}

const createComponents = memoize((Option, ValueContainer, Menu, Input) => ({
    Option,
    ValueContainer,
    Menu,
    Input,
}));

const VisibleInput = (props) => (
    <components.Input {...props} isHidden={false} />
);

export default function SearchInput(props: Iprops) {
    const selectRef = useRef(null);
    const [value, setValue] = useState<SearchOption>(null);
    const appContext = useContext(AppContext);
    const handleChange = (value: SearchOption) => {
        setValue(value);
        setQuery(value?.label);

        blur();
    };
    const handleInputChange = (value: string, actionMeta: InputActionMeta) => {
        if (actionMeta.action === "input-change") {
            setQuery(value);
        }
    };
    const [defaultOptions, setDefaultOptions] = useState([]);
    const [query, setQuery] = useState("");

    useEffect(() => {
        search(value);
    }, [value]);

    useEffect(() => {
        refreshDefaultOptions();
        const t = setInterval(() => refreshDefaultOptions(), 2000);
        return () => clearInterval(t);
    }, []);

    async function refreshDefaultOptions() {
        const defaultOptions = await getDefaultOptions();
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
            setQuery("");
        }
    };

    const getOptions = useCallback(
        pDebounce(
            getAutoCompleteSuggestions(props.files, props.collections),
            250,
        ),
        [props.files, props.collections],
    );

    const blur = () => {
        selectRef.current?.blur();
    };

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
            case SuggestionType.CITY:
                search = {
                    city: selectedOption.value as City,
                };
                props.setIsOpen(true);
                break;
            case SuggestionType.COLLECTION:
                search = { collection: selectedOption.value as number };
                setValue(null);
                setQuery("");
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
        [setValue, selectRef],
    );

    const components = createComponents(
        OptionWithInfo,
        ValueContainerWithIcon,
        MemoizedMenuWithPeople,
        VisibleInput,
    );

    return (
        <SearchInputWrapper isOpen={props.isOpen}>
            <AsyncSelect
                ref={selectRef}
                value={value}
                components={components}
                placeholder={<span>{t("SEARCH_HINT")}</span>}
                loadOptions={getOptions}
                onChange={handleChange}
                onFocus={handleOnFocus}
                isClearable
                inputValue={query}
                onInputChange={handleInputChange}
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
