import { useCallback } from 'react';
import type { EnteFile } from 'ente-media/file';
import type { ItemVisibility } from 'ente-media/file-metadata';
import type { Collection } from 'ente-media/collection';
import { 
    addToFavoritesCollection, 
    removeFromFavoritesCollection,
    removeFromCollection 
} from 'ente-new/photos/services/collection';
import { updateFilesVisibility } from 'ente-new/photos/services/file';
import { getSelectedFiles, type SelectedState } from 'utils/file';
import type { FileOp } from 'ente-new/photos/components/SelectedFileOptions';
import { usePhotosAppContext } from 'ente-new/photos/types/context';
import { useBaseContext } from 'ente-base/context';
import { notifyOthersFilesDialogAttributes } from 'ente-new/photos/components/utils/dialog-attributes';

interface UseFileOperationsProps {
    user: { id: number };
    filteredFiles: EnteFile[];
    selected: SelectedState;
    clearSelection: () => void;
    onRemotePull: () => Promise<void>;
    dispatch: (action: { type: string; [key: string]: unknown }) => void;
    favoriteFileIDs: Set<number>;
}

/**
 * Custom hook for handling file operations
 */
export const useFileOperations = ({
    user,
    filteredFiles,
    selected,
    clearSelection,
    onRemotePull,
    dispatch,
    favoriteFileIDs,
}: UseFileOperationsProps) => {
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();
    const { onGenericError, showMiniDialog } = useBaseContext();

    /**
     * Toggle favorite status of a file
     */
    const handleToggleFavorite = useCallback(
        async (file: EnteFile) => {
            const fileID = file.id;
            const isFavorite = favoriteFileIDs.has(fileID);

            dispatch({ type: "addPendingFavoriteUpdate", fileID });
            try {
                const action = isFavorite
                    ? removeFromFavoritesCollection
                    : addToFavoritesCollection;
                await action([file]);
                dispatch({
                    type: "unsyncedFavoriteUpdate",
                    fileID,
                    isFavorite: !isFavorite,
                });
            } finally {
                dispatch({ type: "removePendingFavoriteUpdate", fileID });
            }
        },
        [favoriteFileIDs, dispatch],
    );

    /**
     * Update file visibility
     */
    const handleFileVisibilityUpdate = useCallback(
        async (file: EnteFile, visibility: ItemVisibility) => {
            const fileID = file.id;
            dispatch({ type: "addPendingVisibilityUpdate", fileID });
            try {
                await updateFilesVisibility([file], visibility);
                dispatch({
                    type: "unsyncedPrivateMagicMetadataUpdate",
                    fileID,
                    privateMagicMetadata: {
                        ...file.magicMetadata,
                        count: file.magicMetadata?.count ?? 0,
                        version: (file.magicMetadata?.version ?? 0) + 1,
                        data: { ...file.magicMetadata?.data, visibility },
                    },
                });
            } finally {
                dispatch({ type: "removePendingVisibilityUpdate", fileID });
            }
        },
        [dispatch],
    );

    /**
     * Remove files from a collection
     */
    const handleRemoveFilesFromCollection = useCallback(
        async (collection: Collection) => {
            showLoadingBar();
            let notifyOthersFiles = false;
            try {
                const selectedFiles = getSelectedFiles(selected, filteredFiles);
                const processedCount = await removeFromCollection(
                    collection,
                    selectedFiles,
                );
                notifyOthersFiles = processedCount !== selectedFiles.length;
                clearSelection();
                await onRemotePull();
            } catch (e) {
                onGenericError(e);
            } finally {
                hideLoadingBar();
            }

            if (notifyOthersFiles) {
                showMiniDialog(notifyOthersFilesDialogAttributes());
            }
        },
        [
            showLoadingBar,
            hideLoadingBar,
            selected,
            filteredFiles,
            clearSelection,
            onRemotePull,
            onGenericError,
            showMiniDialog,
        ],
    );

    /**
     * Create a file operation handler
     */
    const createFileOpHandler = useCallback(
        (op: FileOp) => () => {
            void (async () => {
                showLoadingBar();
                try {
                    const selectedFiles = getSelectedFiles(selected, filteredFiles);
                    const toProcessFiles = selectedFiles.filter(
                        (file) => file.ownerID === user.id,
                    );

                    if (toProcessFiles.length > 0) {
                        // TODO: Implement proper file operations with correct typing
                        // await performFileOp(op, toProcessFiles, ...callbacks);
                        console.log('File operation:', op, toProcessFiles.length, 'files');
                    }

                    if (toProcessFiles.length !== selectedFiles.length) {
                        showMiniDialog(notifyOthersFilesDialogAttributes());
                    }
                    clearSelection();
                    await onRemotePull();
                } catch (e) {
                    onGenericError(e);
                } finally {
                    hideLoadingBar();
                }
            })();
        },
        [
            showLoadingBar,
            hideLoadingBar,
            selected,
            filteredFiles,
            user,
            dispatch,
            showMiniDialog,
            clearSelection,
            onRemotePull,
            onGenericError,
        ],
    );

    return {
        handleToggleFavorite,
        handleFileVisibilityUpdate,
        handleRemoveFilesFromCollection,
        createFileOpHandler,
    };
};
