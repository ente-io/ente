import type { Collection } from "@/media/collection";
import { EnteFile } from "@/media/file";
import { type SelectionContext } from "@/new/photos/components/gallery";
import type { User } from "@ente/shared/user/types";
import { FilesDownloadProgressAttributes } from "components/FilesDownloadProgress";
import { TimeStampListItem } from "components/PhotoList";

export type SelectedState = {
    [k: number]: boolean;
    ownCount: number;
    count: number;
    collectionID: number;
    /**
     * The context in which the selection was made. Only set by newer code if
     * there is an active selection (older code continues to rely on the
     * {@link collectionID} logic).
     */
    context: SelectionContext | undefined;
};
export type SetSelectedState = React.Dispatch<
    React.SetStateAction<SelectedState>
>;
export type SetFiles = React.Dispatch<React.SetStateAction<EnteFile[]>>;
export type SetCollections = React.Dispatch<React.SetStateAction<Collection[]>>;
export type SetLoading = React.Dispatch<React.SetStateAction<boolean>>;
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
    /** Newer and almost equivalent alternative to setActiveCollectionID. */
    onShowCollection: (collectionID: number) => void;
    syncWithRemote: (force?: boolean, silent?: boolean) => Promise<void>;
    setBlockingLoad: (value: boolean) => void;
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
