import ArrowBackIosIcon from "@mui/icons-material/ArrowBackIos";
import ArrowForwardIosIcon from "@mui/icons-material/ArrowForwardIos";
import CloseIcon from "@mui/icons-material/Close";
import FullscreenIcon from "@mui/icons-material/Fullscreen";
import FullscreenExitIcon from "@mui/icons-material/FullscreenExit";
import { Dialog, IconButton, styled } from "@mui/material";
import type { EnteFile } from "ente-media/file";
import { FileType } from "ente-media/file-type";
import React, { useCallback, useEffect, useMemo, useState } from "react";

export interface EmbedFileViewerProps {
    open: boolean;
    onClose: () => void;
    initialIndex: number;
    files: EnteFile[];
}

export const EmbedFileViewer: React.FC<EmbedFileViewerProps> = ({
    open,
    onClose,
    initialIndex,
    files,
}) => {
    const [currentIndex, setCurrentIndex] = useState(initialIndex);
    const [isFullscreen, setIsFullscreen] = useState(false);

    const currentFile = useMemo(
        () => files[currentIndex],
        [files, currentIndex],
    );

    // Update currentIndex when initialIndex changes (and dialog is open)
    useEffect(() => {
        if (open) {
            setCurrentIndex(initialIndex);
        }
    }, [open, initialIndex]);

    const navigateToNext = useCallback(() => {
        if (currentIndex < files.length - 1) {
            setCurrentIndex(currentIndex + 1);
        }
    }, [currentIndex, files.length]);

    const navigateToPrevious = useCallback(() => {
        if (currentIndex > 0) {
            setCurrentIndex(currentIndex - 1);
        }
    }, [currentIndex]);

    const toggleFullscreen = useCallback(() => {
        setIsFullscreen(!isFullscreen);
    }, [isFullscreen]);

    const handleKeyDown = useCallback(
        (event: KeyboardEvent) => {
            if (!open) return;

            switch (event.key) {
                case "ArrowRight":
                    navigateToNext();
                    break;
                case "ArrowLeft":
                    navigateToPrevious();
                    break;
                case "Escape":
                    if (isFullscreen) {
                        setIsFullscreen(false);
                    } else {
                        onClose();
                    }
                    break;
                case "f":
                case "F":
                    toggleFullscreen();
                    break;
            }
        },
        [
            open,
            navigateToNext,
            navigateToPrevious,
            onClose,
            isFullscreen,
            toggleFullscreen,
        ],
    );

    useEffect(() => {
        document.addEventListener("keydown", handleKeyDown);
        return () => document.removeEventListener("keydown", handleKeyDown);
    }, [handleKeyDown]);

    if (!currentFile) {
        return null;
    }

    return (
        <EmbedViewerDialog
            open={open}
            onClose={onClose}
            fullScreen
            isFullscreen={isFullscreen}
        >
            {!isFullscreen && (
                <Controls>
                    <TopControls>
                        <IconButton onClick={onClose} color="inherit">
                            <CloseIcon />
                        </IconButton>
                    </TopControls>
                    <BottomControls>
                        <IconButton
                            onClick={navigateToPrevious}
                            disabled={currentIndex === 0}
                            color="inherit"
                        >
                            <ArrowBackIosIcon />
                        </IconButton>
                        <IconButton onClick={toggleFullscreen} color="inherit">
                            <FullscreenIcon />
                        </IconButton>
                        <IconButton
                            onClick={navigateToNext}
                            disabled={currentIndex === files.length - 1}
                            color="inherit"
                        >
                            <ArrowForwardIosIcon />
                        </IconButton>
                    </BottomControls>
                </Controls>
            )}

            {isFullscreen && (
                <FullscreenControls>
                    <IconButton onClick={toggleFullscreen} color="inherit">
                        <FullscreenExitIcon />
                    </IconButton>
                </FullscreenControls>
            )}

            <MediaContainer>
                <EmbedMediaRenderer
                    file={currentFile}
                    isFullscreen={isFullscreen}
                />
            </MediaContainer>
        </EmbedViewerDialog>
    );
};

interface EmbedMediaRendererProps {
    file: EnteFile;
    isFullscreen: boolean;
}

const EmbedMediaRenderer: React.FC<EmbedMediaRendererProps> = ({
    file,
    isFullscreen,
}) => {
    const [mediaSrc, setMediaSrc] = useState<string>();
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        const loadMedia = async () => {
            try {
                setIsLoading(true);
                // For embed, we'll use thumbnail for now - in a production version,
                // you might want to load the full resolution file
                const { downloadManager } = await import(
                    "ente-gallery/services/download"
                );
                const thumbnailData = await downloadManager.thumbnailData(file);
                if (!thumbnailData) throw new Error("No thumbnail data");
                const media = new Blob([thumbnailData]);
                const url = URL.createObjectURL(media);
                setMediaSrc(url);
            } catch (error) {
                console.error("Failed to load media:", error);
            } finally {
                setIsLoading(false);
            }
        };

        void loadMedia();

        return () => {
            if (mediaSrc) {
                URL.revokeObjectURL(mediaSrc);
            }
        };
    }, [file, mediaSrc]);

    if (isLoading) {
        return <MediaPlaceholder>Loading...</MediaPlaceholder>;
    }

    if (!mediaSrc) {
        return <MediaPlaceholder>Failed to load media</MediaPlaceholder>;
    }

    const isVideo = file.metadata.fileType === FileType.video;

    return isVideo ? (
        <MediaVideo src={mediaSrc} controls isFullscreen={isFullscreen} />
    ) : (
        <MediaImage src={mediaSrc} alt="" isFullscreen={isFullscreen} />
    );
};

const EmbedViewerDialog = styled(Dialog)<{ isFullscreen: boolean }>(
    ({ theme, isFullscreen }) => ({
        "& .MuiDialog-paper": {
            backgroundColor: theme.palette.background.default,
            backgroundImage: "none",
            margin: 0,
            maxWidth: "none",
            maxHeight: "none",
            width: "100%",
            height: "100%",
            borderRadius: 0,
        },
        "& .MuiBackdrop-root": {
            backgroundColor: isFullscreen
                ? "rgba(0, 0, 0, 1)"
                : "rgba(0, 0, 0, 0.8)",
        },
    }),
);

const Controls = styled("div")({
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    pointerEvents: "none",
    zIndex: 1,
});

const TopControls = styled("div")({
    position: "absolute",
    top: 0,
    right: 0,
    padding: "16px",
    pointerEvents: "auto",
    "& button": {
        backgroundColor: "rgba(0, 0, 0, 0.5)",
        color: "white",
        "&:hover": { backgroundColor: "rgba(0, 0, 0, 0.7)" },
    },
});

const BottomControls = styled("div")({
    position: "absolute",
    bottom: 0,
    left: "50%",
    transform: "translateX(-50%)",
    padding: "16px",
    display: "flex",
    gap: "8px",
    pointerEvents: "auto",
    "& button": {
        backgroundColor: "rgba(0, 0, 0, 0.5)",
        color: "white",
        "&:hover": { backgroundColor: "rgba(0, 0, 0, 0.7)" },
        "&:disabled": {
            backgroundColor: "rgba(0, 0, 0, 0.3)",
            color: "rgba(255, 255, 255, 0.5)",
        },
    },
});

const FullscreenControls = styled("div")({
    position: "absolute",
    top: "16px",
    right: "16px",
    zIndex: 2,
    pointerEvents: "auto",
    "& button": {
        backgroundColor: "rgba(0, 0, 0, 0.5)",
        color: "white",
        "&:hover": { backgroundColor: "rgba(0, 0, 0, 0.7)" },
    },
});

const MediaContainer = styled("div")({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    width: "100%",
    height: "100%",
});

const MediaPlaceholder = styled("div")({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    color: "white",
    fontSize: "1.2rem",
});

const MediaImage = styled("img")<{ isFullscreen: boolean }>(
    ({ isFullscreen }) => ({
        maxWidth: "100%",
        maxHeight: "100%",
        objectFit: "contain",
        ...(isFullscreen && { width: "100vw", height: "100vh" }),
    }),
);

const MediaVideo = styled("video")<{ isFullscreen: boolean }>(
    ({ isFullscreen }) => ({
        maxWidth: "100%",
        maxHeight: "100%",
        ...(isFullscreen && { width: "100vw", height: "100vh" }),
    }),
);
