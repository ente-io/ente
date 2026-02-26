import PlayCircleOutlineOutlinedIcon from "@mui/icons-material/PlayCircleOutlineOutlined";
import { Box, styled } from "@mui/material";
import { downloadManager } from "ente-gallery/services/download";
import type { EnteFile } from "ente-media/file";
import { fileDurationString } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import {
    LoadingThumbnail,
    StaticThumbnail,
} from "ente-new/photos/components/PlaceholderThumbnails";
import { TileBottomTextOverlay } from "ente-new/photos/components/Tiles";
import React, { memo, useCallback, useMemo, useState } from "react";

export interface EmbedFileListAnnotatedFile {
    file: EnteFile;
    timelineDateString: string;
}

export interface EmbedFileListProps {
    width: number;
    height: number;
    annotatedFiles: EmbedFileListAnnotatedFile[];
    onItemClick: (index: number) => void;
    header?: React.ReactNode;
    footer?: React.ReactNode;
}

const THUMBNAIL_SIZE = 200;
const THUMBNAIL_GAP = 4;
const CONTAINER_PADDING = 4;

export const EmbedFileList: React.FC<EmbedFileListProps> = memo(
    ({ width, height, annotatedFiles, onItemClick, header, footer }) => {
        const availableWidth = width - 2 * CONTAINER_PADDING;
        const columns = Math.max(
            1,
            Math.floor(availableWidth / (THUMBNAIL_SIZE + THUMBNAIL_GAP)),
        );
        const actualThumbnailSize =
            (availableWidth - (columns - 1) * THUMBNAIL_GAP) / columns;

        return (
            <Container style={{ width, height }}>
                {header}
                <Grid columns={columns} gap={THUMBNAIL_GAP}>
                    {annotatedFiles.map((annotatedFile, index) => (
                        <EmbedFileTile
                            key={`${annotatedFile.file.id}-${index}`}
                            file={annotatedFile.file}
                            size={actualThumbnailSize}
                            onClick={() => onItemClick(index)}
                        />
                    ))}
                </Grid>
                {footer}
            </Container>
        );
    },
);

EmbedFileList.displayName = "EmbedFileList";

interface EmbedFileTileProps {
    file: EnteFile;
    size: number;
    onClick: () => void;
}

const EmbedFileTile: React.FC<EmbedFileTileProps> = memo(
    ({ file, size, onClick }) => {
        const [thumbnailSrc, setThumbnailSrc] = useState<string>();
        const [isLoading, setIsLoading] = useState(true);

        const isVideoFile = useMemo(
            () => file.metadata.fileType === FileType.video,
            [file.metadata.fileType],
        );

        const loadThumbnail = useCallback(async () => {
            try {
                setIsLoading(true);
                const thumbnailData = await downloadManager.thumbnailData(file);
                if (thumbnailData) {
                    const blob = new Blob([thumbnailData]);
                    const url = URL.createObjectURL(blob);
                    setThumbnailSrc(url);
                }
            } catch (error) {
                console.error("Failed to load thumbnail:", error);
            } finally {
                setIsLoading(false);
            }
        }, [file]);

        React.useEffect(() => {
            void loadThumbnail();
        }, [loadThumbnail]);

        // Separate cleanup effect that only runs on unmount
        React.useEffect(() => {
            return () => {
                if (thumbnailSrc) {
                    URL.revokeObjectURL(thumbnailSrc);
                }
            };
        }, [thumbnailSrc]);

        const content = useMemo(() => {
            if (isLoading) {
                return <LoadingThumbnail />;
            }

            if (!thumbnailSrc) {
                return <StaticThumbnail fileType={file.metadata.fileType} />;
            }

            return (
                <ThumbnailImage
                    src={thumbnailSrc}
                    alt=""
                    style={{ width: size, height: size }}
                />
            );
        }, [isLoading, thumbnailSrc, size, file.metadata.fileType]);

        return (
            <TileContainer
                style={{ width: size, height: size }}
                onClick={onClick}
            >
                {content}
                {isVideoFile && (
                    <VideoOverlay>
                        <PlayCircleOutlineOutlinedIcon />
                        <TileBottomTextOverlay>
                            {fileDurationString(file)}
                        </TileBottomTextOverlay>
                    </VideoOverlay>
                )}
            </TileContainer>
        );
    },
);

EmbedFileTile.displayName = "EmbedFileTile";

const Container = styled("div")({
    overflow: "auto",
    padding: `${CONTAINER_PADDING}px`,
});

const Grid = styled("div")<{ columns: number; gap: number }>(
    ({ columns, gap }) => ({
        display: "grid",
        gridTemplateColumns: `repeat(${columns}, 1fr)`,
        gridAutoRows: "min-content",
        gap: `${gap}px`,
    }),
);

const TileContainer = styled("div")({
    position: "relative",
    cursor: "pointer",
    borderRadius: "4px",
    overflow: "hidden",
    transition: "transform 0.2s ease",
    "&:hover": { transform: "scale(1.02)" },
});

const ThumbnailImage = styled("img")({
    objectFit: "cover",
    borderRadius: "4px",
});

const VideoOverlay = styled(Box)({
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    color: "white",
    "& svg": {
        fontSize: "2rem",
        filter: "drop-shadow(0 1px 3px rgba(0,0,0,0.5))",
    },
});
