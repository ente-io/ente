import { Person, Thing, WordGroup } from 'types/machineLearning';
import { IndexStatus } from 'types/machineLearning/ui';
import { EnteFile } from 'types/file';

export type Bbox = [number, number, number, number];

export interface LocationSearchResponse {
    place: string;
    bbox: Bbox;
}

export enum SuggestionType {
    DATE = 'DATE',
    LOCATION = 'LOCATION',
    COLLECTION = 'COLLECTION',
    FILE_NAME = 'FILE_NAME',
    PERSON = 'PERSON',
    INDEX_STATUS = 'INDEX_STATUS',
    THING = 'THING',
    TEXT = 'TEXT',
    FILE_CAPTION = 'FILE_CAPTION',
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
        | Bbox
        | DateValue
        | number[]
        | Person
        | IndexStatus
        | Thing
        | WordGroup;
    hide?: boolean;
}

export type Search = {
    date?: DateValue;
    location?: Bbox;
    collection?: number;
    files?: number[];
    person?: Person;
    thing?: Thing;
    text?: WordGroup;
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
    summary: SearchResultSummary
) => void;
