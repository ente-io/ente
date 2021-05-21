import { SetCollections, SetFiles } from 'pages/gallery';
import React, { useEffect, useState, useRef } from 'react';
import styled from 'styled-components';
import AsyncSelect from 'react-select/async';
import { components } from 'react-select';
import { useDebouncedCallback } from 'use-debounce';
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
    formatDateForLabel,
} from 'utils/search';
import constants from 'utils/strings/constants';
import LocationIcon from './LocationIcon';
import DateIcon from './DateIcon';
import CrossIcon from './CrossIcon';

const Wrapper = styled.div<{ open: boolean }>`
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
    display: ${(props) => (props.open ? 'flex' : 'none')};
`;

enum SearchType {
    DATE,
    LOCATION,
}
interface SearchParams {
    type: SearchType;
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

    useEffect(() => {
        const main = async () => {
            setAllFiles(await getLocalFiles());
            setAllCollections(await getLocalCollections());
        };
        main();
    }, []);

    const searchBarRef = useRef(null);
    useEffect(() => {
        if (props.isOpen) {
            setTimeout(() => {
                searchBarRef.current?.focus();
            }, 200);
        }
    }, [props.isOpen]);

    const getAutoCompleteSuggestion = async (searchPhrase: string) => {
        const searchedDate = parseHumanDate(searchPhrase);
        let option = new Array<SearchParams>();
        if (searchedDate != null) {
            option.push({
                type: SearchType.DATE,
                value: searchedDate,
                label: formatDateForLabel(searchedDate),
            });
        }
        const searchResults = await searchLocation(searchPhrase);
        option.push(
            ...searchResults.map(
                (searchResult) =>
                    ({
                        type: SearchType.LOCATION,
                        value: searchResult.bbox,
                        label: searchResult.placeName,
                    } as SearchParams)
            )
        );
        return option;
    };

    const filterFiles = (selectedOption: SearchParams) => {
        if (!selectedOption) {
            return;
        }
        let resultFiles: File[] = [];

        switch (selectedOption.type) {
            case SearchType.DATE:
                const searchedDate = selectedOption.value as Date;
                const filesWithSameDate = getFilesWithCreationDay(
                    allFiles,
                    searchedDate
                );
                resultFiles = filesWithSameDate;
                break;
            case SearchType.LOCATION:
                const bbox = selectedOption.value as Bbox;

                const filesTakenAtLocation = getFilesInsideBbox(allFiles, bbox);
                resultFiles = filesTakenAtLocation;
        }

        props.setFiles(resultFiles);
        props.setCollections(
            getNonEmptyCollections(allCollections, resultFiles)
        );
    };
    const closeSearchBar = ({ resetForm }) => {
        props.setOpen(false);
        props.setFiles(allFiles);
        props.setCollections(allCollections);
        resetForm();
    };

    const getIconByType = (type: SearchType) =>
        type === SearchType.DATE ? <DateIcon /> : <LocationIcon />;

    const LabelWithIcon = (props: { type: SearchType; label: string }) => (
        <div style={{ display: 'flex', alignItems: 'center' }}>
            <span style={{ marginRight: '10px' }}>
                {getIconByType(props.type)}
            </span>
            <span>{props.label}</span>
        </div>
    );
    const { Option, SingleValue } = components;
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

    const customStyles = {
        control: (provided, { isFocused }) => ({
            ...provided,
            backgroundColor: '#282828',
            color: '#d1d1d1',
            borderColor: isFocused && '#2dc262',
            boxShadow: isFocused && '0 0 3px #2dc262',
            ':hover': {
                borderColor: '#2dc262',
            },
        }),
        input: (provided) => ({
            ...provided,
            color: '#d1d1d1',
        }),
        menu: (provided) => ({
            ...provided,
            marginTop: '10px',
            backgroundColor: '#282828',
        }),
        option: (provided, { isFocused }) => ({
            ...provided,
            backgroundColor: isFocused && '#343434',
        }),
        dropdownIndicator: (provided) => ({
            ...provided,
            display: 'none',
        }),
        indicatorSeparator: (provided) => ({
            ...provided,
            display: 'none',
        }),
        clearIndicator: (provided) => ({
            ...provided,
            ':hover': { color: '#d2d2d2' },
        }),
        singleValue: (provided, state) => ({
            ...provided,
            backgroundColor: '#282828',
            color: '#d1d1d1',
        }),
    };

    const getOptions = useDebouncedCallback(getAutoCompleteSuggestion, 250);

    return (
        <Wrapper open={props.isOpen}>
            <>
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
                        }}
                        ref={searchBarRef}
                        placeholder={constants.SEARCH_HINT}
                        loadOptions={getOptions}
                        onChange={filterFiles}
                        isClearable
                        escapeClearsValue
                        styles={customStyles}
                        noOptionsMessage={() => null}
                    />
                </div>
                <div
                    style={{
                        margin: '0',
                        display: 'flex',
                        alignItems: 'center',
                        cursor: 'pointer',
                    }}
                    onClick={() => closeSearchBar({ resetForm: () => null })}
                >
                    <CrossIcon />
                </div>
            </>
        </Wrapper>
    );
}
