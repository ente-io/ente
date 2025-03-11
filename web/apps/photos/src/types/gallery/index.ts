import { type SelectionContext } from "@/new/photos/components/gallery";
import type { User } from "@ente/shared/user/types";
import { TimeStampListItem } from "components/FileList";
import { FilesDownloadProgressAttributes } from "components/FilesDownloadProgress";

export interface SelectedState {
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
}
export type SetSelectedState = React.Dispatch<
    React.SetStateAction<SelectedState>
>;
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

export interface MergedSourceURL {
    original: string;
    converted: string;
}

export interface GalleryContextType {
    setActiveCollectionID: (collectionID: number) => void;
    syncWithRemote: (force?: boolean, silent?: boolean) => Promise<void>;
    setBlockingLoad: (value: boolean) => void;
    photoListHeader: TimeStampListItem;
    user: User;
    userIDToEmailMap: Map<number, string>;
    emailList: string[];
    openHiddenSection: (callback?: () => void) => void;
    isClipSearchResult: boolean;
    setSelectedFiles: (value) => void;
    selectedFile: SelectedState;
}
