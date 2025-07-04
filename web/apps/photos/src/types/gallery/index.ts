import { type FilesDownloadProgressAttributes } from "components/FilesDownloadProgress";
import { type SelectionContext } from "ente-new/photos/components/gallery";

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


export interface MergedSourceURL {
    original: string;
    converted: string;
}
