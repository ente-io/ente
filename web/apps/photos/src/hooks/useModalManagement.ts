import { useCallback, useRef, useState } from 'react';
import type { EnteFile } from 'ente-media/file';
import { useModalVisibility } from 'ente-base/components/utils/modal';
import type { UploadTypeSelectorIntent } from 'ente-gallery/components/Upload';

/**
 * Custom hook for managing all modal states and visibility
 */
export const useModalManagement = () => {
    // File drag and drop state
    const [dragAndDropFiles, setDragAndDropFiles] = useState<File[]>([]);
    const [shouldDisableDropzone, setShouldDisableDropzone] = useState(false);

    // Upload modal state
    const [uploadTypeSelectorView, setUploadTypeSelectorView] = useState(false);
    const [uploadTypeSelectorIntent, setUploadTypeSelectorIntent] =
        useState<UploadTypeSelectorIntent>("upload");

    // File viewer state
    const [isFileViewerOpen, setIsFileViewerOpen] = useState(false);

    // Fix creation time dialog state
    const [fixCreationTimeFiles, setFixCreationTimeFiles] = useState<EnteFile[]>([]);

    // Authentication callback for hidden section access
    const onAuthenticateCallback = useRef<(() => void) | undefined>(undefined);

    // Modal visibility hooks
    const { show: showSidebar, props: sidebarVisibilityProps } = useModalVisibility();
    const { show: showPlanSelector, props: planSelectorVisibilityProps } = useModalVisibility();
    const { show: showWhatsNew, props: whatsNewVisibilityProps } = useModalVisibility();
    const { show: showFixCreationTime, props: fixCreationTimeVisibilityProps } = useModalVisibility();
    const { show: showExport, props: exportVisibilityProps } = useModalVisibility();
    const { show: showAuthenticateUser, props: authenticateUserVisibilityProps } = useModalVisibility();
    const { show: showAlbumNameInput, props: albumNameInputVisibilityProps } = useModalVisibility();

    /**
     * Authenticate user for hidden section access
     */
    const authenticateUser = useCallback(
        () =>
            new Promise<void>((resolve) => {
                onAuthenticateCallback.current = resolve;
                showAuthenticateUser();
            }),
        [showAuthenticateUser],
    );

    /**
     * Open upload type selector
     */
    const openUploader = useCallback((intent?: UploadTypeSelectorIntent) => {
        setUploadTypeSelectorView(true);
        setUploadTypeSelectorIntent(intent ?? "upload");
    }, []);

    /**
     * Close upload type selector
     */
    const closeUploadTypeSelector = useCallback(() => {
        setUploadTypeSelectorView(false);
    }, []);

    /**
     * Check if any modal is currently open
     */
    const isAnyModalOpen = 
        uploadTypeSelectorView ||
        sidebarVisibilityProps.open ||
        planSelectorVisibilityProps.open ||
        fixCreationTimeVisibilityProps.open ||
        exportVisibilityProps.open ||
        authenticateUserVisibilityProps.open ||
        albumNameInputVisibilityProps.open ||
        isFileViewerOpen;

    return {
        // State
        dragAndDropFiles,
        shouldDisableDropzone,
        uploadTypeSelectorView,
        uploadTypeSelectorIntent,
        isFileViewerOpen,
        fixCreationTimeFiles,
        isAnyModalOpen,

        // Setters
        setDragAndDropFiles,
        setShouldDisableDropzone,
        setUploadTypeSelectorView,
        setUploadTypeSelectorIntent,
        setIsFileViewerOpen,
        setFixCreationTimeFiles,

        // Modal visibility props
        sidebarVisibilityProps,
        planSelectorVisibilityProps,
        whatsNewVisibilityProps,
        fixCreationTimeVisibilityProps,
        exportVisibilityProps,
        authenticateUserVisibilityProps,
        albumNameInputVisibilityProps,

        // Modal show functions
        showSidebar,
        showPlanSelector,
        showWhatsNew,
        showFixCreationTime,
        showExport,
        showAuthenticateUser,
        showAlbumNameInput,

        // Actions
        authenticateUser,
        openUploader,
        closeUploadTypeSelector,

        // Authentication callback
        onAuthenticateCallback,
    };
};
