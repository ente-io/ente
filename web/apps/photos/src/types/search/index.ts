import { FileType } from "@/media/file-type";
import type { MLStatus } from "@/new/photos/services/ml";
import type {
    SearchDateComponents,
    SearchPerson,
} from "@/new/photos/services/search/types";
import { EnteFile } from "@/new/photos/types/file";
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

export type Search = {
    date?: SearchDateComponents;
    location?: LocationTagData;
    city?: City;
    collection?: number;
    files?: number[];
    person?: SearchPerson;
    fileType?: FileType;
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
