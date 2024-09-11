import { isDesktop } from "@/base/app";
import log from "@/base/log";
import { masterKeyFromSession } from "@/base/session-store";
import { ComlinkWorker } from "@/base/worker/comlink-worker";
import type { Collection } from "@/media/collection";
import { FileType } from "@/media/file-type";
import type { LocationTag } from "@/new/photos/services/user-entity";
import i18n, { t } from "i18next";
import type { EnteFile } from "../../types/file";
import { clipMatches, isMLEnabled } from "../ml";
import type {
    City,
    ClipSearchScores,
    DateSearchResult,
    LabelledFileType,
    LocalizedSearchData,
    SearchableData,
    SearchDateComponents,
    SearchOption,
    SearchPerson,
    SearchQuery,
    Suggestion,
} from "./types";
import { SuggestionType } from "./types";
import type { SearchWorker } from "./worker";

/**
 * Cached instance of the {@link ComlinkWorker} that wraps our web worker.
 */
let _comlinkWorker: ComlinkWorker<typeof SearchWorker> | undefined;

/**
 * Lazily created, cached, instance of {@link SearchWorker}.
 */
const worker = () => (_comlinkWorker ??= createComlinkWorker()).remote;

/**
 * Create a new instance of a comlink worker that wraps a {@link SearchWorker}
 * web worker.
 */
const createComlinkWorker = () =>
    new ComlinkWorker<typeof SearchWorker>(
        "search",
        new Worker(new URL("worker.ts", import.meta.url)),
    );

/**
 * Perform any logout specific cleanup for the search subsystem.
 */
export const logoutSearch = () => {
    if (_comlinkWorker) {
        _comlinkWorker.terminate();
        _comlinkWorker = undefined;
    }
    _localizedSearchData = undefined;
};

/**
 * Fetch any data that would be needed if the user were to search.
 */
export const triggerSearchDataSync = () =>
    void worker().then((w) => masterKeyFromSession().then((k) => w.sync(k)));

/**
 * Set the collections and files over which we should search.
 */
export const setSearchableData = (data: SearchableData) =>
    void worker().then((w) => w.setSearchableData(data));

/**
 * Convert a search string into a reusable "search query" that can be passed on
 * to the {@link search} function.
 *
 * @param searchString The string we want to search for.
 */
export const createSearchQuery = async (searchString: string) => {
    // Normalize it by trimming whitespace and converting to lowercase.
    const s = searchString.trim().toLowerCase();
    if (s.length == 0) return [];

    // The CLIP matching code already runs in the ML worker, so let that run
    // separately, in parallel with the rest of the search query construction in
    // the search worker, then combine the two.
    const results = await Promise.all([
        clipSuggestions(s, searchString).then((s) => s ?? []),
        worker().then((w) => w.createSearchQuery(s, localizedSearchData())),
    ]);
    return results.flat();
};

const clipSuggestions = async (s: string, searchString: string) => {
    if (!isDesktop) return undefined;
    if (!isMLEnabled()) return undefined;

    const matches = await clipMatches(s);
    if (!matches) return undefined;
    return {
        type: SuggestionType.CLIP,
        value: matches,
        label: searchString,
    };
};

/**
 * Search for and return the list of {@link EnteFile}s that match the given
 * {@link search} query.
 */
export const search = async (search: SearchQuery) =>
    worker().then((w) => w.search(search));

/**
 * Cached value of {@link localizedSearchData}.
 */
let _localizedSearchData: LocalizedSearchData | undefined;

/*
 * For searching, the web worker needs a bunch of otherwise static data that has
 * names and labels formed by localized strings.
 *
 * Since it would be tricky to get the t() function to work in a web worker, we
 * instead pass this from the main thread (lazily initialized and cached).
 *
 * Note that these need to be evaluated at runtime, and cannot be static
 * constants since t() depends on the user's locale.
 *
 * We currently clear the cached data on logout, but this is not necessary. The
 * only point we necessarily need to clear this data is if the user changes their
 * preferred locale, but currently we reload the page in such cases so any in
 * memory state would be reset that way.
 */
const localizedSearchData = () =>
    (_localizedSearchData ??= {
        locale: i18n.language,
        holidays: holidays().map((h) => ({
            ...h,
            lowercasedName: h.label.toLowerCase(),
        })),
        labelledFileTypes: labelledFileTypes().map((t) => ({
            ...t,
            lowercasedName: t.label.toLowerCase(),
        })),
    });

/**
 * A list of holidays - their yearly dates and localized names.
 */
const holidays = (): DateSearchResult[] => [
    { components: { month: 12, day: 25 }, label: t("CHRISTMAS") },
    { components: { month: 12, day: 24 }, label: t("CHRISTMAS_EVE") },
    { components: { month: 1, day: 1 }, label: t("NEW_YEAR") },
    { components: { month: 12, day: 31 }, label: t("NEW_YEAR_EVE") },
];

/**
 * A list of file types with their localized names.
 */
const labelledFileTypes = (): LabelledFileType[] => [
    { fileType: FileType.image, label: t("IMAGE") },
    { fileType: FileType.video, label: t("VIDEO") },
    { fileType: FileType.livePhoto, label: t("LIVE_PHOTO") },
];

// TODO-Cluster -- AUDIT BELOW THIS

// Suggestions shown in the search dropdown when the user has typed something.
export const getAutoCompleteSuggestions =
    (files: EnteFile[], collections: Collection[]) =>
    async (searchPhrase: string): Promise<SearchOption[]> => {
        log.debug(() => [
            "getAutoCompleteSuggestions",
            { searchPhrase, collections },
        ]);
        try {
            const searchPhrase2 = searchPhrase.trim().toLowerCase();
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
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
                getFileCaptionSuggestion(searchPhrase2, files),
                // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
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
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (searchQuery?.clip) {
            resultFiles.sort((a, b) => {
                const aScore = searchQuery.clip?.get(a.id) ?? 0;
                const bScore = searchQuery.clip?.get(b.id) ?? 0;
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

function searchFilesByCaption(searchPhrase: string, files: EnteFile[]) {
    return files.filter(
        (file) =>
            // eslint-disable-next-line @typescript-eslint/prefer-optional-chain
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
