import { type EnteFile } from "ente-media/file";
import { fileCreationTime } from "ente-media/file-metadata";
import { useCallback, useState } from "react";
import type { JourneyPoint } from "../types";

interface UseFileViewerProps {
    files: EnteFile[];
    onSetOpenFileViewer?: (open: boolean) => void;
}

export const useFileViewer = ({
    files,
    onSetOpenFileViewer,
}: UseFileViewerProps) => {
    const [openFileViewer, setOpenFileViewer] = useState(false);
    const [currentFileIndex, setCurrentFileIndex] = useState(0);
    const [viewerFiles, setViewerFiles] = useState<EnteFile[]>([]);

    const handleOpenFileViewer = useCallback(
        (cluster: JourneyPoint[], clickedFileId: number) => {
            // Get file IDs from the cluster
            const clusterFileIds = cluster.map((point) => point.fileId);

            // Filter files to only include those from the cluster
            const clusterFiles = files.filter((file) =>
                clusterFileIds.includes(file.id),
            );

            // Sort cluster files by creation time
            const sortedClusterFiles = [...clusterFiles].sort(
                (a, b) => fileCreationTime(a) - fileCreationTime(b),
            );

            // Find the index of the clicked photo in the cluster files
            const clickedIndex = sortedClusterFiles.findIndex(
                (f) => f.id === clickedFileId,
            );

            if (clickedIndex !== -1 && sortedClusterFiles.length > 0) {
                // Batch state updates to avoid multiple re-renders
                setViewerFiles(sortedClusterFiles);
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

    return {
        // State
        openFileViewer,
        currentFileIndex,
        viewerFiles,
        // Handlers
        handleOpenFileViewer,
        handleCloseFileViewer,
    };
};
