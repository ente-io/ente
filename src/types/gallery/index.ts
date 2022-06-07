import { ButtonProps } from '@mui/material';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { Search, SearchResultSummary } from 'types/search';

export type SelectedState = {
    [k: number]: boolean;
    count: number;
    collectionID: number;
};
export type SetFiles = React.Dispatch<React.SetStateAction<EnteFile[]>>;
export type SetCollections = React.Dispatch<React.SetStateAction<Collection[]>>;
export type SetLoading = React.Dispatch<React.SetStateAction<Boolean>>;
export type SetSearchResultSummary = React.Dispatch<
    React.SetStateAction<SearchResultSummary>
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
    variant: ButtonProps['color'];
    message: JSX.Element | string;
    action?: {
        text: string;
        callback: () => void;
    };
}
