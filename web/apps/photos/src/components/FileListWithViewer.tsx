import { styled } from "@mui/material";
import { isSameDay } from "ente-base/date";
import { formattedDate } from "ente-base/i18n-date";
import type { AddSaveGroup } from "ente-gallery/components/utils/save-groups";
import {
    FileViewer,
    type FileViewerProps,
} from "ente-gallery/components/viewer/FileViewer";
import { downloadAndSaveFiles } from "ente-gallery/services/save";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { fileCreationTime, fileFileName } from "ente-media/file-metadata";
import { moveToTrash } from "ente-new/photos/services/collection";
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import { t } from "i18next";
import { useCallback, useMemo, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { uploadManager } from "services/upload-manager";
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
    /**
     * Called when the visibility of the file viewer dialog changes.
     */
    onSetOpenFileViewer?: (open: boolean) => void;
    /**
     * Called when an action in the file viewer requires us to perform a full
     * pull from remote.
     */
    onRemotePull: () => Promise<void>;
    /**
     * A function that can be used to create a UI notification to track the
     * progress of user-initiated download, and to cancel it if needed.
     */
    onAddSaveGroup: AddSaveGroup;

    onAddFileToCollection?: (
        file: EnteFile,
        sourceCollectionSummaryID?: number,
    ) => void;
} & Pick<
    FileListProps,
    | "mode"
    | "modePlus"
    | "header"
    | "footer"
    | "disableGrouping"
    | "enableSelect"
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
    footer,
    user,
    files,
    enableDownload,
    disableGrouping,
    enableSelect,
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
    onSetOpenFileViewer,
    onRemotePull,
    onRemoteFilesPull,
    onVisualFeedback,
    onAddSaveGroup,
    onToggleFavorite,
    onFileVisibilityUpdate,
    onMarkTempDeleted,
    onSelectCollection,
    onSelectPerson,
    onAddFileToCollection,
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

    const handleThumbnailClick = useCallback(
        (index: number) => {
            setCurrentIndex(index);
            setOpenFileViewer(true);
            onSetOpenFileViewer?.(true);
        },
        [onSetOpenFileViewer],
    );

    const handleCloseFileViewer = useCallback(() => {
        onSetOpenFileViewer?.(false);
        setOpenFileViewer(false);
    }, [onSetOpenFileViewer]);

    const handleTriggerRemotePull = useCallback(
        () => void onRemotePull(),
        [onRemotePull],
    );

    const handleDownload = useCallback(
        (file: EnteFile) =>
            downloadAndSaveFiles([file], fileFileName(file), onAddSaveGroup),
        [onAddSaveGroup],
    );

    const handleDelete = useMemo(() => {
        return onMarkTempDeleted
            ? (file: EnteFile) =>
                  moveToTrash([file]).then(() => onMarkTempDeleted([file]))
            : undefined;
    }, [onMarkTempDeleted]);

    const handleSaveEditedImageCopy = useCallback(
        (editedFile: File, collection: Collection, enteFile: EnteFile) => {
            uploadManager.prepareForNewUpload();
            uploadManager.showUploadProgressDialog();
            void uploadManager.uploadFile(editedFile, collection, enteFile);
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
                            footer,
                            user,
                            disableGrouping,
                            enableSelect,
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
                onAddFileToCollection={onAddFileToCollection}
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
