import * as chrono from 'chrono-node';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import HTTPService from './HTTPService';
import { getAllPeople } from 'utils/machineLearning';
import constants from 'utils/strings/constants';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import { getMLSyncConfig } from 'utils/machineLearning/config';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';

import { logError } from 'utils/sentry';
import {
    Bbox,
    DateValue,
    LocationSearchResponse,
    Search,
    SearchOption,
    Suggestion,
    SuggestionType,
} from 'types/search';
import ObjectService from './machineLearning/objectService';
import textService from './machineLearning/textService';
import { FILE_TYPE } from 'constants/file';
import { getFormattedDate, isInsideBox, isSameDayAnyYear } from 'utils/search';
import { Person } from 'types/machineLearning';

const ENDPOINT = getEndpoint();

const DIGITS = new Set(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);

export const getDefaultOptions = (files: EnteFile[]) => async () => {
    return [
        await getIndexStatusSuggestion(),
        ...convertSuggestionsToOptions(await getAllPeopleSuggestion(), files),
    ];
};

export const getAutoCompleteSuggestions =
    (files: EnteFile[], collections: Collection[]) =>
    async (searchPhrase: string) => {
        searchPhrase = searchPhrase.trim().toLowerCase();
        if (!searchPhrase?.length) {
            return [];
        }
        const suggestions = [
            ...getHolidaySuggestion(searchPhrase),
            ...getYearSuggestion(searchPhrase),
            ...getDateSuggestion(searchPhrase),
            ...getCollectionSuggestion(searchPhrase, collections),
            ...getFileSuggestion(searchPhrase, files),
            ...(await getLocationSuggestions(searchPhrase)),
        ];

        return convertSuggestionsToOptions(suggestions, files);
    };

function convertSuggestionsToOptions(
    suggestions: Suggestion[],
    files: EnteFile[]
) {
    const previewImageAppendedOptions: SearchOption[] = suggestions
        .map((suggestion) => ({
            suggestion,
            searchQuery: convertSuggestionToSearchQuery(suggestion),
        }))
        .map(({ suggestion, searchQuery }) => {
            const resultFiles = files.filter((file) =>
                isSearchedFile(file, searchQuery)
            );
            return {
                ...suggestion,
                fileCount: resultFiles.length,
                previewFiles: resultFiles.slice(0, 3),
            };
        })
        .filter((option) => option.fileCount);

    return previewImageAppendedOptions;
}

function getHolidaySuggestion(searchPhrase: string): Suggestion[] {
    return [
        {
            label: 'Christmas',
            value: { month: 11, date: 25 },
            type: SuggestionType.DATE,
        },
        {
            label: 'Christmas Eve',
            value: { month: 11, date: 24 },
            type: SuggestionType.DATE,
        },
        {
            label: 'New Year',
            value: { month: 0, date: 1 },
            type: SuggestionType.DATE,
        },
        {
            label: 'New Year Eve',
            value: { month: 11, date: 31 },
            type: SuggestionType.DATE,
        },
    ].filter((suggestion) =>
        suggestion.label.toLowerCase().includes(searchPhrase)
    );
}

function getYearSuggestion(searchPhrase: string): Suggestion[] {
    if (searchPhrase.length === 4) {
        try {
            const year = parseInt(searchPhrase);
            if (year >= 1970 && year <= new Date().getFullYear()) {
                return [
                    {
                        label: searchPhrase,
                        value: { year },
                        type: SuggestionType.DATE,
                    },
                ];
            }
        } catch (e) {
            logError(e, 'getYearSuggestion failed');
        }
    }
    return [];
}

export async function getAllPeopleSuggestion(): Promise<Array<Suggestion>> {
    const people = await getAllPeople(200);
    return people.map((person) => ({
        label: person.name,
        type: SuggestionType.PERSON,
        value: person,
        hide: true,
    }));
}

export async function getIndexStatusSuggestion(): Promise<Suggestion> {
    const config = await getMLSyncConfig();
    const indexStatus = await mlIDbStorage.getIndexStatus(config.mlVersion);

    let label;
    if (!indexStatus.localFilesSynced) {
        label = constants.INDEXING_SCHEDULED;
    } else if (indexStatus.outOfSyncFilesExists) {
        label = constants.ANALYZING_PHOTOS(
            indexStatus.nSyncedFiles,
            indexStatus.nTotalFiles
        );
    } else if (!indexStatus.peopleIndexSynced) {
        label = constants.INDEXING_PEOPLE(indexStatus.nSyncedFiles);
    } else {
        label = constants.INDEXING_DONE(indexStatus.nSyncedFiles);
    }

    return {
        label,
        type: SuggestionType.INDEX_STATUS,
        value: indexStatus,
        hide: true,
    };
}

export function searchCollection(
    searchPhrase: string,
    collections: Collection[]
): Collection[] {
    return collections.filter((collection) =>
        collection.name.toLowerCase().includes(searchPhrase)
    );
}

function searchFiles(searchPhrase: string, files: EnteFile[]) {
    return files
        .map((file) => ({
            title: file.metadata.title,
            id: file.id,
            type: file.metadata.fileType,
        }))
        .filter(({ title }) => title.toLowerCase().includes(searchPhrase))
        .slice(0, 4);
}

export async function searchThing(searchPhrase: string) {
    const thingClasses = await ObjectService.getAllThingClasses();
    return thingClasses
        .filter((thingClass) =>
            thingClass.className.toLocaleLowerCase().includes(searchPhrase)
        )
        .map(({ className, files }) => ({ className, files }));
}

export async function searchText(searchPhrase: string) {
    const texts = await textService.clusterWords();
    return texts
        .filter((text) => text.word.toLocaleLowerCase().includes(searchPhrase))
        .map(({ word, files }) => ({
            word,
            files,
        }))
        .slice(0, 4);
}

function getDateSuggestion(searchPhrase: string) {
    const searchedDates = parseHumanDate(searchPhrase);

    return searchedDates.map((searchedDate) => ({
        type: SuggestionType.DATE,
        value: searchedDate,
        label: getFormattedDate(searchedDate),
    }));
}

function getCollectionSuggestion(
    searchPhrase: string,
    collections: Collection[]
) {
    const collectionResults = searchCollection(searchPhrase, collections);

    return collectionResults.map(
        (searchResult) =>
            ({
                type: SuggestionType.COLLECTION,
                value: searchResult.id,
                label: searchResult.name,
            } as Suggestion)
    );
}

function getFileSuggestion(
    searchPhrase: string,
    files: EnteFile[]
): Suggestion[] {
    const fileResults = searchFiles(searchPhrase, files);
    return fileResults.map((file) => ({
        type:
            file.type === FILE_TYPE.IMAGE
                ? SuggestionType.IMAGE
                : SuggestionType.VIDEO,
        value: file.id,
        label: file.title,
    }));
}

async function getLocationSuggestions(searchPhrase: string) {
    const locationResults = await searchLocation(searchPhrase);

    return locationResults.map(
        (searchResult) =>
            ({
                type: SuggestionType.LOCATION,
                value: searchResult.bbox,
                label: searchResult.place,
            } as Suggestion)
    );
}
function parseHumanDate(humanDate: string): DateValue[] {
    const date = chrono.parseDate(humanDate);
    const date1 = chrono.parseDate(`${humanDate} 1`);
    if (date !== null) {
        const dates = [
            { month: date.getMonth() },
            { date: date.getDate(), month: date.getMonth() },
        ];
        let reverse = false;
        humanDate.split('').forEach((c) => {
            if (DIGITS.has(c)) {
                reverse = true;
            }
        });
        if (reverse) {
            return dates.reverse();
        }
        return dates;
    }
    if (date1) {
        return [{ month: date1.getMonth() }];
    }
    return [];
}

async function searchLocation(
    searchPhrase: string
): Promise<LocationSearchResponse[]> {
    try {
        const resp = await HTTPService.get(
            `${ENDPOINT}/search/location`,
            {
                query: searchPhrase,
                limit: 4,
            },
            {
                'X-Auth-Token': getToken(),
            }
        );
        return resp.data.results ?? [];
    } catch (e) {
        logError(e, 'location search failed');
    }
    return [];
}

export function isSearchedFile(file: EnteFile, search: Search) {
    if (search?.date) {
        return isSameDayAnyYear(search.date)(
            new Date(file.metadata.creationTime / 1000)
        );
    }
    if (search?.location) {
        return isInsideBox(
            {
                latitude: file.metadata.latitude,
                longitude: file.metadata.longitude,
            },
            search.location
        );
    }
    if (search?.file) {
        return file.id === search.file;
    }
    if (search?.collection) {
        return search.collection === file.collectionID;
    }
    if (search?.person) {
        return search.person.files.indexOf(file.id) !== -1;
    }

    if (search?.thing) {
        return search.thing.files.indexOf(file.id) !== -1;
    }

    if (search?.text) {
        return search.text.files.indexOf(file.id) !== -1;
    }
    return false;
}

function convertSuggestionToSearchQuery(option: Suggestion): Search {
    switch (option.type) {
        case SuggestionType.DATE:
            return {
                date: option.value as DateValue,
            };

        case SuggestionType.LOCATION:
            return {
                location: option.value as Bbox,
            };

        case SuggestionType.COLLECTION:
            return { collection: option.value as number };

        case SuggestionType.IMAGE:
        case SuggestionType.VIDEO:
            return { file: option.value as number };

        case SuggestionType.PERSON:
            return { person: option.value as Person };
    }
}
