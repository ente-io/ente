import { Person, Thing } from 'types/machineLearning';
import { IndexStatus } from 'types/machineLearning/ui';

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
