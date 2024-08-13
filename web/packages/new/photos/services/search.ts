import type { EnteFile } from "@/new/photos/types/file";

/**
 * A massaged version of {@link Person} suitable for being shown in search
 * results.
 */
export interface SearchPerson {
    id: number;
    name?: string;
    files: number[];
    displayFaceID: string;
    displayFaceFile: EnteFile;
}
