/**
 * @file types shared between the main thread interface to search (`index.ts`)
 * and the search worker (`worker.ts`)
 */

import type { EnteFile } from "../../types/file";

export interface DateValue {
    date?: number;
    month?: number;
    year?: number;
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
