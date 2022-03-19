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
    DateValue,
    LocationSearchResponse,
    Suggestion,
    SuggestionType,
} from 'types/search';
import ObjectService from './machineLearning/objectService';
import textService from './machineLearning/textService';

const ENDPOINT = getEndpoint();

const DIGITS = new Set(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);

export function parseHumanDate(humanDate: string): DateValue[] {
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

export async function searchLocation(
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

export function getHolidaySuggestion(searchPhrase: string): Suggestion[] {
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

export function getYearSuggestion(searchPhrase: string): Suggestion[] {
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

export function searchFiles(searchPhrase: string, files: EnteFile[]) {
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
