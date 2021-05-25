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
} from 'utils/search';
import constants from 'utils/strings/constants';
import LocationIcon from './LocationIcon';
import DateIcon from './DateIcon';
import SearchIcon from './SearchIcon';
import CrossIcon from './CrossIcon';

const Wrapper = styled.div`
    background-color: #111;
    color: #fff;
    min-height: 64px;
    align-items: center;
    box-shadow: 0 0 5px rgba(0, 0, 0, 0.7);
    margin-bottom: 10px;
    position: fixed;
    top: 0;
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 200;
    padding: 0 20%;
`;

enum SuggestionType {
    DATE,
    LOCATION,
}
interface Suggestion {
    type: SuggestionType;
    label: string;
    value: Bbox | Date;
}
interface Props {
    isOpen: boolean;
    setOpen: (value) => void;
    loadingBar: any;
    setFiles: SetFiles;
    setCollections: SetCollections;
}
export default function SearchBar(props: Props) {
    const [allFiles, setAllFiles] = useState<File[]>([]);
    const [allCollections, setAllCollections] = useState<Collection[]>([]);
    const selectRef = useRef(null);
    useEffect(() => {
        if (!props.isOpen && allFiles?.length > 0) {
            return;
        }
        const main = async () => {
            setAllFiles(await getLocalFiles());
            setAllCollections(await getLocalCollections());
        };
        main();
    }, [props.isOpen]);

    //==========================
    // Functionality
    //==========================
    const getAutoCompleteSuggestion = async (searchPhrase: string) => {
        let option = new Array<Suggestion>();
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
                        label: searchResult.placeName,
                    } as Suggestion)
            )
        );
        return option;
    };

    const getOptions = debounce(getAutoCompleteSuggestion, 250);

    const filterFiles = (selectedOption: Suggestion) => {
        if (!selectedOption) {
            return;
        }
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
    };
    const resetSearch = () => {
        if (props.isOpen) {
            selectRef.current.select.state.value = null;
            console.log(selectRef.current);
            props.loadingBar.current?.continuousStart();
            props.setFiles(allFiles);
            props.setCollections(allCollections);
            setTimeout(() => {
                props.loadingBar.current?.complete();
            }, 10);
            props.setOpen(false);
        }
    };

    //==========================
    // UI
    //==========================

    const getIconByType = (type: SuggestionType) =>
        type === SuggestionType.DATE ? <DateIcon /> : <LocationIcon />;

    const LabelWithIcon = (props: { type: SuggestionType; label: string }) => (
        <div style={{ display: 'flex', alignItems: 'center' }}>
            <span style={{ marginRight: '10px' }}>
                {getIconByType(props.type)}
            </span>
            <span>{props.label}</span>
        </div>
    );
    const { Option, SingleValue, Control } = components;
    const SingleValueWithIcon = (props) => (
        <SingleValue {...props}>
            <LabelWithIcon type={props.data.type} label={props.data.label} />
        </SingleValue>
    );
    const OptionWithIcon = (props) => (
        <Option {...props}>
            <LabelWithIcon type={props.data.type} label={props.data.label} />
        </Option>
    );
    const ControlWithIcon = (props) => (
        <Control {...props}>
            <span style={{ paddingLeft: '10px' }}>
                <SearchIcon />
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
            ':hover': { color: '#d2d2d2', cursor: 'pointer' },
        }),
        singleValue: (style) => ({
            ...style,
            backgroundColor: '#282828',
            color: '#d1d1d1',
        }),
    };

    return (
        <Wrapper>
            <div
                style={{
                    flex: 1,
                    maxWidth: '600px',
                    margin: '10px',
                }}
            >
                <AsyncSelect
                    components={{
                        Option: OptionWithIcon,
                        SingleValue: SingleValueWithIcon,
                        Control: ControlWithIcon,
                    }}
                    ref={selectRef}
                    placeholder={constants.SEARCH_HINT}
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
                    <div style={{ cursor: 'pointer' }} onClick={resetSearch}>
                        <CrossIcon />
                    </div>
                )}
            </div>
        </Wrapper>
    );
}
