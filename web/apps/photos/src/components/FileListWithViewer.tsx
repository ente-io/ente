import { styled } from "@mui/material";
import { isSameDay } from "ente-base/date";
import { formattedDate } from "ente-base/i18n-date";
import {
    FileViewer,
    type FileViewerProps,
} from "ente-gallery/components/viewer/FileViewer";
import type { Collection } from "ente-media/collection";
import { EnteFile } from "ente-media/file";
import { fileCreationTime, fileFileName } from "ente-media/file-metadata";
import { moveToTrash } from "ente-new/photos/services/collection";
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import { t } from "i18next";
import { useCallback, useMemo, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { uploadManager } from "services/upload-manager";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";
import { downloadSingleFile } from "utils/file";
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
     * Called when the component wants to mark the given files as deleted in the
     * the in-memory, unsynced, state maintained by the top level gallery.
     *
     * For more details, see {@link unsyncedFavoriteUpdates} in the gallery
     * reducer's documentation.
     *
     * Not set in the context of the shared albums app.
     */
    onMarkTempDeleted?: (files: EnteFile[]) => void;
    setFilesDownloadProgressAttributesCreator?: SetFilesDownloadProgressAttributesCreator;
    /**
     * Called when the visibility of the file viewer dialog changes.
     */
    onSetOpenFileViewer?: (open: boolean) => void;
    /**
     * Called when an action in the file viewer requires us to perform a full
     * pull from remote.
     */
    onRemotePull: () => Promise<void>;
} & Pick<
    FileListProps,
    | "mode"
    | "modePlus"
    | "header"
    | "showAppDownloadBanner"
    | "isMagicSearchResult"
    | "selectable"
    | "selected"
    | "setSelected"
    | "activeCollectionID"
    | "activePersonID"
    | "favoriteFileIDs"
    | "emailByUserID"
> &
    Pick<
        FileViewerProps,
        | "user"
        | "isInIncomingSharedCollection"
        | "isInHiddenSection"
        | "fileNormalCollectionIDs"
        | "collectionNameByID"
        | "pendingFavoriteUpdates"
        | "pendingVisibilityUpdates"
        | "onRemoteFilesPull"
        | "onVisualFeedback"
        | "onToggleFavorite"
        | "onFileVisibilityUpdate"
        | "onSelectCollection"
        | "onSelectPerson"
    >;

/**
 * A list of files (represented by their thumbnails), along with a file viewer
 * that opens on activating the thumbnail (and also allows the user to navigate
 * through this list of files).
 */
export const FileListWithViewer: React.FC<FileListWithViewerProps> = ({
    mode,
    modePlus,
    header,
    user,
    files,
    enableDownload,
    showAppDownloadBanner,
    isMagicSearchResult,
    selectable,
    selected,
    setSelected,
    activeCollectionID,
    activePersonID,
    favoriteFileIDs,
    emailByUserID,
    isInIncomingSharedCollection,
    isInHiddenSection,
    fileNormalCollectionIDs,
    collectionNameByID,
    pendingFavoriteUpdates,
    pendingVisibilityUpdates,
    setFilesDownloadProgressAttributesCreator,
    onSetOpenFileViewer,
    onRemotePull,
    onRemoteFilesPull,
    onVisualFeedback,
    onToggleFavorite,
    onFileVisibilityUpdate,
    onMarkTempDeleted,
    onSelectCollection,
    onSelectPerson,
}) => {
    const [openFileViewer, setOpenFileViewer] = useState(false);
    const [currentIndex, setCurrentIndex] = useState(0);

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
        onSetOpenFileViewer?.(true);
    }, []);

    const handleCloseFileViewer = useCallback(() => {
        onSetOpenFileViewer?.(false);
        setOpenFileViewer(false);
    }, []);

    const handleTriggerRemotePull = useCallback(
        () => void onRemotePull(),
        [onRemotePull],
    );

    const handleDownload = useCallback(
        (file: EnteFile) => {
            const setSingleFileDownloadProgress =
                setFilesDownloadProgressAttributesCreator!(fileFileName(file));
            void downloadSingleFile(file, setSingleFileDownloadProgress);
        },
        [setFilesDownloadProgressAttributesCreator],
    );

    const handleDelete = useMemo(() => {
        return onMarkTempDeleted
            ? (file: EnteFile) =>
                  moveToTrash([file]).then(() => onMarkTempDeleted?.([file]))
            : undefined;
    }, [onMarkTempDeleted]);

    const handleSaveEditedImageCopy = useCallback(
        (editedFile: File, collection: Collection, enteFile: EnteFile) => {
            uploadManager.prepareForNewUpload();
            uploadManager.showUploadProgressDialog();
            uploadManager.uploadFile(editedFile, collection, enteFile);
        },
        [],
    );

    return (
        <Container>
            <AutoSizer>
                {({ height, width }) => (
                    <FileList
                        {...{ width, height, annotatedFiles }}
                        {...{
                            mode,
                            modePlus,
                            header,
                            user,
                            showAppDownloadBanner,
                            isMagicSearchResult,
                            selectable,
                            selected,
                            setSelected,
                            activeCollectionID,
                            activePersonID,
                            favoriteFileIDs,
                            emailByUserID,
                        }}
                        onItemClick={handleThumbnailClick}
                    />
                )}
            </AutoSizer>
            <FileViewer
                open={openFileViewer}
                onClose={handleCloseFileViewer}
                initialIndex={currentIndex}
                disableDownload={!enableDownload}
                isInTrashSection={
                    activeCollectionID == PseudoCollectionID.trash
                }
                {...{
                    user,
                    files,
                    isInHiddenSection,
                    isInIncomingSharedCollection,
                    favoriteFileIDs,
                    fileNormalCollectionIDs,
                    collectionNameByID,
                    pendingFavoriteUpdates,
                    pendingVisibilityUpdates,
                    onRemoteFilesPull,
                    onVisualFeedback,
                    onToggleFavorite,
                    onFileVisibilityUpdate,
                    onSelectCollection,
                    onSelectPerson,
                }}
                onTriggerRemotePull={handleTriggerRemotePull}
                onDownload={handleDownload}
                onDelete={handleDelete}
                onSaveEditedImageCopy={handleSaveEditedImageCopy}
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
