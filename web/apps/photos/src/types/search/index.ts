import { FILE_TYPE } from "@/media/file-type";
import { EnteFile } from "@/new/photos/types/file";
import type { FaceIndexingStatus } from "services/face/indexer";
import type { Person } from "services/face/people";
import { City } from "services/locationSearchService";
import { LocationTagData } from "types/entity";

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

export interface DateValue {
    date?: number;
    month?: number;
    year?: number;
}

export interface Suggestion {
    type: SuggestionType;
    label: string;
    value:
        | DateValue
        | number[]
        | Person
        | FaceIndexingStatus
        | LocationTagData
        | City
        | FILE_TYPE
        | ClipSearchScores;
    hide?: boolean;
}

export type Search = {
    date?: DateValue;
    location?: LocationTagData;
    city?: City;
    collection?: number;
    files?: number[];
    person?: Person;
    fileType?: FILE_TYPE;
    clip?: ClipSearchScores;
};

export type SearchResultSummary = {
    optionName: string;
    fileCount: number;
};

export interface SearchOption extends Suggestion {
    fileCount: number;
    previewFiles: EnteFile[];
}

export type UpdateSearch = (
    search: Search,
    summary: SearchResultSummary,
) => void;

export type ClipSearchScores = Map<number, number>;
