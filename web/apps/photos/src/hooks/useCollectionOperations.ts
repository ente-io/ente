import { useCallback, useState } from 'react';
import type { Collection } from 'ente-media/collection';
import type { EnteFile } from 'ente-media/file';
import type { SelectedState } from 'utils/file';
import type { CollectionOp } from 'ente-new/photos/components/SelectedFileOptions';
import type { CollectionSelectorAttributes } from 'ente-new/photos/components/CollectionSelector';
import { createAlbum } from 'ente-new/photos/services/collection';
import { performCollectionOp } from 'ente-new/photos/components/gallery/helpers';
import { getSelectedFiles } from 'utils/file';
import { usePhotosAppContext } from 'ente-new/photos/types/context';
import { useBaseContext } from 'ente-base/context';
import { notifyOthersFilesDialogAttributes } from 'ente-new/photos/components/utils/dialog-attributes';

interface UseCollectionOperationsProps {
    user: { id: number } | null;
    filteredFiles: EnteFile[];
    selected: SelectedState;
    clearSelection: () => void;
    onRemotePull: () => Promise<void>;
}

/**
 * Custom hook for managing collection operations
 */
export const useCollectionOperations = ({
    user,
    filteredFiles,
    selected,
    clearSelection,
    onRemotePull,
}: UseCollectionOperationsProps) => {
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();
    const { onGenericError, showMiniDialog } = useBaseContext();

    // Collection selector state
    const [openCollectionSelector, setOpenCollectionSelector] = useState(false);
    const [collectionSelectorAttributes, setCollectionSelectorAttributes] = 
        useState<CollectionSelectorAttributes | undefined>();

    // Album creation state
    const [postCreateAlbumOp, setPostCreateAlbumOp] = useState<CollectionOp | undefined>();

    /**
     * Create a handler for collection operations (add, move)
     */
    const createOnSelectForCollectionOp = useCallback(
        (op: CollectionOp) => (selectedCollection: Collection) => {
            void (async () => {
                showLoadingBar();
                try {
                    setOpenCollectionSelector(false);
                    const selectedFiles = getSelectedFiles(selected, filteredFiles);
                    const userFiles = selectedFiles.filter(
                        (f) => f.ownerID === user!.id,
                    );
                    const sourceCollectionID = selected.collectionID;
                    
                    if (userFiles.length > 0) {
                        await performCollectionOp(
                            op,
                            selectedCollection,
                            userFiles,
                            sourceCollectionID,
                        );
                    }
                    
                    // Notify if some files couldn't be processed
                    if (userFiles.length !== selectedFiles.length) {
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
            showMiniDialog,
            clearSelection,
            onRemotePull,
            onGenericError,
        ],
    );

    /**
     * Create a handler for collection operations that need album creation
     */
    const createOnCreateForCollectionOp = useCallback(
        (op: CollectionOp) => {
            setPostCreateAlbumOp(op);
            return () => {
                // This will be handled by the album name input dialog
                // The actual creation happens in handleAlbumNameSubmit
            };
        },
        [],
    );

    /**
     * Handle album name submission after creation
     */
    const handleAlbumNameSubmit = useCallback(
        async (name: string) => {
            if (!postCreateAlbumOp) return;

            try {
                const collection = await createAlbum(name);
                // Execute the deferred operation
                createOnSelectForCollectionOp(postCreateAlbumOp)(collection);
                setPostCreateAlbumOp(undefined);
            } catch (e) {
                onGenericError(e);
                setPostCreateAlbumOp(undefined);
            }
        },
        [postCreateAlbumOp, createOnSelectForCollectionOp, onGenericError],
    );

    /**
     * Open collection selector with specific attributes
     */
    const handleOpenCollectionSelector = useCallback(
        (attributes: CollectionSelectorAttributes) => {
            setCollectionSelectorAttributes(attributes);
            setOpenCollectionSelector(true);
        },
        [],
    );

    /**
     * Close collection selector
     */
    const handleCloseCollectionSelector = useCallback(
        () => {
            setOpenCollectionSelector(false);
            setCollectionSelectorAttributes(undefined);
        },
        [],
    );

    return {
        // State
        openCollectionSelector,
        collectionSelectorAttributes,
        postCreateAlbumOp,
        
        // Handlers
        createOnSelectForCollectionOp,
        createOnCreateForCollectionOp,
        handleAlbumNameSubmit,
        handleOpenCollectionSelector,
        handleCloseCollectionSelector,
        
        // Setters for external control
        setOpenCollectionSelector,
        setCollectionSelectorAttributes,
    };
};
