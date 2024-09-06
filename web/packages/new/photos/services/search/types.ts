/**
 * @file types shared between the main thread interface to search (`index.ts`)
 * and the search worker that does the actual searching (`worker.ts`).
 */

import { FileType } from "@/media/file-type";
import type { MLStatus } from "@/new/photos/services/ml";
import type { EnteFile } from "@/new/photos/types/file";

export interface DateSearchResult {
    components: SearchDateComponents;
    label: string;
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

// TODO-cgroup: Audit below

export interface LocationOld {
    latitude: number | null;
    longitude: number | null;
}

export interface LocationTagData {
    name: string;
    radius: number;
    aSquare: number;
    bSquare: number;
    centerPoint: LocationOld;
}

export interface City {
    city: string;
    country: string;
    lat: number;
    lng: number;
}

export enum SuggestionType {
    DATE = "DATE",
    LOCATION = "LOCATION",
    COLLECTION = "COLLECTION",
    FILE_NAME = "FILE_NAME",
    PERSON = "PERSON",
    INDEX_STATUS = "INDEX_STATUS",
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
        | MLStatus
        | LocationTagData
        | City
        | FileType
        | ClipSearchScores;
    hide?: boolean;
}

export interface SearchQuery {
    date?: SearchDateComponents;
    location?: LocationTagData;
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

export interface SearchOption extends Suggestion {
    fileCount: number;
    previewFiles: EnteFile[];
}

export type UpdateSearch = (
    search: SearchQuery,
    summary: SearchResultSummary,
) => void;

export type ClipSearchScores = Map<number, number>;
