import { Person, Thing, WordGroup } from 'types/machineLearning';
import { IndexStatus } from 'types/machineLearning/ui';
import { EnteFile } from 'types/file';
import { LocationTagData } from 'types/entity';
import { FILE_TYPE } from 'constants/file';

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
    FILE_TYPE = 'FILE_TYPE',
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
        | IndexStatus
        | Thing
        | WordGroup
        | LocationTagData
        | FILE_TYPE;
    hide?: boolean;
}

export type Search = {
    date?: DateValue;
    location?: LocationTagData;
    collection?: number;
    files?: number[];
    person?: Person;
    thing?: Thing;
    text?: WordGroup;
    fileType?: FILE_TYPE;
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
