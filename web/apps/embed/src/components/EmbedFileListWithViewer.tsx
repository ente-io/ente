import { styled, Typography } from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { SpacedRow } from "ente-base/components/containers";
import { isSameDay } from "ente-base/date";
import { formattedDate } from "ente-base/i18n-date";
import { FileViewer } from "ente-gallery/components/viewer/FileViewer";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { fileCreationTime } from "ente-media/file-metadata";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "ente-new/photos/components/gallery/ListHeader";
import { t } from "i18next";
import { useCallback, useMemo, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import {
    EmbedFileList,
    type EmbedFileListAnnotatedFile,
} from "./EmbedFileList";

export interface EmbedFileListWithViewerProps {
    files: EnteFile[];
    publicCollection: Collection;
    onRemotePull?: () => Promise<void>;
}

export const EmbedFileListWithViewer: React.FC<
    EmbedFileListWithViewerProps
> = ({ files, publicCollection, onRemotePull }) => {
    const [openFileViewer, setOpenFileViewer] = useState(false);
    const [currentIndex, setCurrentIndex] = useState(0);

    const annotatedFiles = useMemo(
        (): EmbedFileListAnnotatedFile[] =>
            files.map((file) => ({
                file,
                timelineDateString: fileTimelineDateString(file),
            })),
        [files],
    );

    const handleThumbnailClick = useCallback(
        (index: number) => {
            console.log("Thumbnail clicked, index:", index);
            console.log("Files available:", files.length);
            setCurrentIndex(index);
            setOpenFileViewer(true);
        },
        [files.length],
    );

    const handleCloseFileViewer = useCallback(() => {
        console.log("Closing file viewer");
        setOpenFileViewer(false);
    }, []);

    const handleTriggerRemotePull = useCallback(
        () => void onRemotePull?.(),
        [onRemotePull],
    );

    const header = useMemo(
        () => (
            <GalleryItemsHeaderAdapter>
                <SpacedRow>
                    <GalleryItemsSummary
                        name={publicCollection.name}
                        fileCount={files.length}
                    />
                    <Typography
                        variant="small"
                        sx={{
                            color: "text.muted",
                            display: "flex",
                            flexDirection: "column",
                            alignItems: "flex-end",
                            marginRight: "16px",
                            fontSize: "0.8em",
                            "&:hover .powered-text": {
                                color: "text.base",
                                cursor: "pointer",
                            },
                            "&:hover .ente-logo": {
                                color: "#1db954",
                                cursor: "pointer",
                            },
                        }}
                    >
                        <span
                            className="powered-text"
                            style={{ transition: "color 0.2s ease" }}
                        >
                            powered by
                        </span>
                        <span
                            className="ente-logo"
                            style={{ transition: "color 0.2s ease" }}
                        >
                            <EnteLogo height={14} />
                        </span>
                    </Typography>
                </SpacedRow>
            </GalleryItemsHeaderAdapter>
        ),
        [publicCollection.name, files.length],
    );

    const footer = null;

    return (
        <Container>
            <AutoSizer>
                {({ height, width }) => (
                    <EmbedFileList
                        width={width}
                        height={height}
                        annotatedFiles={annotatedFiles}
                        onItemClick={handleThumbnailClick}
                        header={header}
                        footer={footer}
                    />
                )}
            </AutoSizer>
            {openFileViewer && (
                <FileViewer
                    open={openFileViewer}
                    onClose={handleCloseFileViewer}
                    initialIndex={currentIndex}
                    files={files}
                    disableDownload={true}
                    onTriggerRemotePull={handleTriggerRemotePull}
                    onVisualFeedback={() => {
                        console.log("Visual feedback requested");
                    }}
                />
            )}
        </Container>
    );
};

const Container = styled("div")({ flex: 1, width: "100%" });

const fileTimelineDateString = (file: EnteFile) => {
    const date = new Date(fileCreationTime(file) / 1000);
    return isSameDay(date, new Date())
        ? t("today")
        : isSameDay(date, new Date(Date.now() - 24 * 60 * 60 * 1000))
          ? t("yesterday")
          : formattedDate(date);
};
