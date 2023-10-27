import * as chrono from 'chrono-node';
import { getAllPeople } from 'utils/machineLearning';
import { t } from 'i18next';

import mlIDbStorage from 'utils/storage/mlIDbStorage';
import { getMLSyncConfig } from 'utils/machineLearning/config';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { logError } from 'utils/sentry';
import {
    DateValue,
    Search,
    SearchOption,
    Suggestion,
    SuggestionType,
    ClipSearchScores,
} from 'types/search';
import ObjectService from './machineLearning/objectService';
import {
    getFormattedDate,
    isInsideLocationTag,
    isSameDayAnyYear,
} from 'utils/search';
import { Person, Thing } from 'types/machineLearning';
import { getUniqueFiles } from 'utils/file';
import { getLatestEntities } from './entityService';
import { LocationTag, LocationTagData, EntityType } from 'types/entity';
import { addLogLine } from 'utils/logging';
import { FILE_TYPE } from 'constants/file';
import {
    ClipService,
    computeClipMatchScore,
    getLocalClipImageEmbeddings,
} from './clipService';

const DIGITS = new Set(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);

const CLIP_SCORE_THRESHOLD = 0.23;

export const getDefaultOptions = async (files: EnteFile[]) => {
    return [
        await getIndexStatusSuggestion(),
        ...convertSuggestionsToOptions(await getAllPeopleSuggestion(), files),
    ];
};

export const getAutoCompleteSuggestions =
    (files: EnteFile[], collections: Collection[]) =>
    async (searchPhrase: string): Promise<SearchOption[]> => {
        try {
            searchPhrase = searchPhrase.trim().toLowerCase();
            if (!searchPhrase?.length) {
                return [];
            }
            const suggestions: Suggestion[] = [
                ...getFileTypeSuggestion(searchPhrase),
                ...getHolidaySuggestion(searchPhrase),
                ...getYearSuggestion(searchPhrase),
                ...getDateSuggestion(searchPhrase),
                ...getCollectionSuggestion(searchPhrase, collections),
                getFileNameSuggestion(searchPhrase, files),
                getFileCaptionSuggestion(searchPhrase, files),
                ...(await getLocationTagSuggestions(searchPhrase)),
                ...(await getThingSuggestion(searchPhrase)),
                await getClipSuggestion(searchPhrase),
            ].filter((suggestion) => !!suggestion);

            return convertSuggestionsToOptions(suggestions, files);
        } catch (e) {
            logError(e, 'getAutoCompleteSuggestions failed');
            return [];
        }
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
            const resultFiles = getUniqueFiles(
                files.filter((file) => isSearchedFile(file, searchQuery))
            );

            if (searchQuery?.clip) {
                resultFiles.sort((a, b) => {
                    const aScore = searchQuery.clip.get(a.id);
                    const bScore = searchQuery.clip.get(b.id);
                    return bScore - aScore;
                });
            }

            return {
                ...suggestion,
                fileCount: resultFiles.length,
                previewFiles: resultFiles.slice(0, 3),
            };
        })
        .filter((option) => option.fileCount);

    return previewImageAppendedOptions;
}
function getFileTypeSuggestion(searchPhrase: string): Suggestion[] {
    return [
        {
            label: t('IMAGE'),
            value: FILE_TYPE.IMAGE,
            type: SuggestionType.FILE_TYPE,
        },
        {
            label: t('VIDEO'),
            value: FILE_TYPE.VIDEO,
            type: SuggestionType.FILE_TYPE,
        },
        {
            label: t('LIVE_PHOTO'),
            value: FILE_TYPE.LIVE_PHOTO,
            type: SuggestionType.FILE_TYPE,
        },
    ].filter((suggestion) =>
        suggestion.label.toLowerCase().includes(searchPhrase)
    );
}

function getHolidaySuggestion(searchPhrase: string): Suggestion[] {
    return [
        {
            label: t('CHRISTMAS'),
            value: { month: 11, date: 25 },
            type: SuggestionType.DATE,
        },
        {
            label: t('CHRISTMAS_EVE'),
            value: { month: 11, date: 24 },
            type: SuggestionType.DATE,
        },
        {
            label: t('NEW_YEAR'),
            value: { month: 0, date: 1 },
            type: SuggestionType.DATE,
        },
        {
            label: t('NEW_YEAR_EVE'),
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
    try {
        const people = await getAllPeople(200);
        return people.map((person) => ({
            label: person.name,
            type: SuggestionType.PERSON,
            value: person,
            hide: true,
        }));
    } catch (e) {
        logError(e, 'getAllPeopleSuggestion failed');
        return [];
    }
}

export async function getIndexStatusSuggestion(): Promise<Suggestion> {
    const config = await getMLSyncConfig();
    const indexStatus = await mlIDbStorage.getIndexStatus(config.mlVersion);

    let label;
    if (!indexStatus.localFilesSynced) {
        label = t('INDEXING_SCHEDULED');
    } else if (indexStatus.outOfSyncFilesExists) {
        label = t('ANALYZING_PHOTOS', {
            indexStatus,
        });
    } else if (!indexStatus.peopleIndexSynced) {
        label = t('INDEXING_PEOPLE', { indexStatus });
    } else {
        label = t('INDEXING_DONE', { indexStatus });
    }

    return {
        label,
        type: SuggestionType.INDEX_STATUS,
        value: indexStatus,
        hide: true,
    };
}

function getDateSuggestion(searchPhrase: string): Suggestion[] {
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
): Suggestion[] {
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

function getFileNameSuggestion(
    searchPhrase: string,
    files: EnteFile[]
): Suggestion {
    const matchedFiles = searchFilesByName(searchPhrase, files);
    return {
        type: SuggestionType.FILE_NAME,
        value: matchedFiles.map((file) => file.id),
        label: searchPhrase,
    };
}

function getFileCaptionSuggestion(
    searchPhrase: string,
    files: EnteFile[]
): Suggestion {
    const matchedFiles = searchFilesByCaption(searchPhrase, files);
    return {
        type: SuggestionType.FILE_CAPTION,
        value: matchedFiles.map((file) => file.id),
        label: searchPhrase,
    };
}

async function getLocationTagSuggestions(searchPhrase: string) {
    const searchResults = await searchLocationTag(searchPhrase);

    return searchResults.map(
        (locationTag) =>
            ({
                type: SuggestionType.LOCATION,
                value: locationTag.data,
                label: locationTag.data.name,
            } as Suggestion)
    );
}

async function getThingSuggestion(searchPhrase: string): Promise<Suggestion[]> {
    const thingResults = await searchThing(searchPhrase);

    return thingResults.map(
        (searchResult) =>
            ({
                type: SuggestionType.THING,
                value: searchResult,
                label: searchResult.name,
            } as Suggestion)
    );
}

async function getClipSuggestion(searchPhrase: string): Promise<Suggestion> {
    if (!(await ClipService.isClipSupported())) {
        return null;
    }
    const clipResults = await searchClip(searchPhrase);
    return {
        type: SuggestionType.CLIP,
        value: clipResults,
        label: searchPhrase,
    };
}

function searchCollection(
    searchPhrase: string,
    collections: Collection[]
): Collection[] {
    return collections.filter((collection) =>
        collection.name.toLowerCase().includes(searchPhrase)
    );
}

function searchFilesByName(searchPhrase: string, files: EnteFile[]) {
    return files.filter((file) =>
        file.metadata.title.toLowerCase().includes(searchPhrase)
    );
}

function searchFilesByCaption(searchPhrase: string, files: EnteFile[]) {
    return files.filter(
        (file) =>
            file.pubMagicMetadata &&
            file.pubMagicMetadata.data.caption
                ?.toLowerCase()
                .includes(searchPhrase)
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

async function searchLocationTag(searchPhrase: string): Promise<LocationTag[]> {
    const locationTags = await getLatestEntities<LocationTagData>(
        EntityType.LOCATION_TAG
    );
    const matchedLocationTags = locationTags.filter((locationTag) =>
        locationTag.data.name.toLowerCase().includes(searchPhrase)
    );
    if (matchedLocationTags.length > 0) {
        addLogLine(
            `Found ${matchedLocationTags.length} location tags for search phrase`
        );
    }
    return matchedLocationTags;
}

async function searchThing(searchPhrase: string) {
    const things = await ObjectService.getAllThings();
    return things.filter((thing) =>
        thing.name.toLocaleLowerCase().includes(searchPhrase)
    );
}

async function searchClip(searchPhrase: string): Promise<ClipSearchScores> {
    const imageEmbeddings = await getLocalClipImageEmbeddings();
    const textEmbedding = await ClipService.getTextEmbedding(searchPhrase);
    const clipSearchResult = new Map<number, number>(
        (
            await Promise.all(
                imageEmbeddings.map(
                    async (imageEmbedding): Promise<[number, number]> => [
                        imageEmbedding.fileID,
                        await computeClipMatchScore(
                            imageEmbedding.embedding,
                            textEmbedding
                        ),
                    ]
                )
            )
        ).filter(([, score]) => score >= CLIP_SCORE_THRESHOLD)
    );

    return clipSearchResult;
}

function isSearchedFile(file: EnteFile, search: Search) {
    if (search?.collection) {
        return search.collection === file.collectionID;
    }

    if (search?.date) {
        return isSameDayAnyYear(search.date)(
            new Date(file.metadata.creationTime / 1000)
        );
    }
    if (search?.location) {
        return isInsideLocationTag(
            {
                latitude: file.metadata.latitude,
                longitude: file.metadata.longitude,
            },
            search.location
        );
    }
    if (search?.files) {
        return search.files.indexOf(file.id) !== -1;
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
    if (typeof search?.fileType !== 'undefined') {
        return search.fileType === file.metadata.fileType;
    }
    if (typeof search?.clip !== 'undefined') {
        return search.clip.has(file.id);
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
                location: option.value as LocationTagData,
            };

        case SuggestionType.COLLECTION:
            return { collection: option.value as number };

        case SuggestionType.FILE_NAME:
            return { files: option.value as number[] };

        case SuggestionType.FILE_CAPTION:
            return { files: option.value as number[] };

        case SuggestionType.PERSON:
            return { person: option.value as Person };

        case SuggestionType.THING:
            return { thing: option.value as Thing };
        case SuggestionType.FILE_TYPE:
            return { fileType: option.value as FILE_TYPE };
        case SuggestionType.CLIP:
            return { clip: option.value as ClipSearchScores };
    }
}
