import { IconButton, Tooltip, styled } from "@mui/material";
import { useColorScheme, useTheme } from "@mui/material/styles";
import { CollectionMapDialog } from "components/Collections/CollectionMapDialog";
import { useModalVisibility } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
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
import { useSettingsSnapshot } from "ente-new/photos/components/utils/use-snapshot";
import { moveToTrash } from "ente-new/photos/services/collection";
import type { CollectionSummary } from "ente-new/photos/services/collection-summary";
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import { updateMapEnabled } from "ente-new/photos/services/settings";
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
    enableImageEditing?: boolean;
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
    activeCollectionSummary?: CollectionSummary;
    activeCollection?: Collection;
    /**
     * A function that can be used to create a UI notification to track the
     * progress of user-initiated download, and to cancel it if needed.
     */
    onAddSaveGroup: AddSaveGroup;

    onAddFileToCollection?: (
        file: EnteFile,
        sourceCollectionSummaryID?: number,
    ) => void;
    /**
     * Called when the list scrolls, providing the current scroll offset.
     */
    onScroll?: (scrollOffset: number) => void;
    /**
     * Called when the visible date at the top of the viewport changes.
     */
    onVisibleDateChange?: (date: string | undefined) => void;
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
    | "listBorderRadius"
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
    enableImageEditing = true,
    disableGrouping,
    enableSelect,
    selected,
    setSelected,
    activeCollectionID,
    activePersonID,
    activeCollectionSummary,
    activeCollection,
    favoriteFileIDs,
    emailByUserID,
    listBorderRadius,
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
    onScroll,
    onVisibleDateChange,
}) => {
    const [openFileViewer, setOpenFileViewer] = useState(false);
    const [currentIndex, setCurrentIndex] = useState(0);
    const { show: showMapDialog, props: mapDialogVisibilityProps } =
        useModalVisibility();
    const { onGenericError } = useBaseContext();
    const { mapEnabled } = useSettingsSnapshot();
    const { mode: colorSchemeMode, systemMode } = useColorScheme();
    const theme = useTheme();
    const resolvedMode =
        colorSchemeMode === "system"
            ? systemMode
            : (colorSchemeMode ?? theme.palette.mode);
    const isDarkMode = resolvedMode === "dark";

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

    const handleSaveEditedImageCopy = useMemo(() => {
        if (!enableImageEditing) return undefined;
        return (
            editedFile: File,
            collection: Collection,
            enteFile: EnteFile,
        ) => {
            uploadManager.prepareForNewUpload();
            uploadManager.showUploadProgressDialog();
            void uploadManager.uploadFile(editedFile, collection, enteFile);
        };
    }, [enableImageEditing]);

    const shouldShowMapButton =
        modePlus !== "search" &&
        activeCollectionSummary?.type === "all" &&
        activeCollectionSummary.fileCount > 0;

    const handleShowMap = useCallback(async () => {
        if (!activeCollectionSummary) return;
        if (!mapEnabled) {
            try {
                await updateMapEnabled(true);
            } catch (e) {
                onGenericError(e);
                return;
            }
        }
        showMapDialog();
    }, [activeCollectionSummary, mapEnabled, onGenericError, showMapDialog]);

    const headerWithMap = useMemo(() => {
        if (!shouldShowMapButton || !header) return header;
        return {
            ...header,
            component: (
                <HeaderWithMap>
                    <HeaderMain>{header.component}</HeaderMain>
                    <Tooltip title={t("map")}>
                        <IconButton
                            className="map-button"
                            size="small"
                            aria-label={t("map")}
                            onClick={handleShowMap}
                        >
                            <MapIcon
                                src="/images/gallery-globe/globe.svg"
                                alt=""
                                aria-hidden
                                $isDarkMode={isDarkMode}
                            />
                        </IconButton>
                    </Tooltip>
                </HeaderWithMap>
            ),
        };
    }, [header, handleShowMap, isDarkMode, shouldShowMapButton]);

    return (
        <Container>
            <AutoSizer>
                {({ height, width }) => (
                    <FileList
                        {...{ width, height, annotatedFiles }}
                        {...{
                            mode,
                            modePlus,
                            header: headerWithMap,
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
                            listBorderRadius,
                            onScroll,
                            onVisibleDateChange,
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
            {shouldShowMapButton && (
                <CollectionMapDialog
                    {...mapDialogVisibilityProps}
                    collectionSummary={activeCollectionSummary}
                    activeCollection={activeCollection}
                    onRemotePull={onRemotePull}
                    {...{
                        onAddSaveGroup,
                        onMarkTempDeleted,
                        onAddFileToCollection,
                        onRemoteFilesPull,
                        onVisualFeedback,
                        fileNormalCollectionIDs,
                        collectionNameByID,
                        onSelectCollection,
                        onSelectPerson,
                    }}
                />
            )}
        </Container>
    );
};

const Container = styled("div")`
    flex: 1;
    width: 100%;
`;

const HeaderWithMap = styled("div")`
    display: flex;
    align-items: center;
    justify-content: flex-start;
    gap: 12px;
    width: 100%;
    & > .map-button {
        flex-shrink: 0;
        margin-left: auto;
    }
`;

const HeaderMain = styled("div")`
    flex: 1;
    min-width: 0;
`;

const MapIcon = styled("img")<{ $isDarkMode: boolean }>(
    ({ theme, $isDarkMode }) => ({
        display: "block",
        width: 24,
        height: 24,
        filter:
            $isDarkMode || theme.palette.mode === "dark" ? "invert(1)" : "none",
    }),
);

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
