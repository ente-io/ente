import React, { useContext, useEffect, useState } from 'react';
import styled from 'styled-components';
import AsyncSelect from 'react-select/async';
import { components } from 'react-select';
import debounce from 'debounce-promise';
import {
    getHolidaySuggestion,
    getYearSuggestion,
    parseHumanDate,
    searchCollection,
    searchFiles,
    searchLocation,
} from 'services/searchService';
import { getFormattedDate, isInsideBox } from 'utils/search';
import constants from 'utils/strings/constants';
import LocationIcon from '../icons/LocationIcon';
import DateIcon from '../icons/DateIcon';
import SearchIcon from '../icons/SearchIcon';
import CloseIcon from '@mui/icons-material/Close';
import { Collection } from 'types/collection';
import CollectionIcon from '../icons/CollectionIcon';

import ImageIcon from '../icons/ImageIcon';
import VideoIcon from '../icons/VideoIcon';
import { IconButton } from '../Container';
import { EnteFile } from 'types/file';
import { Suggestion, SuggestionType, DateValue, Bbox } from 'types/search';
import { Search, SearchStats } from 'types/gallery';
import { FILE_TYPE } from 'constants/file';
import { SelectStyles } from './styles';
import { AppContext } from 'pages/_app';

const Wrapper = styled.div<{ isDisabled: boolean; isOpen: boolean }>`
    display: ${({ isOpen }) => (isOpen ? 'flex' : 'none')};
    width: 100%;
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
        cursor: pointer;
        align-items: center;
        min-height: 64px;
    }
`;

const SearchInput = styled.div`
    width: 100%;
    display: flex;
    align-items: center;
    max-width: 484px;
    margin: auto;
`;

interface Props {
    isOpen: boolean;
    isFirstFetch: boolean;
    setOpen: (value: boolean) => void;
    setSearch: (search: Search) => void;
    searchStats: SearchStats;
    collections: Collection[];
    setActiveCollection: (id: number) => void;
    files: EnteFile[];
}
export default function SearchBar(props: Props) {
    const [value, setValue] = useState<Suggestion>(null);
    const appContext = useContext(AppContext);
    const handleChange = (value) => {
        setValue(value);
    };

    useEffect(() => search(value), [value]);

    // = =========================
    // Functionality
    // = =========================
    const getAutoCompleteSuggestions = async (searchPhrase: string) => {
        searchPhrase = searchPhrase.trim().toLowerCase();
        if (!searchPhrase?.length) {
            return [];
        }
        const options = [
            ...getHolidaySuggestion(searchPhrase),
            ...getYearSuggestion(searchPhrase),
        ];

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

        const locationResultsHasFiles: boolean[] = new Array(
            locationResults.length
        ).fill(false);
        props.files.map((file) => {
            for (const [index, location] of locationResults.entries()) {
                if (
                    isInsideBox(
                        {
                            latitude: file.metadata.latitude,
                            longitude: file.metadata.longitude,
                        },
                        location.bbox
                    )
                ) {
                    locationResultsHasFiles[index] = true;
                }
            }
        });
        const filteredLocationWithFiles = locationResults.filter(
            (_, index) => locationResultsHasFiles[index]
        );
        options.push(
            ...filteredLocationWithFiles.map(
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
        }
    };
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
    const { Option, Control } = components;

    const OptionWithIcon = (props) => (
        <Option {...props}>
            <LabelWithIcon type={props.data.type} label={props.data.label} />
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
    return (
        <>
            <Wrapper isDisabled={props.isFirstFetch} isOpen={props.isOpen}>
                <SearchInput>
                    <div
                        style={{
                            flex: 1,
                            margin: '10px',
                        }}>
                        <AsyncSelect
                            value={value}
                            components={{
                                Option: OptionWithIcon,
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
