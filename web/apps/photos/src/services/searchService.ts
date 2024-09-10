import log from "@/base/log";
import { FileType } from "@/media/file-type";
import {
    isMLSupported,
    mlStatusSnapshot,
    wipSearchPersons,
} from "@/new/photos/services/ml";
import { createSearchQuery, search } from "@/new/photos/services/search";
import type {
    SearchDateComponents,
    SearchPerson,
} from "@/new/photos/services/search/types";
import {
    City,
    ClipSearchScores,
    SearchOption,
    SearchQuery,
    Suggestion,
    SuggestionType,
} from "@/new/photos/services/search/types";
import type { LocationTag } from "@/new/photos/services/user-entity";
import { EnteFile } from "@/new/photos/types/file";
import { t } from "i18next";
import { Collection } from "types/collection";
import { getUniqueFiles } from "utils/file";

// Suggestions shown in the search dropdown's empty state, i.e. when the user
// selects the search bar but does not provide any input.
export const getDefaultOptions = async () => {
    return [
        await getMLStatusSuggestion(),
        ...(await convertSuggestionsToOptions(await getAllPeopleSuggestion())),
    ].filter((t) => !!t);
};

// Suggestions shown in the search dropdown when the user has typed something.
export const getAutoCompleteSuggestions =
    (files: EnteFile[], collections: Collection[]) =>
    async (searchPhrase: string): Promise<SearchOption[]> => {
        try {
            const searchPhrase2 = searchPhrase.trim().toLowerCase();
            if (!searchPhrase2?.length) {
                return [];
            }
            const suggestions: Suggestion[] = [
                // The following functionality has moved to createSearchQuery
                // - getClipSuggestion(searchPhrase)
                // - getDateSuggestion(searchPhrase),
                // - getLocationSuggestion(searchPhrase),
                // - getFileTypeSuggestion(searchPhrase),
                ...(await createSearchQuery(searchPhrase)),
                ...getCollectionSuggestion(searchPhrase2, collections),
                getFileNameSuggestion(searchPhrase2, files),
                getFileCaptionSuggestion(searchPhrase2, files),
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
    const previewImageAppendedOptions: SearchOption[] = [];
    for (const suggestion of suggestions) {
        const searchQuery = convertSuggestionToSearchQuery(suggestion);
        const resultFiles = getUniqueFiles(await search(searchQuery));
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

function convertSuggestionToSearchQuery(option: Suggestion): SearchQuery {
    switch (option.type) {
        case SuggestionType.DATE:
            return {
                date: option.value as SearchDateComponents,
            };

        case SuggestionType.LOCATION:
            return {
                location: option.value as LocationTag,
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

async function getAllPeople(limit: number = undefined) {
    return (await wipSearchPersons()).slice(0, limit);
    // TODO-Clustetr
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
