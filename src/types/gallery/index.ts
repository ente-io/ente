import { CollectionSelectorAttributes } from 'components/Collections/CollectionSelector';
import { TimeStampListItem } from 'components/PhotoList';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { Person, ThingClass, WordGroup } from 'types/machineLearning';
import { DateValue, Bbox } from 'types/search';

export type SelectedState = {
    [k: number]: boolean;
    count: number;
    collectionID: number;
};
export type SetFiles = React.Dispatch<React.SetStateAction<EnteFile[]>>;
export type SetCollections = React.Dispatch<React.SetStateAction<Collection[]>>;
export type setSearchStats = React.Dispatch<React.SetStateAction<SearchStats>>;

export type Search = {
    date?: DateValue;
    location?: Bbox;
    fileIndex?: number;
    person?: Person;
    thing?: ThingClass;
    text?: WordGroup;
};
export interface SearchStats {
    resultCount: number;
    timeTaken: number;
}
export type SetLoading = React.Dispatch<React.SetStateAction<boolean>>;
export type SetCollectionSelectorAttributes = React.Dispatch<
    React.SetStateAction<CollectionSelectorAttributes>
>;

export type GalleryContextType = {
    thumbs: Map<number, string>;
    files: Map<number, { original: string; converted: string }>;
    showPlanSelectorModal: () => void;
    setActiveCollection: (collection: number) => void;
    syncWithRemote: (force?: boolean, silent?: boolean) => Promise<void>;
    setBlockingLoad: (value: boolean) => void;
    photoListHeader: TimeStampListItem;
};
