import { isDesktop } from "@/base/app";
import log from "@/base/log";
import { FileType } from "@/media/file-type";
import {
    clipMatches,
    isMLEnabled,
    isMLSupported,
    mlStatusSnapshot,
} from "@/new/photos/services/ml";
import { parseDateComponents } from "@/new/photos/services/search";
import type {
    SearchDateComponents,
    SearchPerson,
} from "@/new/photos/services/search/types";
import { EnteFile } from "@/new/photos/types/file";
import { t } from "i18next";
import { Collection } from "types/collection";
import { EntityType, LocationTag, LocationTagData } from "types/entity";
import {
    ClipSearchScores,
    Search,
    SearchOption,
    Suggestion,
    SuggestionType,
} from "types/search";
import ComlinkSearchWorker from "utils/comlink/ComlinkSearchWorker";
import { getUniqueFiles } from "utils/file";
import { getLatestEntities } from "./entityService";
import locationSearchService, { City } from "./locationSearchService";

export const getDefaultOptions = async () => {
    return [
        await getMLStatusSuggestion(),
        ...(await convertSuggestionsToOptions(await getAllPeopleSuggestion())),
    ].filter((t) => !!t);
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
                await getClipSuggestion(searchPhrase),
                ...getFileTypeSuggestion(searchPhrase),
                ...getDateSuggestion(searchPhrase),
                ...getCollectionSuggestion(searchPhrase, collections),
                getFileNameSuggestion(searchPhrase, files),
                getFileCaptionSuggestion(searchPhrase, files),
                ...(await getLocationSuggestions(searchPhrase)),
            ].filter((suggestion) => !!suggestion);

            return convertSuggestionsToOptions(suggestions);
        } catch (e) {
            log.error("getAutoCompleteSuggestions failed", e);
            return [];
        }
    };

async function convertSuggestionsToOptions(
    suggestions: Suggestion[],
): Promise<SearchOption[]> {
    const searchWorker = await ComlinkSearchWorker.getInstance();
    const previewImageAppendedOptions: SearchOption[] = [];
    for (const suggestion of suggestions) {
        const searchQuery = convertSuggestionToSearchQuery(suggestion);
        const resultFiles = getUniqueFiles(
            await searchWorker.search(searchQuery),
        );
        if (searchQuery?.clip) {
            resultFiles.sort((a, b) => {
                const aScore = searchQuery.clip.get(a.id);
                const bScore = searchQuery.clip.get(b.id);
                return bScore - aScore;
            });
        }
        if (resultFiles.length) {
            previewImageAppendedOptions.push({
                ...suggestion,
                fileCount: resultFiles.length,
                previewFiles: resultFiles.slice(0, 3),
            });
        }
    }
    return previewImageAppendedOptions;
}
function getFileTypeSuggestion(searchPhrase: string): Suggestion[] {
    return [
        {
            label: t("IMAGE"),
            value: FileType.image,
            type: SuggestionType.FILE_TYPE,
        },
        {
            label: t("VIDEO"),
            value: FileType.video,
            type: SuggestionType.FILE_TYPE,
        },
        {
            label: t("LIVE_PHOTO"),
            value: FileType.livePhoto,
            type: SuggestionType.FILE_TYPE,
        },
    ].filter((suggestion) =>
        suggestion.label.toLowerCase().includes(searchPhrase),
    );
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
        log.error("getAllPeopleSuggestion failed", e);
        return [];
    }
}

export async function getMLStatusSuggestion(): Promise<Suggestion> {
    if (!isMLSupported) return undefined;

    const status = mlStatusSnapshot();

    if (!status || status.phase == "disabled") return undefined;

    let label: string;
    switch (status.phase) {
        case "scheduled":
            label = t("indexing_scheduled");
            break;
        case "indexing":
            label = t("indexing_photos", status);
            break;
        case "fetching":
            label = t("indexing_fetching", status);
            break;
        case "clustering":
            label = t("indexing_people", status);
            break;
        case "done":
            label = t("indexing_done", status);
            break;
    }

    return {
        label,
        type: SuggestionType.INDEX_STATUS,
        value: status,
        hide: true,
    };
}

const getDateSuggestion = (searchPhrase: string): Suggestion[] =>
    parseDateComponents(searchPhrase).map(({ components, label }) => ({
        type: SuggestionType.DATE,
        value: components,
        label,
    }));

function getCollectionSuggestion(
    searchPhrase: string,
    collections: Collection[],
): Suggestion[] {
    const collectionResults = searchCollection(searchPhrase, collections);

    return collectionResults.map(
        (searchResult) =>
            ({
                type: SuggestionType.COLLECTION,
                value: searchResult.id,
                label: searchResult.name,
            }) as Suggestion,
    );
}

function getFileNameSuggestion(
    searchPhrase: string,
    files: EnteFile[],
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
    files: EnteFile[],
): Suggestion {
    const matchedFiles = searchFilesByCaption(searchPhrase, files);
    return {
        type: SuggestionType.FILE_CAPTION,
        value: matchedFiles.map((file) => file.id),
        label: searchPhrase,
    };
}

async function getLocationSuggestions(searchPhrase: string) {
    const locationTagResults = await searchLocationTag(searchPhrase);
    const locationTagSuggestions = locationTagResults.map(
        (locationTag) =>
            ({
                type: SuggestionType.LOCATION,
                value: locationTag.data,
                label: locationTag.data.name,
            }) as Suggestion,
    );
    const locationTagNames = new Set(
        locationTagSuggestions.map((result) => result.label),
    );

    const citySearchResults =
        await locationSearchService.searchCities(searchPhrase);

    const nonConflictingCityResult = citySearchResults.filter(
        (city) => !locationTagNames.has(city.city),
    );

    const citySearchSuggestions = nonConflictingCityResult.map(
        (city) =>
            ({
                type: SuggestionType.CITY,
                value: city,
                label: city.city,
            }) as Suggestion,
    );

    return [...locationTagSuggestions, ...citySearchSuggestions];
}

async function getClipSuggestion(
    searchPhrase: string,
): Promise<Suggestion | undefined> {
    if (!isDesktop) return undefined;

    const clipResults = await searchClip(searchPhrase);
    if (!clipResults) return undefined;
    return {
        type: SuggestionType.CLIP,
        value: clipResults,
        label: searchPhrase,
    };
}

function searchCollection(
    searchPhrase: string,
    collections: Collection[],
): Collection[] {
    return collections.filter((collection) =>
        collection.name.toLowerCase().includes(searchPhrase),
    );
}

function searchFilesByName(searchPhrase: string, files: EnteFile[]) {
    return files.filter(
        (file) =>
            file.id.toString().includes(searchPhrase) ||
            file.metadata.title.toLowerCase().includes(searchPhrase),
    );
}

function searchFilesByCaption(searchPhrase: string, files: EnteFile[]) {
    return files.filter(
        (file) =>
            file.pubMagicMetadata &&
            file.pubMagicMetadata.data.caption
                ?.toLowerCase()
                .includes(searchPhrase),
    );
}

async function searchLocationTag(searchPhrase: string): Promise<LocationTag[]> {
    const locationTags = await getLatestEntities<LocationTagData>(
        EntityType.LOCATION_TAG,
    );
    const matchedLocationTags = locationTags.filter((locationTag) =>
        locationTag.data.name.toLowerCase().includes(searchPhrase),
    );
    if (matchedLocationTags.length > 0) {
        log.info(
            `Found ${matchedLocationTags.length} location tags for search phrase`,
        );
    }
    return matchedLocationTags;
}

const searchClip = async (
    searchPhrase: string,
): Promise<ClipSearchScores | undefined> => {
    if (!isMLEnabled()) return undefined;
    const matches = await clipMatches(searchPhrase);
    log.debug(() => ["clip/scores", matches]);
    return matches;
};

function convertSuggestionToSearchQuery(option: Suggestion): Search {
    switch (option.type) {
        case SuggestionType.DATE:
            return {
                date: option.value as SearchDateComponents,
            };

        case SuggestionType.LOCATION:
            return {
                location: option.value as LocationTagData,
            };

        case SuggestionType.CITY:
            return { city: option.value as City };

        case SuggestionType.COLLECTION:
            return { collection: option.value as number };

        case SuggestionType.FILE_NAME:
            return { files: option.value as number[] };

        case SuggestionType.FILE_CAPTION:
            return { files: option.value as number[] };

        case SuggestionType.PERSON:
            return { person: option.value as SearchPerson };

        case SuggestionType.FILE_TYPE:
            return { fileType: option.value as FileType };

        case SuggestionType.CLIP:
            return { clip: option.value as ClipSearchScores };
    }
}

// let done = false;
// eslint-disable-next-line @typescript-eslint/no-unused-vars
async function getAllPeople(_limit: number = undefined) {
    return [];
    // if (!(await wipClusterEnable())) return [];
    // if (done) return [];

    // done = true;
    // if (process.env.NEXT_PUBLIC_ENTE_WIP_CL_FETCH) {
    //     await syncCGroups();
    //     const people = await clusterGroups();
    //     log.debug(() => ["people", { people }]);
    // }

    // let people: Array<SearchPerson> = []; // await mlIDbStorage.getAllPeople();
    // people = await wipCluster();
    // // await mlPeopleStore.iterate<Person, void>((person) => {
    // //     people.push(person);
    // // });
    // people = people ?? [];
    // const result = people
    //     .sort((p1, p2) => p2.files.length - p1.files.length)
    //     .slice(0, limit);
    // // log.debug(() => ["getAllPeople", result]);

    // return result;
}
