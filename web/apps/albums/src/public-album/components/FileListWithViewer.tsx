import { styled } from "@mui/material";
import { isSameDay } from "ente-base/date";
import { formattedDate } from "ente-base/i18n-date";
import type { AddSaveGroup } from "@/gallery/components/utils/save-groups";
import {
    FileViewer,
    type FileViewerInitialSidebar,
} from "@/gallery/components/viewer/FileViewer";
import { downloadAndSaveFiles } from "@/gallery/services/save";
import type { EnteFile } from "ente-media/file";
import { fileCreationTime, fileFileName } from "ente-media/file-metadata";
import { t } from "i18next";
import {
    type ComponentProps,
    useCallback,
    useEffect,
    useMemo,
    useState,
} from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import {
    FileList,
    type FileListAnnotatedFile,
    type FileListProps,
} from "./FileList";

export type FileListWithViewerProps = {
    /**
     * The list of files to show.
     */
    files: EnteFile[];
    enableDownload?: boolean;
    /**
     * If set, the file viewer will open to this file index on mount/update.
     * Set to undefined after the navigation is complete.
     */
    pendingFileIndex?: number;
    /**
     * The sidebar to open when navigating to a file from feed.
     */
    pendingFileSidebar?: FileViewerInitialSidebar;
    /**
     * The comment ID to highlight when navigating from feed.
     */
    pendingHighlightCommentID?: string;
    /**
     * Called after the pending navigation is consumed.
     */
    onPendingNavigationConsumed?: () => void;
    /**
     * A function that can be used to create a UI notification to track the
     * progress of user-initiated download, and to cancel it if needed.
     */
    onAddSaveGroup: AddSaveGroup;
} & Pick<
    FileListProps,
    | "layout"
    | "header"
    | "footer"
    | "enableSelect"
    | "selected"
    | "setSelected"
    | "activeCollectionID"
> &
    Pick<
        ComponentProps<typeof FileViewer>,
        | "publicAlbumsCredentials"
        | "collectionKey"
        | "onJoinAlbum"
        | "enableComment"
        | "enableJoin"
    >;

/**
 * A list of files (represented by their thumbnails), along with a file viewer
 * that opens on activating the thumbnail (and also allows the user to navigate
 * through this list of files).
 */
export const FileListWithViewer: React.FC<FileListWithViewerProps> = ({
    layout,
    header,
    footer,
    files,
    enableDownload,
    enableSelect,
    selected,
    setSelected,
    activeCollectionID,
    onAddSaveGroup,
    pendingFileIndex,
    pendingFileSidebar,
    pendingHighlightCommentID,
    onPendingNavigationConsumed,
    publicAlbumsCredentials,
    collectionKey,
    onJoinAlbum,
    enableComment,
    enableJoin,
}) => {
    const [openFileViewer, setOpenFileViewer] = useState(false);
    const [currentIndex, setCurrentIndex] = useState(0);
    const [initialSidebar, setInitialSidebar] = useState<
        FileViewerInitialSidebar | undefined
    >(undefined);
    const [highlightCommentID, setHighlightCommentID] = useState<
        string | undefined
    >(undefined);

    // Handle pending navigation from feed item clicks
    useEffect(() => {
        if (pendingFileIndex !== undefined) {
            setCurrentIndex(pendingFileIndex);
            setInitialSidebar(pendingFileSidebar);
            setHighlightCommentID(pendingHighlightCommentID);
            setOpenFileViewer(true);
            onPendingNavigationConsumed?.();
        }
    }, [
        pendingFileIndex,
        pendingFileSidebar,
        pendingHighlightCommentID,
        onPendingNavigationConsumed,
    ]);

    // Clear initial sidebar state when file viewer closes
    const handleCloseFileViewerInternal = useCallback(() => {
        setInitialSidebar(undefined);
        setHighlightCommentID(undefined);
        setOpenFileViewer(false);
    }, []);

    const annotatedFiles = useMemo(
        (): FileListAnnotatedFile[] =>
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

    const handleDownload = useCallback(
        (file: EnteFile) =>
            downloadAndSaveFiles([file], fileFileName(file), onAddSaveGroup),
        [onAddSaveGroup],
    );

    return (
        <Container>
            <AutoSizer>
                {({ height, width }) => (
                    <FileList
                        {...{ width, height, annotatedFiles }}
                        {...{
                            layout,
                            header,
                            footer,
                            enableSelect,
                            selected,
                            setSelected,
                            activeCollectionID,
                        }}
                        onItemClick={handleThumbnailClick}
                    />
                )}
            </AutoSizer>
            <FileViewer
                open={openFileViewer}
                onClose={handleCloseFileViewerInternal}
                initialIndex={currentIndex}
                initialSidebar={initialSidebar}
                highlightCommentID={highlightCommentID}
                disableDownload={!enableDownload}
                {...{
                    files,
                    publicAlbumsCredentials,
                    collectionKey,
                    onJoinAlbum,
                    enableComment,
                    enableJoin,
                }}
                onDownload={handleDownload}
                activeCollectionID={activeCollectionID}
            />
        </Container>
    );
};

const Container = styled("div")`
    flex: 1;
    width: 100%;
`;

/**
 * See: [Note: Timeline date string]
 */
const fileTimelineDateString = (file: EnteFile) => {
    const date = new Date(fileCreationTime(file) / 1000);
    return isSameDay(date, new Date())
        ? t("today")
        : isSameDay(date, new Date(Date.now() - 24 * 60 * 60 * 1000))
          ? t("yesterday")
          : formattedDate(date);
};
