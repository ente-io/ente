import { isSameDay } from "@/base/date";
import { formattedDate } from "@/base/i18n-date";
import {
    FileViewer,
    type FileViewerProps,
} from "@/gallery/components/viewer/FileViewer";
import { type RenderableSourceURLs } from "@/gallery/services/download";
import type { Collection } from "@/media/collection";
import { EnteFile } from "@/media/file";
import { moveToTrash, TRASH_SECTION } from "@/new/photos/services/collection";
import { styled } from "@mui/material";
import { t } from "i18next";
import { useCallback, useMemo, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import {
    addToFavorites,
    removeFromFavorites,
} from "services/collectionService";
import uploadManager from "services/upload/uploadManager";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";
import { downloadSingleFile } from "utils/file";
import {
    FileList,
    type FileListAnnotatedFile,
    type FileListProps,
} from "./FileList";

/**
 * An {@link EnteFile} augmented with various in-memory state used for
 * displaying it in the photo viewer.
 */
export type DisplayFile = EnteFile & {
    src?: string;
    srcURLs?: RenderableSourceURLs;
    /**
     * An object URL corresponding to the image portion, if any, associated with
     * the {@link DisplayFile}.
     *
     * - For images, this will be the object URL of the renderable image itself.
     * - For live photos, this will be the object URL of the image portion of
     *   the live photo.
     * - For videos, this will not be defined.
     */
    associatedImageURL?: string | undefined;
    msrc?: string;
    html?: string;
    w?: number;
    h?: number;
    title?: string;
    isSourceLoaded?: boolean;
    conversionFailed?: boolean;
    canForceConvert?: boolean;
    /**
     * [Note: Timeline date string]
     *
     * The timeline date string is a formatted date string under which a
     * particular file should be grouped in the gallery listing. e.g. "Today",
     * "Yesterday", "Fri, 21 Feb" etc.
     *
     * All files which have the same timelineDateString will be grouped under a
     * single section in the gallery listing, prefixed by the timelineDateString
     * itself, and a checkbox to select all files on that date.
     */
    timelineDateString?: string;
};

export type FileListWithViewerProps = {
    /**
     * The list of files to show.
     */
    files: EnteFile[];
    enableDownload?: boolean;
    /**
     * Called when the component wants to update the in-memory, unsynced,
     * favorite status of a file.
     *
     * For more details, see {@link unsyncedFavoriteUpdates} in the gallery
     * reducer's documentation.
     *
     * Not set in the context of the shared albums app.
     */
    onMarkUnsyncedFavoriteUpdate?: (
        fileID: number,
        isFavorite: boolean,
    ) => void;
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
     * Called when an action in the file viewer requires us to sync with remote.
     */
    onSyncWithRemote: () => Promise<void>;
} & Pick<
    FileListProps,
    | "mode"
    | "modePlus"
    | "showAppDownloadBanner"
    | "selectable"
    | "selected"
    | "setSelected"
    | "activeCollectionID"
    | "activePersonID"
    | "favoriteFileIDs"
> &
    Pick<
        FileViewerProps,
        | "user"
        | "isInIncomingSharedCollection"
        | "isInHiddenSection"
        | "fileCollectionIDs"
        | "allCollectionsNameByID"
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
    user,
    files,
    enableDownload,
    showAppDownloadBanner,
    selectable,
    selected,
    setSelected,
    activeCollectionID,
    activePersonID,
    favoriteFileIDs,
    isInIncomingSharedCollection,
    isInHiddenSection,
    fileCollectionIDs,
    allCollectionsNameByID,
    setFilesDownloadProgressAttributesCreator,
    onMarkUnsyncedFavoriteUpdate,
    onMarkTempDeleted,
    onSetOpenFileViewer,
    onSyncWithRemote,
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

    const handleTriggerSyncWithRemote = useCallback(
        () => void onSyncWithRemote(),
        [onSyncWithRemote],
    );

    const handleToggleFavorite = useMemo(() => {
        return favoriteFileIDs && onMarkUnsyncedFavoriteUpdate
            ? async (file: EnteFile) => {
                  const isFavorite = favoriteFileIDs!.has(file.id);
                  await (isFavorite ? removeFromFavorites : addToFavorites)(
                      file,
                      true,
                  );
                  // See: [Note: File viewer update and dispatch]
                  onMarkUnsyncedFavoriteUpdate(file.id, !isFavorite);
              }
            : undefined;
    }, [favoriteFileIDs, onMarkUnsyncedFavoriteUpdate]);

    const handleDownload = useCallback(
        (file: EnteFile) => {
            const setSingleFileDownloadProgress =
                setFilesDownloadProgressAttributesCreator!(file.metadata.title);
            void downloadSingleFile(file, setSingleFileDownloadProgress);
        },
        [setFilesDownloadProgressAttributesCreator],
    );

    const handleDelete = useMemo(() => {
        return onMarkTempDeleted
            ? async (file: EnteFile) => {
                  await moveToTrash([file]);
                  // See: [Note: File viewer update and dispatch]
                  onMarkTempDeleted?.([file]);
              }
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
                            showAppDownloadBanner,
                            selectable,
                            selected,
                            setSelected,
                            activeCollectionID,
                            activePersonID,
                            favoriteFileIDs,
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
                isInTrashSection={activeCollectionID === TRASH_SECTION}
                {...{
                    user,
                    files,
                    isInHiddenSection,
                    isInIncomingSharedCollection,
                    favoriteFileIDs,
                    fileCollectionIDs,
                    allCollectionsNameByID,
                    onSelectCollection,
                    onSelectPerson,
                }}
                onTriggerSyncWithRemote={handleTriggerSyncWithRemote}
                onToggleFavorite={handleToggleFavorite}
                onDownload={handleDownload}
                onDelete={handleDelete}
                onSaveEditedImageCopy={handleSaveEditedImageCopy}
            />
        </Container>
    );
};

const Container = styled("div")`
    display: block;
    flex: 1;
    width: 100%;
    flex-wrap: wrap;
    margin: 0 auto;
    overflow: hidden;
    .pswp-thumbnail {
        display: inline-block;
        cursor: pointer;
    }
`;

/**
 * See: [Note: Timeline date string]
 */
const fileTimelineDateString = (item: EnteFile) => {
    const date = new Date(item.metadata.creationTime / 1000);
    return isSameDay(date, new Date())
        ? t("today")
        : isSameDay(date, new Date(Date.now() - 24 * 60 * 60 * 1000))
          ? t("yesterday")
          : formattedDate(date);
};
