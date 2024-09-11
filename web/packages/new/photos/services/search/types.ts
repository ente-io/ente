/**
 * @file types shared between the main thread interface to search (`index.ts`)
 * and the search worker that does the actual searching (`worker.ts`).
 */

import type { Location } from "@/base/types";
import { FileType } from "@/media/file-type";
import type { EnteFile } from "@/new/photos/types/file";
import type { LocationTag } from "../user-entity";

export interface DateSearchResult {
    components: SearchDateComponents;
    label: string;
}

export interface LabelledFileType {
    fileType: FileType;
    label: string;
}

/**
 * An annotated version of {@link T} that includes its searchable "lowercased"
 * label or name.
 *
 * Precomputing these lowercased values saves us from doing the lowercasing
 * during the search itself.
 */
export type Searchable<T> = T & {
    /**
     * The name or label of T, lowercased.
     */
    lowercasedName: string;
};

/**
 * Various bits of static but locale specific data that the search worker needs
 * during searching.
 */
export interface LocalizedSearchData {
    locale: string;
    holidays: Searchable<DateSearchResult>[];
    labelledFileTypes: Searchable<LabelledFileType>[];
}

/**
 * A parsed version of a potential natural language date time string.
 *
 * All attributes which were parsed will be set. The type doesn't enforce this,
 * but it is guaranteed that at least one attribute will be present.
 */
export interface SearchDateComponents {
    /**
     * The year, if the search string specified one. e.g. `2024`.
     */
    year?: number;
    /**
     * The month (1 to 12, with December being 12), if the search string
     * specified one.
     */
    month?: number;
    /**
     * The day of the month (1 to 31), if the search string specified one.
     */
    day?: number;
    /**
     * The day of the week (0 to 6, with Sunday being 0), if the search string
     * specified one.
     */
    weekday?: number;
    /**
     * The hour of the day (0 to 23, with 0 as midnight), if the search string
     * specified one.
     */
    hour?: number;
}

/**
 * A massaged version of {@link CGroup} suitable for being shown in search
 * results.
 */
export interface SearchPerson {
    id: string;
    name?: string;
    files: number[];
    displayFaceID: string;
    displayFaceFile: EnteFile;
}

/**
 * A city as identified by a static dataset.
 *
 * Each city is represented by its latitude and longitude. The dataset does not
 * have information about the city's estimated radius.
 */
export type City = Location & {
    /** Name of the city. */
    name: string;
};

// TODO-cgroup: Audit below

export enum SuggestionType {
    DATE = "DATE",
    LOCATION = "LOCATION",
    COLLECTION = "COLLECTION",
    FILE_NAME = "FILE_NAME",
    PERSON = "PERSON",
    FILE_CAPTION = "FILE_CAPTION",
    FILE_TYPE = "FILE_TYPE",
    CLIP = "CLIP",
    CITY = "CITY",
}

export interface Suggestion {
    type: SuggestionType;
    label: string;
    value:
        | SearchDateComponents
        | number[]
        | SearchPerson
        | LocationTag
        | City
        | FileType
        | ClipSearchScores;
}

export interface SearchQuery {
    date?: SearchDateComponents;
    location?: LocationTag;
    city?: City;
    collection?: number;
    files?: number[];
    person?: SearchPerson;
    fileType?: FileType;
    clip?: ClipSearchScores;
}

export interface SearchResultSummary {
    optionName: string;
    fileCount: number;
}

export type SearchSuggestion = { label: string } & (
    | { type: "collection"; collectionID: number }
    | { type: "files"; fileIDs: number[] }
    | { type: "fileType"; fileType: FileType }
    | { type: "date"; dateComponents: SearchDateComponents }
    | { type: "location"; locationTag: LocationTag }
    | { type: "city"; city: City }
    | { type: "clip"; clipScoreForFileID: Map<number, number> }
    | { type: "cgroup"; cgroup: SearchPerson }
);

/**
 * An option shown in the the search bar's select dropdown.
 *
 * The option includes essential data that is necessary to show a corresponding
 * entry in the dropdown. If the user selects the option, then we will re-run
 * the search, using the data to filter the list of files shown to the user.
 */
export interface SearchOption extends Suggestion {
    fileCount: number;
    previewFiles: EnteFile[];
}

export type ClipSearchScores = Map<number, number>;
