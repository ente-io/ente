import { EnteFile } from "@/new/photos/types/file";
import type { User } from "@ente/shared/user/types";
import { CollectionSelectorAttributes } from "components/Collections/CollectionSelector";
import { FilesDownloadProgressAttributes } from "components/FilesDownloadProgress";
import { TimeStampListItem } from "components/PhotoList";
import { Collection } from "types/collection";

export type SelectedState = {
    [k: number]: boolean;
    ownCount: number;
    count: number;
    collectionID: number;
};
export type SetSelectedState = React.Dispatch<
    React.SetStateAction<SelectedState>
>;
export type SetFiles = React.Dispatch<React.SetStateAction<EnteFile[]>>;
export type SetCollections = React.Dispatch<React.SetStateAction<Collection[]>>;
export type SetLoading = React.Dispatch<React.SetStateAction<boolean>>;
export type SetCollectionSelectorAttributes = React.Dispatch<
    React.SetStateAction<CollectionSelectorAttributes>
>;
export type SetFilesDownloadProgressAttributes = (
    value:
        | Partial<FilesDownloadProgressAttributes>
        | ((
              prev: FilesDownloadProgressAttributes,
          ) => FilesDownloadProgressAttributes),
) => void;

export type SetFilesDownloadProgressAttributesCreator = (
    folderName: string,
    collectionID?: number,
    isHidden?: boolean,
) => SetFilesDownloadProgressAttributes;

export type MergedSourceURL = {
    original: string;
    converted: string;
};

export type GalleryContextType = {
    showPlanSelectorModal: () => void;
    setActiveCollectionID: (collectionID: number) => void;
    syncWithRemote: (force?: boolean, silent?: boolean) => Promise<void>;
    setBlockingLoad: (value: boolean) => void;
    setIsInSearchMode: (value: boolean) => void;
    photoListHeader: TimeStampListItem;
    openExportModal: () => void;
    authenticateUser: (callback: () => void) => void;
    user: User;
    userIDToEmailMap: Map<number, string>;
    emailList: string[];
    openHiddenSection: (callback?: () => void) => void;
    isClipSearchResult: boolean;
    setSelectedFiles: (value) => void;
    selectedFile: SelectedState;
};

export enum CollectionSelectorIntent {
    upload,
    add,
    move,
    restore,
    unhide,
}
