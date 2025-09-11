import { type EnteFile } from "ente-media/file";
import { useCallback, useState } from "react";
import type { JourneyPoint } from "../types";

interface UseFileViewerProps {
    files: EnteFile[];
    onSetOpenFileViewer?: (open: boolean) => void;
    onRemotePull?: () => Promise<void>;
}

export const useFileViewer = ({
    files,
    onSetOpenFileViewer,
    onRemotePull,
}: UseFileViewerProps) => {
    const [openFileViewer, setOpenFileViewer] = useState(false);
    const [currentFileIndex, setCurrentFileIndex] = useState(0);
    const [viewerFiles, setViewerFiles] = useState<EnteFile[]>([]);

    const handleOpenFileViewer = useCallback(
        (_cluster: JourneyPoint[], clickedFileId: number) => {
            // Sort all files by creation time
            const sortedFiles = [...files].sort(
                (a, b) =>
                    new Date(a.metadata.creationTime / 1000).getTime() -
                    new Date(b.metadata.creationTime / 1000).getTime(),
            );

            // Find the index of the clicked photo in all files
            const clickedIndex = sortedFiles.findIndex(
                (f) => f.id === clickedFileId,
            );

            if (clickedIndex !== -1 && sortedFiles.length > 0) {
                // Batch state updates to avoid multiple re-renders
                setViewerFiles(sortedFiles);
                setCurrentFileIndex(clickedIndex);
                setOpenFileViewer(true);
                onSetOpenFileViewer?.(true);
            }
        },
        [files, onSetOpenFileViewer],
    );

    const handleCloseFileViewer = useCallback(() => {
        // Batch state updates
        setOpenFileViewer(false);
        onSetOpenFileViewer?.(false);
    }, [onSetOpenFileViewer]);

    const handleTriggerRemotePull = useCallback(() => {
        return onRemotePull?.() || Promise.resolve();
    }, [onRemotePull]);

    return {
        // State
        openFileViewer,
        currentFileIndex,
        viewerFiles,
        // Handlers
        handleOpenFileViewer,
        handleCloseFileViewer,
        handleTriggerRemotePull,
    };
};
