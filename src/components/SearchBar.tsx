import { SetCollections, SetFiles } from 'pages/gallery';
import React, { useEffect, useState, useRef } from 'react';
import styled from 'styled-components';
import AsyncSelect from 'react-select/async';
import { components } from 'react-select';
import debounce from 'debounce-promise';
import { File, getLocalFiles } from 'services/fileService';
import {
    Collection,
    getLocalCollections,
    getNonEmptyCollections,
} from 'services/collectionService';
import { Bbox, parseHumanDate, searchLocation } from 'services/searchService';
import {
    getFilesWithCreationDay,
    getFilesInsideBbox,
    getFormattedDate,
    getDefaultSuggestions,
} from 'utils/search';
import constants from 'utils/strings/constants';
import LocationIcon from './LocationIcon';
import DateIcon from './DateIcon';
import SearchIcon from './SearchIcon';
import CrossIcon from './CrossIcon';

const Wrapper = styled.div<{ width: number }>`
    position: fixed;
    z-index: 1000;
    top: 0;
    opacity: 0;
    left: ${(props) => `max(0px, 50% - min(360px,${props.width / 2}px))`};
    width: 100%;
    max-width: 720px;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0 5%;
    background-color: #111;
    color: #fff;
    min-height: 64px;
    box-shadow: 0 0 5px rgba(0, 0, 0, 0.7);
    margin-bottom: 10px;
`;

const SearchButton = styled.div`
    top: 1px;
    z-index: 100;
    right: 80px;
    color: #fff;
    cursor: pointer;
    min-height: 64px;
    position: fixed;
    display: flex;
    align-items: center;
    justify-content: center;
`;

const SearchStats = styled.div`
    display: flex;
    justify-content: center;
    align-items: center;
    color: #979797;
`;

export enum SuggestionType {
    DATE,
    LOCATION,
}
export interface Suggestion {
    type: SuggestionType;
    label: string;
    value: Bbox | Date;
}
interface Props {
    isOpen: boolean;
    isFirstFetch: boolean;
    setOpen: (value) => void;
    loadingBar: any;
    setFiles: SetFiles;
    setCollections: SetCollections;
}
interface Stats {
    resultCount: number;
    timeTaken: number;
}
export default function SearchBar(props: Props) {
    const [allFiles, setAllFiles] = useState<File[]>([]);
    const [allCollections, setAllCollections] = useState<Collection[]>([]);
    const [windowWidth, setWindowWidth] = useState(window.innerWidth);
    const [stats, setStats] = useState<Stats>(null);
    const selectRef = useRef(null);
    useEffect(() => {
        if (props.isOpen) {
            setTimeout(() => {
                selectRef.current?.focus();
            }, 250);
        }
        if (!props.isOpen && allFiles?.length > 0) {
            return;
        }
        const main = async () => {
            setAllFiles(await getLocalFiles());
            setAllCollections(await getLocalCollections());
        };
        main();
    }, [props.isOpen]);

    useEffect(() => {
        window.addEventListener('resize', () =>
            setWindowWidth(window.innerWidth)
        );
    });
    //==========================
    // Functionality
    //==========================
    const getAutoCompleteSuggestions = async (searchPhrase: string) => {
        let option = getDefaultSuggestions().filter((suggestion) =>
            suggestion.label.toLowerCase().includes(searchPhrase.toLowerCase())
        );

        if (!searchPhrase?.length) {
            return option;
        }
        const searchedDate = parseHumanDate(searchPhrase);
        if (searchedDate != null) {
            option.push({
                type: SuggestionType.DATE,
                value: searchedDate,
                label: getFormattedDate(searchedDate),
            });
        }
        const searchResults = await searchLocation(searchPhrase);
        option.push(
            ...searchResults.map(
                (searchResult) =>
                    ({
                        type: SuggestionType.LOCATION,
                        value: searchResult.bbox,
                        label: searchResult.place,
                    } as Suggestion)
            )
        );
        return option;
    };

    const getOptions = debounce(getAutoCompleteSuggestions, 250);

    const filterFiles = (selectedOption: Suggestion) => {
        if (!selectedOption) {
            return;
        }
        const startTime = Date.now();
        props.setOpen(true);
        let resultFiles: File[] = [];

        switch (selectedOption.type) {
            case SuggestionType.DATE:
                const searchedDate = selectedOption.value as Date;
                const filesWithSameDate = getFilesWithCreationDay(
                    allFiles,
                    searchedDate
                );
                resultFiles = filesWithSameDate;
                break;
            case SuggestionType.LOCATION:
                const bbox = selectedOption.value as Bbox;

                const filesTakenAtLocation = getFilesInsideBbox(allFiles, bbox);
                resultFiles = filesTakenAtLocation;
        }
        props.setFiles(resultFiles);
        props.setCollections(
            getNonEmptyCollections(allCollections, resultFiles)
        );
        const timeTaken = (Date.now() - startTime) / 1000;
        setStats({
            timeTaken,
            resultCount: resultFiles.length,
        });
    };
    const resetSearch = () => {
        if (props.isOpen) {
            selectRef.current.select.state.value = null;
            props.loadingBar.current?.continuousStart();
            props.setFiles(allFiles);
            props.setCollections(allCollections);
            setTimeout(() => {
                props.loadingBar.current?.complete();
            }, 10);
            props.setOpen(false);
            setStats(null);
        }
    };

    //==========================
    // UI
    //==========================

    const getIconByType = (type: SuggestionType) =>
        type === SuggestionType.DATE ? <DateIcon /> : <LocationIcon />;

    const LabelWithIcon = (props: { type: SuggestionType; label: string }) => (
        <div style={{ display: 'flex', alignItems: 'center' }}>
            <span style={{ paddingRight: '10px', paddingBottom: '4px' }}>
                {getIconByType(props.type)}
            </span>
            <span>{props.label}</span>
        </div>
    );
    const { Option, Control } = components;

    const OptionWithIcon = (props) => (
        <Option {...props}>
            <LabelWithIcon type={props.data.type} label={props.data.label} />
        </Option>
    );
    const ControlWithIcon = (props) => (
        <Control {...props}>
            <span
                className={'icon'}
                style={{
                    paddingLeft: '10px',
                    paddingBottom: '4px',
                }}
            >
                {props.getValue().length == 0 || props.menuIsOpen ? (
                    <SearchIcon />
                ) : props.getValue()[0].type == SuggestionType.DATE ? (
                    <DateIcon />
                ) : (
                    <LocationIcon />
                )}
            </span>
            {props.children}
        </Control>
    );

    const customStyles = {
        control: (style, { isFocused }) => ({
            ...style,
            backgroundColor: '#282828',
            color: '#d1d1d1',
            borderColor: isFocused ? '#2dc262' : '#444',
            boxShadow: isFocused && '0 0 3px #2dc262',
            ':hover': {
                borderColor: '#2dc262',
                cursor: 'text',
                '&>.icon': { color: '#2dc262' },
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
        }),
    };
    return (
        <>
            {windowWidth > 1000 || props.isOpen ? (
                <Wrapper
                    width={windowWidth}
                    className={!props.isFirstFetch && 'fadeIn'}
                >
                    <div
                        style={{
                            flex: 1,
                            margin: '10px',
                        }}
                    >
                        <AsyncSelect
                            components={{
                                Option: OptionWithIcon,
                                Control: ControlWithIcon,
                            }}
                            ref={selectRef}
                            placeholder={constants.SEARCH_HINT()}
                            loadOptions={getOptions}
                            onChange={filterFiles}
                            isClearable
                            escapeClearsValue
                            styles={customStyles}
                            noOptionsMessage={() => null}
                        />
                    </div>
                    <div style={{ width: '24px' }}>
                        {props.isOpen && (
                            <div
                                style={{ cursor: 'pointer' }}
                                onClick={resetSearch}
                            >
                                <CrossIcon />
                            </div>
                        )}
                    </div>
                </Wrapper>
            ) : (
                <SearchButton onClick={() => props.setOpen(true)}>
                    <SearchIcon />
                </SearchButton>
            )}
            {props.isOpen && stats && (
                <SearchStats>{constants.SEARCH_STATS(stats)}</SearchStats>
            )}
        </>
    );
}
