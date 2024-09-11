import log from "@/base/log";
import type { Collection } from "@/media/collection";
import { FileType } from "@/media/file-type";
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
import { type EnteFile } from "@/new/photos/types/file";

// Suggestions shown in the search dropdown when the user has typed something.
export const getAutoCompleteSuggestions =
    (files: EnteFile[], collections: Collection[]) =>
    async (searchPhrase: string): Promise<SearchOption[]> => {
        log.debug(() => ["getAutoCompleteSuggestions", { searchPhrase }]);
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
        const resultFiles = await search(searchQuery);
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
