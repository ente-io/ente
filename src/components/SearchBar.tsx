import { Search, SearchStats } from 'pages/gallery';
import React, { useContext, useEffect, useRef, useState } from 'react';
import styled from 'styled-components';
import AsyncSelect from 'react-select/async';
import { components } from 'react-select';
import debounce from 'debounce-promise';
import {
    Bbox,
    getAllPeopleSuggestion,
    getHolidaySuggestion,
    getYearSuggestion,
    parseHumanDate,
    searchCollection,
    searchFiles,
    searchLocation,
} from 'services/searchService';
import { getFormattedDate } from 'utils/search';
import constants from 'utils/strings/constants';
import LocationIcon from './icons/LocationIcon';
import DateIcon from './icons/DateIcon';
import SearchIcon from './icons/SearchIcon';
import CloseIcon from './icons/CloseIcon';
import { Collection } from 'services/collectionService';
import CollectionIcon from './icons/CollectionIcon';
import { File, FILE_TYPE } from 'services/fileService';
import ImageIcon from './icons/ImageIcon';
import VideoIcon from './icons/VideoIcon';
import { IconButton } from './Container';
import { Person } from 'types/machineLearning';
import { PeopleList } from './MachineLearning/PeopleList';
import { AppContext } from 'pages/_app';

const Wrapper = styled.div<{ isDisabled: boolean; isOpen: boolean }>`
    position: fixed;
    top: 0;
    z-index: 1000;
    display: ${({ isOpen }) => (isOpen ? 'flex' : 'none')};
    width: 100%;
    background: #111;
    @media (min-width: 625px) {
        display: flex;
        width: calc(100vw - 140px);
        margin: 0 70px;
    }
    align-items: center;
    min-height: 64px;
    transition: opacity 1s ease;
    opacity: ${(props) => (props.isDisabled ? 0 : 1)};
    margin-bottom: 10px;
`;

const SearchButton = styled.div<{ isOpen: boolean }>`
    display: none;
    @media (max-width: 624px) {
        display: ${({ isOpen }) => (!isOpen ? 'flex' : 'none')};
        right: 80px;
        cursor: pointer;
        position: fixed;
        top: 0;
        z-index: 1000;
        align-items: center;
        min-height: 64px;
    }
`;

const SearchStatsContainer = styled.div`
    display: flex;
    justify-content: center;
    align-items: center;
    color: #979797;
    margin-bottom: 8px;
`;

const SearchInput = styled.div`
    width: 100%;
    display: flex;
    align-items: center;
    max-width: 484px;
    margin: auto;
`;

const Legend = styled.span`
    font-size: 20px;
    color: #ddd;
    display: inline;
    padding: 20px 10px;
`;

export enum SuggestionType {
    DATE,
    LOCATION,
    COLLECTION,
    IMAGE,
    VIDEO,
    PERSON,
}
export interface DateValue {
    date?: number;
    month?: number;
    year?: number;
}
export interface Suggestion {
    type: SuggestionType;
    label: string;
    value: Bbox | DateValue | number | Person;
    hide?: boolean;
}
interface Props {
    isOpen: boolean;
    isFirstFetch: boolean;
    setOpen: (value: boolean) => void;
    loadingBar: any;
    setSearch: (search: Search) => void;
    searchStats: SearchStats;
    collections: Collection[];
    setActiveCollection: (id: number) => void;
    files: File[];
}
export default function SearchBar(props: Props) {
    const selectRef = useRef(null);
    const [value, setValue] = useState<Suggestion>(null);
    const appContext = useContext(AppContext);

    const handleChange = (value) => {
        setValue(value);
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

    useEffect(() => search(value), [value]);

    // = =========================
    // Functionality
    // = =========================
    const getAutoCompleteSuggestions = async (searchPhrase: string) => {
        const options: Array<Suggestion> = [];
        searchPhrase = searchPhrase.trim().toLowerCase();
        if (appContext.mlSearchEnabled) {
            options.push(...(await getAllPeopleSuggestion()));
        }
        if (!searchPhrase?.length) {
            return options;
        }
        options.push(...getHolidaySuggestion(searchPhrase));
        options.push(...getYearSuggestion(searchPhrase));

        const searchedDates = parseHumanDate(searchPhrase);

        options.push(
            ...searchedDates.map((searchedDate) => ({
                type: SuggestionType.DATE,
                value: searchedDate,
                label: getFormattedDate(searchedDate),
            }))
        );

        const collectionResults = searchCollection(
            searchPhrase,
            props.collections
        );
        options.push(
            ...collectionResults.map(
                (searchResult) =>
                    ({
                        type: SuggestionType.COLLECTION,
                        value: searchResult.id,
                        label: searchResult.name,
                    } as Suggestion)
            )
        );
        const fileResults = searchFiles(searchPhrase, props.files);
        options.push(
            ...fileResults.map((file) => ({
                type:
                    file.type === FILE_TYPE.IMAGE
                        ? SuggestionType.IMAGE
                        : SuggestionType.VIDEO,
                value: file.index,
                label: file.title,
            }))
        );

        const locationResults = await searchLocation(searchPhrase);
        options.push(
            ...locationResults.map(
                (searchResult) =>
                    ({
                        type: SuggestionType.LOCATION,
                        value: searchResult.bbox,
                        label: searchResult.place,
                    } as Suggestion)
            )
        );
        return options;
    };

    const getOptions = debounce(getAutoCompleteSuggestions, 250);

    const search = (selectedOption: Suggestion) => {
        // console.log('search...');
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
                props.setSearch({ fileIndex: selectedOption.value as number });
                setValue(null);
                break;
            case SuggestionType.PERSON:
                props.setSearch({ person: selectedOption.value as Person });
                props.setOpen(true);
                break;
        }
    };
    const resetSearch = () => {
        if (props.isOpen) {
            props.loadingBar.current?.continuousStart();
            props.setSearch({});
            setTimeout(() => {
                props.loadingBar.current?.complete();
            }, 10);
            props.setOpen(false);
            setValue(null);
        }
    };

    // = =========================
    // UI
    // = =========================

    const getIconByType = (type: SuggestionType) => {
        switch (type) {
            case SuggestionType.DATE:
                return <DateIcon />;
            case SuggestionType.LOCATION:
                return <LocationIcon />;
            case SuggestionType.COLLECTION:
                return <CollectionIcon />;
            case SuggestionType.IMAGE:
                return <ImageIcon />;
            case SuggestionType.VIDEO:
                return <VideoIcon />;
            default:
                return <SearchIcon />;
        }
    };

    const LabelWithIcon = (props: { type: SuggestionType; label: string }) => (
        <div style={{ display: 'flex', alignItems: 'center' }}>
            <span style={{ paddingRight: '10px', paddingBottom: '4px' }}>
                {getIconByType(props.type)}
            </span>
            <span>{props.label}</span>
        </div>
    );
    const { Option, Control, Menu } = components;

    const OptionWithIcon = (props) =>
        !props.data.hide && (
            <Option {...props}>
                <LabelWithIcon
                    type={props.data.type}
                    label={props.data.label}
                />
            </Option>
        );
    const ControlWithIcon = (props) => (
        <Control {...props}>
            <span
                className="icon"
                style={{
                    paddingLeft: '10px',
                    paddingBottom: '4px',
                }}>
                {getIconByType(props.getValue()[0]?.type)}
            </span>
            {props.children}
        </Control>
    );

    const CustomMenu = (props) => {
        // console.log("props.selectProps.options: ", selectRef);
        const peopleSuggestions = props.selectProps.options.filter(
            (o) => o.type === SuggestionType.PERSON
        );
        const people = peopleSuggestions.map((o) => o.value);
        return (
            <Menu {...props}>
                {people && people.length > 0 && (
                    <>
                        <Legend>{constants.PEOPLE}</Legend>
                        <PeopleList
                            people={people}
                            maxRows={2}
                            onSelect={(person, index) => {
                                selectRef.current.blur();
                                setValue(peopleSuggestions[index]);
                            }}></PeopleList>
                    </>
                )}
                {props.children}
            </Menu>
        );
    };

    const customStyles = {
        control: (style, { isFocused }) => ({
            ...style,
            backgroundColor: '#282828',
            color: '#d1d1d1',
            borderColor: isFocused ? '#51cd7c' : '#444',
            boxShadow: 'none',
            ':hover': {
                borderColor: '#51cd7c',
                cursor: 'text',
                '&>.icon': { color: '#51cd7c' },
            },
        }),
        input: (style) => ({
            ...style,
            color: '#d1d1d1',
        }),
        menu: (style) => ({
            ...style,
            marginTop: '10px',
            backgroundColor: '#282828',
        }),
        option: (style, { isFocused }) => ({
            ...style,
            backgroundColor: isFocused && '#343434',
        }),
        dropdownIndicator: (style) => ({
            ...style,
            display: 'none',
        }),
        indicatorSeparator: (style) => ({
            ...style,
            display: 'none',
        }),
        clearIndicator: (style) => ({
            ...style,
            display: 'none',
        }),
        singleValue: (style, state) => ({
            ...style,
            backgroundColor: '#282828',
            color: '#d1d1d1',
            display: state.selectProps.menuIsOpen ? 'none' : 'block',
        }),
        placeholder: (style) => ({
            ...style,
            color: '#686868',
            wordSpacing: '2px',
            whiteSpace: 'nowrap',
        }),
    };
    return (
        <>
            {props.searchStats && (
                <SearchStatsContainer>
                    {constants.SEARCH_STATS(props.searchStats)}
                </SearchStatsContainer>
            )}
            <Wrapper isDisabled={props.isFirstFetch} isOpen={props.isOpen}>
                <SearchInput>
                    <div
                        style={{
                            flex: 1,
                            margin: '10px',
                        }}>
                        <AsyncSelect
                            ref={selectRef}
                            value={value}
                            components={{
                                Menu: CustomMenu,
                                Option: OptionWithIcon,
                                Control: ControlWithIcon,
                            }}
                            placeholder={constants.SEARCH_HINT()}
                            loadOptions={getOptions}
                            onChange={handleChange}
                            onFocus={handleOnFocus}
                            isClearable
                            escapeClearsValue
                            styles={customStyles}
                            noOptionsMessage={() => null}
                        />
                    </div>
                    {props.isOpen && (
                        <IconButton onClick={() => resetSearch()}>
                            <CloseIcon />
                        </IconButton>
                    )}
                </SearchInput>
            </Wrapper>
            <SearchButton
                isOpen={props.isOpen}
                onClick={() => !props.isFirstFetch && props.setOpen(true)}>
                <SearchIcon />
            </SearchButton>
        </>
    );
}
