import * as chrono from 'chrono-node';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import HTTPService from './HTTPService';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';

import { logError } from 'utils/sentry';
import {
    DateValue,
    LocationSearchResponse,
    Suggestion,
    SuggestionType,
} from 'types/search';
import { FILE_TYPE } from 'constants/file';
import { getFormattedDate, isInsideBox } from 'utils/search';

const ENDPOINT = getEndpoint();

const DIGITS = new Set(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);

export const getAutoCompleteSuggestions =
    (files: EnteFile[], collections: Collection[]) =>
    async (searchPhrase: string) => {
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

        const collectionResults = searchCollection(searchPhrase, collections);
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
        const fileResults = searchFiles(searchPhrase, files);
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
        files.map((file) => {
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

function searchCollection(
    searchPhrase: string,
    collections: Collection[]
): Collection[] {
    return collections.filter((collection) =>
        collection.name.toLowerCase().includes(searchPhrase)
    );
}

function searchFiles(searchPhrase: string, files: EnteFile[]) {
    return files
        .map((file, idx) => ({
            title: file.metadata.title,
            index: idx,
            type: file.metadata.fileType,
            ownerID: file.ownerID,
            id: file.id,
        }))
        .filter(({ title }) => title.toLowerCase().includes(searchPhrase))
        .slice(0, 4);
}
