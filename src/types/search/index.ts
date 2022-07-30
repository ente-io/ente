import { Person, Thing, ThingClass, WordGroup } from 'types/machineLearning';
import { IndexStatus } from 'types/machineLearning/ui';
import { EnteFile } from 'types/file';

export type Bbox = [number, number, number, number];

export interface LocationSearchResponse {
    place: string;
    bbox: Bbox;
}

export enum SuggestionType {
    DATE,
    LOCATION,
    COLLECTION,
    IMAGE,
    VIDEO,
    PERSON,
    INDEX_STATUS,
    THING,
    TEXT,
}

export interface DateValue {
    date?: number;
    month?: number;
    year?: number;
}

export interface Suggestion {
    type: SuggestionType;
    label: string;
    value: Bbox | DateValue | number | Person | IndexStatus | Thing;
    hide?: boolean;
}

export type Search = {
    date?: DateValue;
    location?: Bbox;
    collection?: number;
    file?: number;
    person?: Person;
    thing?: ThingClass;
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
