/**
 * @file types shared between the main thread interface to search (`index.ts`)
 * and the search worker (`worker.ts`)
 */

import type { EnteFile } from "../../types/file";

/**
 * A parsed version of a potential natural language date time string.
 *
 * The components which were parsed will be set. The type doesn't enforce this,
 * but at least one component will be present.
 *
 * e.g. "December 2022" will be parsed into a (year 2022, month 12, day
 * undefined), while "22 December 2022" will be parsed into (year 2022, month
 * 12, day 22).
 */
export interface SearchDateComponents {
    /** The year, if the search string specified one. */
    year: number | undefined;
    /** The month, if the search string specified one. */
    month: number | undefined;
    /** The day of the month, if the search string specified one. */
    day: number | undefined;
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
