export type Bbox = [number, number, number, number];

export interface LocationSearchResponse {
    place: string;
    bbox: Bbox;
}
export const getMapboxToken = () => process.env.NEXT_PUBLIC_MAPBOX_TOKEN;

export enum SuggestionType {
    DATE,
    LOCATION,
    COLLECTION,
    IMAGE,
    VIDEO,
}

export interface DateValue {
    date?: number;
    month?: number;
    year?: number;
}

export interface Suggestion {
    type: SuggestionType;
    label: string;
    value: Bbox | DateValue | number;
}
