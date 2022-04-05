import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { DateValue, Bbox } from 'types/search';

export type SelectedState = {
    [k: number]: boolean;
    count: number;
    collectionID: number;
};
export type SetFiles = React.Dispatch<React.SetStateAction<EnteFile[]>>;
export type SetCollections = React.Dispatch<React.SetStateAction<Collection[]>>;
export type SetLoading = React.Dispatch<React.SetStateAction<Boolean>>;
export type setSearchStats = React.Dispatch<React.SetStateAction<SearchStats>>;

export type Search = {
    date?: DateValue;
    location?: Bbox;
    fileIndex?: number;
};
export interface SearchStats {
    resultCount: number;
    timeTaken: number;
}

export type GalleryContextType = {
    thumbs: Map<number, string>;
    files: Map<number, string>;
    showPlanSelectorModal: () => void;
    setActiveCollection: (collection: number) => void;
    syncWithRemote: (force?: boolean, silent?: boolean) => Promise<void>;

    setNotificationAttributes: (attributes: NotificationAttributes) => void;
    setBlockingLoad: (value: boolean) => void;
    clubSameTimeFilesOnly: boolean;
    setClubSameTimeFilesOnly: (clubSameTimeFilesOnly: boolean) => void;
    fileSizeMap: Map<number, number>;
    isDeduplicating: boolean;
    setIsDeduplicating: (value: boolean) => void;
};

export interface NotificationAttributes {
    message: string;
    title: string;
}
