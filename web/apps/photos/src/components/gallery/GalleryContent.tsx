import React from 'react';
import { GalleryEmptyState, PeopleEmptyState } from 'ente-new/photos/components/gallery';
import { uploadManager } from 'services/upload-manager';
import { PseudoCollectionID } from 'ente-new/photos/services/collection-summary';
import type { EnteFile } from 'ente-media/file';
import type { GalleryBarMode } from 'ente-new/photos/components/gallery/reducer';

interface GalleryContentProps {
    // Basic state
    filteredFiles: EnteFile[];
    isInSearchMode: boolean;
    isFirstLoad: boolean;
    barMode: GalleryBarMode;
    activeCollectionID: number | undefined;
    activePerson: unknown;
    
    // Event handlers
    onUpload: () => void;
    
    // Children for flexible content
    children?: React.ReactNode;
}

/**
 * Simplified main content area that handles empty states and delegates to children
 */
export const GalleryContent: React.FC<GalleryContentProps> = ({
    filteredFiles,
    isInSearchMode,
    isFirstLoad,
    barMode,
    activeCollectionID,
    activePerson,
    onUpload,
    children,
}) => {
    // Show empty states for specific conditions
    const showGalleryEmptyState = 
        !isInSearchMode &&
        !isFirstLoad &&
        !filteredFiles.length &&
        activeCollectionID === PseudoCollectionID.all;
        
    const showPeopleEmptyState = 
        !isInSearchMode &&
        !isFirstLoad &&
        barMode === "people" &&
        !activePerson;

    if (showGalleryEmptyState) {
        return (
            <GalleryEmptyState
                isUploadInProgress={uploadManager.isUploadInProgress()}
                onUpload={onUpload}
            />
        );
    }

    if (showPeopleEmptyState) {
        return <PeopleEmptyState />;
    }

    // Render children (FileListWithViewer, GalleryBarAndListHeader, etc.)
    return <>{children}</>;
};
