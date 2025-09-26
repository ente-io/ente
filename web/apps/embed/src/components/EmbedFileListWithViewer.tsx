import { styled } from "@mui/material";
import { isSameDay } from "ente-base/date";
import { formattedDate } from "ente-base/i18n-date";
import type { EnteFile } from "ente-media/file";
import { fileCreationTime } from "ente-media/file-metadata";
import { t } from "i18next";
import { useCallback, useMemo, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import {
    EmbedFileList,
    type EmbedFileListAnnotatedFile,
} from "./EmbedFileList";
import { EmbedFileViewer } from "./EmbedFileViewer";

export interface EmbedFileListWithViewerProps {
    files: EnteFile[];
    onRemotePull?: () => Promise<void>; // Optional for embed
}

export const EmbedFileListWithViewer: React.FC<
    EmbedFileListWithViewerProps
> = ({ files }) => {
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

    const handleThumbnailClick = useCallback((index: number) => {
        setCurrentIndex(index);
        setOpenFileViewer(true);
    }, []);

    const handleCloseFileViewer = useCallback(() => {
        setOpenFileViewer(false);
    }, []);

    return (
        <Container>
            <AutoSizer>
                {({ height, width }) => (
                    <EmbedFileList
                        width={width}
                        height={height}
                        annotatedFiles={annotatedFiles}
                        onItemClick={handleThumbnailClick}
                    />
                )}
            </AutoSizer>
            <EmbedFileViewer
                open={openFileViewer}
                onClose={handleCloseFileViewer}
                initialIndex={currentIndex}
                files={files}
            />
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
