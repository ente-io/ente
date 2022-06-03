import { Collection, CollectionSummary } from 'types/collection';
import { EnteFile } from 'types/file';
import { Search } from 'types/search';

export type SelectedState = {
    [k: number]: boolean;
    count: number;
    collectionID: number;
};
export type SetFiles = React.Dispatch<React.SetStateAction<EnteFile[]>>;
export type SetCollections = React.Dispatch<React.SetStateAction<Collection[]>>;
export type SetLoading = React.Dispatch<React.SetStateAction<Boolean>>;
export type SetSearchResultInfo = React.Dispatch<
    React.SetStateAction<CollectionSummary>
>;
export type SetSearch = React.Dispatch<React.SetStateAction<Search>>;

export type GalleryContextType = {
    thumbs: Map<number, string>;
    files: Map<number, string>;
    showPlanSelectorModal: () => void;
    setActiveCollection: (collection: number) => void;
    syncWithRemote: (force?: boolean, silent?: boolean) => Promise<void>;
    setNotificationAttributes: (attributes: NotificationAttributes) => void;
    setBlockingLoad: (value: boolean) => void;
    sidebarView: boolean;
    closeSidebar: () => void;
};

export interface NotificationAttributes {
    message: string;
    title: string;
}
