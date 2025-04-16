import ArchiveOutlinedIcon from "@mui/icons-material/ArchiveOutlined";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import FullscreenExitOutlinedIcon from "@mui/icons-material/FullscreenExitOutlined";
import FullscreenOutlinedIcon from "@mui/icons-material/FullscreenOutlined";
import UnArchiveIcon from "@mui/icons-material/Unarchive";
import {
    Dialog,
    DialogContent,
    DialogTitle,
    Menu,
    MenuItem,
    Stack,
    styled,
    Typography,
    type ModalProps,
} from "@mui/material";
import { isDesktop } from "ente-base/app";
import { SpacedRow } from "ente-base/components/containers";
import { InlineErrorIndicator } from "ente-base/components/ErrorIndicator";
import { TitledMiniDialog } from "ente-base/components/MiniDialog";
import { DialogCloseIconButton } from "ente-base/components/mui/DialogCloseIconButton";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import { type ModalVisibilityProps } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import { lowercaseExtension } from "ente-base/file-name";
import { formattedListJoin, pt, ut } from "ente-base/i18n";
import type { LocalUser } from "ente-base/local-user";
import log from "ente-base/log";
import {
    FileInfo,
    type FileInfoExif,
    type FileInfoProps,
} from "ente-gallery/components/FileInfo";
import type { Collection } from "ente-media/collection";
import { fileVisibility, ItemVisibility } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import type { EnteFile } from "ente-media/file.js";
import { isHEICExtension, needsJPEGConversion } from "ente-media/formats";
import {
    ImageEditorOverlay,
    type ImageEditorOverlayProps,
} from "ente-new/photos/components/ImageEditorOverlay";
import { t } from "i18next";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import {
    fileInfoExifForFile,
    updateItemDataAlt,
    type ItemData,
} from "./data-source";
import {
    FileViewerPhotoSwipe,
    moreButtonID,
    moreMenuID,
    resetMoreMenuButtonOnMenuClose,
    shouldUsePlayerV2,
    type FileViewerPhotoSwipeDelegate,
} from "./photoswipe";

/**
 * Derived data for a file that is needed to display the file viewer controls
 * etc associated with the file.
 *
 * This is recomputed on-demand each time the slide changes.
 */
export interface FileViewerFileAnnotation {
    /**
     * The id of the file whose annotation this is.
     */
    fileID: number;
    /**
     * `true` if this file is owned by the logged in user (if any).
     */
    isOwnFile: boolean;
    /**
     * `true` if the toggle favorite action should be shown for this file.
     */
    showFavorite: boolean;
    /**
     * Set if the download action should be shown for this file.
     *
     * - When "bar", the action button is shown among the bar icons.
     *
     * - When "menu", the action is shown as a more menu entry.
     *
     * Note: "bar" should only be set if {@link haveUser} is also true.
     */
    showDownload: "bar" | "menu" | undefined;
    /**
     * `true` if the delete action should be shown for this file.
     */
    showDelete: boolean;
    /**
     * `true` if the toggle archive action should be shown for this file.
     */
    showArchive: boolean;
    /**
     * `true` if the copy image action should be shown for this file.
     */
    showCopyImage: boolean;
    /**
     * `true` if this is an image which can be edited, _and_ editing is
     * possible, and the edit action should therefore be shown for this file.
     */
    showEditImage: boolean;
}

/**
 * A file, its annotation, and its item data, in a nice cosy box.
 */
export interface FileViewerAnnotatedFile {
    file: EnteFile;
    annotation: FileViewerFileAnnotation;
    itemData: ItemData;
}

export type FileViewerProps = ModalVisibilityProps & {
    /**
     * The currently logged in user, if any.
     *
     * - If we're running in the context of the photos app, then this should be
     *   set to the currently logged in user.
     *
     * - If we're running in the context of the public albums app, then this
     *   should not be set.
     *
     * See: [Note: Gallery children can assume user]
     */
    user?: LocalUser;
    /**
     * The list of files that are currently being displayed in the context in
     * which the file viewer was invoked.
     *
     * Although the file viewer is called on to display a particular file
     * (specified by the {@link initialIndex} prop), the viewer is always used
     * in the context of a an album, or search results, or some other arbitrary
     * list of files. The {@link files} prop sets this underlying list of files.
     *
     * After the initial file has been shown, the user can navigate through the
     * other files from within the viewer by using the arrow buttons.
     */
    files: EnteFile[];
    /**
     * The index of the file that should be initially shown.
     *
     * Subsequently the user may navigate between files by using the controls
     * provided within the file viewer itself.
     */
    initialIndex: number;
    /**
     * If true then the viewer does not show controls for downloading the file.
     */
    disableDownload?: boolean;
    /**
     * `true` when we are viewing files in an album that the user does not own.
     */
    isInIncomingSharedCollection?: boolean;
    /**
     * `true` when we are viewing files in the Trash.
     */
    isInTrashSection?: boolean;
    /**
     * `true` when we are viewing files in the hidden section.
     */
    isInHiddenSection?: boolean;
    /**
     * File IDs of all the files that the user has marked as a favorite.
     *
     * See also {@link onToggleFavorite}.
     */
    favoriteFileIDs?: Set<number>;
    /**
     * File IDs of for which an update of its favorite status is pending (e.g.
     * due to a toggle favorite action in the file viewer).
     *
     * See also {@link favoriteFileIDs} and {@link onToggleFavorite}.
     */
    pendingFavoriteUpdates?: Set<number>;
    /**
     * File IDs of for which an update of its visibility is pending (e.g. due to
     * a toggle archived action in the file viewer).
     *
     * See also {@link onFileVisibilityUpdate}.
     */
    pendingVisibilityUpdates?: Set<number>;
    /**
     * A mapping from file IDs to the IDs of the normal (non-hidden) collections
     * that they are a part of.
     */
    fileNormalCollectionIDs?: FileInfoProps["fileCollectionIDs"];
    /**
     * Called when there was some update performed within the file viewer that
     * necessitates us to sync with remote again to fetch the latest updates.
     *
     * This is called lazily, and at most once, when the file viewer is closing
     * if any changes were made in the file info panel of the file viewer for
     * any of the files that the user was viewing (e.g. if they changed the
     * caption). Those changes have already been applied to both remote and to
     * the in-memory file object used by the file viewer; this callback is to
     * trigger a sync so that our local database also gets up to speed.
     *
     * If we're in a context where edits are not possible, e.g. {@link user} is
     * not defined, then this prop is not used.
     */
    onTriggerSyncWithRemote?: () => void;
    /**
     * Called when the user performs an action which does not otherwise have any
     * immediate visual impact, to acknowledge it.
     *
     * See: [Note: Visual feedback to acknowledge user actions]
     */
    onVisualFeedback: () => void;
    /**
     * Called when the favorite status of given {@link file} should be toggled
     * from its current value.
     *
     * The favorite toggle button is shown only if all three of
     * {@link favoriteFileIDs}, {@link pendingFavoriteUpdates} and
     * {@link onToggleFavorite} are provided.
     */
    onToggleFavorite?: (file: EnteFile) => Promise<void>;
    /**
     * Called when {@link visibility} of the given {@link file} should be
     * updated (when the user activates toggle archived action).
     *
     * The toggle archived action is shown only if both
     * {@link pendingVisibilityUpdates} and {@link onFileVisibilityUpdate} are
     * provided.
     */
    onFileVisibilityUpdate?: (
        file: EnteFile,
        visibility: ItemVisibility,
    ) => Promise<void>;
    /**
     * Called when the given {@link file} should be downloaded.
     *
     * If this is not provided then the download action will not be shown.
     */
    onDownload?: (file: EnteFile) => void;
    /**
     * Called when the given {@link file} should be deleted.
     *
     * If this is not provided then the delete action will not be shown.
     */
    onDelete?: (file: EnteFile) => Promise<void>;
    /**
     * Called when the user edits an image in the image editor and asks us to
     * save their edits as a copy.
     *
     * Editing is disabled if this is not provided.
     *
     * See {@link onSaveEditedCopy} in the {@link ImageEditorOverlay} props for
     * documentation about the parameters.
     */
    onSaveEditedImageCopy?: ImageEditorOverlayProps["onSaveEditedCopy"];
} & Pick<
        FileInfoProps,
        "collectionNameByID" | "onSelectCollection" | "onSelectPerson"
    >;

/**
 * A PhotoSwipe based image, live photo and video viewer.
 */
export const FileViewer: React.FC<FileViewerProps> = ({
    open,
    onClose,
    user,
    files,
    initialIndex,
    disableDownload,
    isInIncomingSharedCollection,
    isInTrashSection,
    isInHiddenSection,
    favoriteFileIDs,
    pendingFavoriteUpdates,
    pendingVisibilityUpdates,
    fileNormalCollectionIDs,
    collectionNameByID,
    onTriggerSyncWithRemote,
    onVisualFeedback,
    onToggleFavorite,
    onFileVisibilityUpdate,
    onDownload,
    onDelete,
    onSelectCollection,
    onSelectPerson,
    onSaveEditedImageCopy,
}) => {
    const { onGenericError } = useBaseContext();

    // There are 3 things involved in this dance:
    //
    // 1. Us, "FileViewer". We're a React component.
    // 2. The custom PhotoSwipe wrapper, "FileViewerPhotoSwipe". It is a class.
    // 3. The delegate, "FileViewerPhotoSwipeDelegate".
    //
    // The delegate acts as a bridge between us and (our custom) photoswipe
    // class, to avoid recreating the class each time a "dynamic" prop changes.
    // The delegate has a stable identity, we just keep updating the callback
    // functions that it holds.
    //
    // The word "dynamic" here means a prop on whose change we should not
    // recreate the photoswipe dialog.
    const delegateRef = useRef<FileViewerPhotoSwipeDelegate | undefined>(
        undefined,
    );

    // We also need to maintain a ref to the currently displayed dialog since we
    // might need to ask it to refresh its contents.
    const psRef = useRef<FileViewerPhotoSwipe | undefined>(undefined);

    // Whenever we get a callback from our custom PhotoSwipe instance, we also
    // get the active file on which that action was performed as an argument. We
    // save it as the `activeAnnotatedFile` state so that the rest of our React
    // tree can use it.
    //
    // This is not guaranteed, or even intended, to be in sync with the active
    // file shown within the file viewer. All that this guarantees is this will
    // refer to the file on which the last user initiated action was performed.
    const [activeAnnotatedFile, setActiveAnnotatedFile] = useState<
        FileViewerAnnotatedFile | undefined
    >(undefined);

    // With semantics similar to `activeAnnotatedFile`, this is the exif data
    // associated with the `activeAnnotatedFile`, if any.
    const [activeFileExif, setActiveFileExif] = useState<
        FileInfoExif | undefined
    >(undefined);

    const [openFileInfo, setOpenFileInfo] = useState(false);
    const [moreMenuAnchorEl, setMoreMenuAnchorEl] =
        useState<HTMLElement | null>(null);
    const [openImageEditor, setOpenImageEditor] = useState(false);
    const [openConfirmDelete, setOpenConfirmDelete] = useState(false);
    const [openShortcuts, setOpenShortcuts] = useState(false);

    const [isFullscreen, setIsFullscreen] = useState(false);

    // If `true`, then we need to trigger a sync with remote when we close.
    const [, setNeedsSync] = useState(false);

    const handleNeedsRemoteSync = useCallback(() => setNeedsSync(true), []);

    const handleClose = useCallback(() => {
        setNeedsSync((needSync) => {
            if (needSync) onTriggerSyncWithRemote?.();
            return false;
        });
        setOpenFileInfo(false);
        // No need to `resetMoreMenuButtonOnMenuClose` since we're closing
        // anyway and it'll be removed from the DOM.
        setMoreMenuAnchorEl(null);
        setOpenImageEditor(false);
        setOpenConfirmDelete(false);
        setOpenShortcuts(false);
        onClose();
    }, [onTriggerSyncWithRemote, onClose]);

    const handleViewInfo = useCallback(
        (annotatedFile: FileViewerAnnotatedFile) => {
            setActiveFileExif(
                fileInfoExifForFile(annotatedFile.file, (exif) =>
                    setActiveFileExif(exif),
                ),
            );
            setOpenFileInfo(true);
        },
        [],
    );

    const handleFileInfoClose = useCallback(() => setOpenFileInfo(false), []);

    // Callback invoked when the download action is triggered by activating the
    // download button in the PhotoSwipe bar.
    const handleDownloadBarAction = useCallback(
        (annotatedFile: FileViewerAnnotatedFile) => {
            onDownload!(annotatedFile.file);
        },
        [onDownload],
    );

    // Callback invoked when the download action is triggered by activating the
    // download menu item in the more menu.
    //
    // Not memoized since it uses the frequently changing `activeAnnotatedFile`.
    const handleDownloadMenuAction = () => {
        handleMoreMenuCloseIfNeeded();
        onDownload!(activeAnnotatedFile!.file);
    };

    const handleMore = useCallback(
        (buttonElement: HTMLElement) => setMoreMenuAnchorEl(buttonElement),
        [],
    );

    const handleMoreMenuCloseIfNeeded = useCallback(() => {
        setMoreMenuAnchorEl((el) => {
            if (el) resetMoreMenuButtonOnMenuClose(el);
            return null;
        });
    }, []);

    const handleConfirmDelete = useMemo(() => {
        return onDelete
            ? () => {
                  handleMoreMenuCloseIfNeeded();
                  setOpenConfirmDelete(true);
              }
            : undefined;
    }, [onDelete, handleMoreMenuCloseIfNeeded]);

    const handleConfirmDeleteClose = useCallback(
        () => setOpenConfirmDelete(false),
        [],
    );

    // Not memoized since it uses the frequently changing `activeAnnotatedFile`.
    const handleDelete = async () => {
        const file = activeAnnotatedFile!.file;
        await onDelete!(file);
        handleNeedsRemoteSync();
    };

    // Not memoized since it uses the frequently changing `activeAnnotatedFile`.
    const handleCopyImage = useCallback(() => {
        handleMoreMenuCloseIfNeeded();
        const imageURL = activeAnnotatedFile?.itemData.imageURL;
        // Safari does not copy if we do not call `navigator.clipboard.write`
        // synchronously within the click event handler, but it does supports
        // passing a promise in lieu of the blob.
        void window.navigator.clipboard
            .write([
                new ClipboardItem({
                    "image/png": createImagePNGBlob(imageURL!),
                }),
            ])
            .catch(onGenericError);
    }, [onGenericError, handleMoreMenuCloseIfNeeded, activeAnnotatedFile]);

    const handleEditImage = useMemo(() => {
        return onSaveEditedImageCopy
            ? () => {
                  handleMoreMenuCloseIfNeeded();
                  setOpenImageEditor(true);
              }
            : undefined;
    }, [onSaveEditedImageCopy, handleMoreMenuCloseIfNeeded]);

    const handleImageEditorClose = useCallback(
        () => setOpenImageEditor(false),
        [],
    );

    const handleSaveEditedCopy = useMemo(() => {
        return onSaveEditedImageCopy
            ? (
                  editedFile: File,
                  collection: Collection,
                  enteFile: EnteFile,
              ) => {
                  onSaveEditedImageCopy(editedFile, collection, enteFile);
                  handleClose();
              }
            : undefined;
    }, [onSaveEditedImageCopy, handleClose]);

    const handleAnnotate = useCallback(
        (file: EnteFile, itemData: ItemData): FileViewerAnnotatedFile => {
            const fileID = file.id;
            const isOwnFile = file.ownerID == user?.id;

            const canModify =
                isOwnFile && !isInTrashSection && !isInHiddenSection;

            const showFavorite = canModify;

            const showArchive = canModify;

            const showDelete =
                !!handleConfirmDelete &&
                isOwnFile &&
                !isInTrashSection &&
                !isInIncomingSharedCollection;

            const showEditImage =
                !!handleEditImage && canModify && fileIsEditableImage(file);

            const showDownload = (() => {
                if (disableDownload) return undefined;
                if (!onDownload) return undefined;
                if (user) {
                    // Logged in users see the download option in the more menu.
                    return "menu";
                } else {
                    // In public albums, the download option is shown in the bar
                    // buttons, in lieu of the favorite option.
                    return "bar";
                }
            })();

            const showCopyImage = (() => {
                if (disableDownload) return false;
                switch (file.metadata.fileType) {
                    case FileType.image:
                    case FileType.livePhoto:
                        return true;
                    default:
                        return false;
                }
            })();

            const annotation: FileViewerFileAnnotation = {
                fileID,
                isOwnFile,
                showFavorite,
                showDownload,
                showDelete,
                showArchive,
                showCopyImage,
                showEditImage,
            };

            const annotatedFile = { file, annotation, itemData };
            setActiveAnnotatedFile(annotatedFile);
            return annotatedFile;
        },
        [
            user,
            disableDownload,
            isInIncomingSharedCollection,
            isInTrashSection,
            isInHiddenSection,
            onDownload,
            handleEditImage,
            handleConfirmDelete,
        ],
    );

    const handleSelectCollection = useMemo(() => {
        return onSelectCollection
            ? (collectionID: number) => {
                  onSelectCollection(collectionID);
                  handleClose();
              }
            : undefined;
    }, [onSelectCollection, handleClose]);

    const handleSelectPerson = useMemo(() => {
        return onSelectPerson
            ? (personID: string) => {
                  onSelectPerson(personID);
                  handleClose();
              }
            : undefined;
    }, [onSelectPerson, handleClose]);

    const haveUser = !!user;

    const getFiles = useCallback(() => files, [files]);

    const isFavorite = useCallback(
        ({ file }: FileViewerAnnotatedFile) => {
            if (
                !haveUser ||
                !favoriteFileIDs ||
                !pendingFavoriteUpdates ||
                !onToggleFavorite
            ) {
                return undefined;
            }
            return favoriteFileIDs.has(file.id);
        },
        [haveUser, favoriteFileIDs, pendingFavoriteUpdates, onToggleFavorite],
    );

    const isFavoritePending = useCallback(
        ({ file }: FileViewerAnnotatedFile) =>
            !!pendingFavoriteUpdates?.has(file.id),
        [pendingFavoriteUpdates],
    );

    const toggleFavorite = useCallback(
        ({ file }: FileViewerAnnotatedFile) =>
            onToggleFavorite!(file)
                .catch(onGenericError)
                .finally(handleNeedsRemoteSync),
        [onToggleFavorite, onGenericError, handleNeedsRemoteSync],
    );

    const updateFullscreenStatus = useCallback(() => {
        setIsFullscreen(!!document.fullscreenElement);
    }, []);

    const handleToggleFullscreen = useCallback(() => {
        handleMoreMenuCloseIfNeeded();
        void (
            document.fullscreenElement
                ? document.exitFullscreen()
                : document.body.requestFullscreen()
        ).then(updateFullscreenStatus);
    }, [handleMoreMenuCloseIfNeeded, updateFullscreenStatus]);

    const handleShortcuts = useCallback(() => {
        handleMoreMenuCloseIfNeeded();
        setOpenShortcuts(true);
    }, [handleMoreMenuCloseIfNeeded]);

    const handleShortcutsClose = useCallback(() => setOpenShortcuts(false), []);

    // TODO: Unused translation t("convert") - can be removed post the upcoming
    // streaming changes as they'll provides the equiv.

    const shouldIgnoreKeyboardEvent = useCallback(() => {
        // Don't handle keydowns if any of the modals are open.
        return (
            openFileInfo ||
            !!moreMenuAnchorEl ||
            openImageEditor ||
            openConfirmDelete ||
            openShortcuts
        );
    }, [
        openFileInfo,
        moreMenuAnchorEl,
        openImageEditor,
        openConfirmDelete,
        openShortcuts,
    ]);

    const canCopyImage = useCallback(
        () =>
            activeAnnotatedFile?.annotation.showCopyImage &&
            activeAnnotatedFile.itemData.imageURL,
        [activeAnnotatedFile],
    );

    const { isArchived, isPendingToggleArchive, toggleArchived } =
        useMemo(() => {
            let isArchived: boolean | undefined;
            let isPendingToggleArchive: boolean | undefined;
            let toggleArchived: (() => void) | undefined;

            const file = activeAnnotatedFile?.file;

            if (
                pendingVisibilityUpdates &&
                onFileVisibilityUpdate &&
                file &&
                activeAnnotatedFile.annotation.showArchive
            ) {
                switch (fileVisibility(file)) {
                    case undefined:
                    case ItemVisibility.visible:
                        isArchived = false;
                        break;
                    case ItemVisibility.archived:
                        isArchived = true;
                        break;
                }

                isPendingToggleArchive = pendingVisibilityUpdates.has(file.id);

                toggleArchived = () => {
                    handleMoreMenuCloseIfNeeded();
                    void onFileVisibilityUpdate(
                        file,
                        isArchived
                            ? ItemVisibility.visible
                            : ItemVisibility.archived,
                    )
                        .then(handleNeedsRemoteSync)
                        .catch(onGenericError);
                };
            }

            return { isArchived, isPendingToggleArchive, toggleArchived };
        }, [
            pendingVisibilityUpdates,
            onFileVisibilityUpdate,
            onGenericError,
            handleNeedsRemoteSync,
            handleMoreMenuCloseIfNeeded,
            activeAnnotatedFile,
        ]);

    const performKeyAction = useCallback<
        FileViewerPhotoSwipeDelegate["performKeyAction"]
    >(
        (action) => {
            switch (action) {
                case "delete":
                    if (activeAnnotatedFile?.annotation.showDelete)
                        handleConfirmDelete?.();
                    break;
                case "toggle-archive":
                    if (!isPendingToggleArchive) {
                        // Provide extra visual feedback when the toggle archive
                        // action is invoked via a keyboard shortcut since there
                        // is no corresponding screen control visible (the more
                        // menu might not be visible).
                        onVisualFeedback();
                        toggleArchived?.();
                    }
                    break;
                case "copy":
                    if (canCopyImage()) handleCopyImage();
                    break;
                case "toggle-fullscreen":
                    handleToggleFullscreen();
                    break;
                case "help":
                    handleShortcuts();
                    break;
            }
        },
        [
            onVisualFeedback,
            handleConfirmDelete,
            handleCopyImage,
            handleToggleFullscreen,
            handleShortcuts,
            activeAnnotatedFile,
            isPendingToggleArchive,
            toggleArchived,
            canCopyImage,
        ],
    );

    // Initial value of delegate.
    if (!delegateRef.current) {
        delegateRef.current = {
            getFiles,
            isFavorite,
            isFavoritePending,
            toggleFavorite,
            shouldIgnoreKeyboardEvent,
            performKeyAction,
        };
    }

    // Updates to delegate callbacks.
    useEffect(() => {
        const delegate = delegateRef.current!;
        delegate.getFiles = getFiles;
        delegate.isFavorite = isFavorite;
        delegate.isFavoritePending = isFavoritePending;
        delegate.toggleFavorite = toggleFavorite;
        delegate.shouldIgnoreKeyboardEvent = shouldIgnoreKeyboardEvent;
        delegate.performKeyAction = performKeyAction;
    }, [
        getFiles,
        isFavorite,
        isFavoritePending,
        toggleFavorite,
        shouldIgnoreKeyboardEvent,
        performKeyAction,
    ]);

    // Update the active annotated file, if needed, on updates to files or
    // favoriteFileIDs.
    //
    // If the active annotated file is no longer being shown, move to the next
    // slide if possible, or close the viewer otherwise.
    useEffect(() => {
        setActiveAnnotatedFile((af) => {
            // Do nothing if we're not showing a file (we might not be open).
            if (!af) return af;

            if (files.length) {
                const updatedFile = files.find(({ id }) => id == af?.file.id);
                if (updatedFile) {
                    // Modify the active annotated file if we found a file with
                    // the same ID in the (possibly) updated files array.
                    //
                    // Note the omission of the PhotoSwipe refresh: we don't
                    // refresh the PhotoSwipe dialog itself since that would
                    // cause the user to lose their pan / zoom etc.
                    //
                    // This is not correct in its full generality, but it works
                    // fine in the specific cases we would need to handle:
                    //
                    // - In case of delete, we'll not get to this code branch.
                    //
                    // - In case of toggling archive, just updating the file
                    //   attribute is enough, the UI state is derived from it;
                    //   none of the other attributes of the annotated file
                    //   currently depend on the archive status change.
                    af = { ...af, file: updatedFile };
                } else {
                    // Refreshing the current slide after the current file has
                    // gone will show the subsequent slide (since that would've
                    // now moved down to the current index).
                    //
                    // However, we might've been the last slide, in which case
                    // we need to go back one slide first. To determine this,
                    // also pass the expected count of files to our PhotoSwipe
                    // wrapper.
                    psRef.current?.refreshCurrentSlideContent(files.length);
                }
            } else {
                // If there are no more files left, close the viewer.
                handleClose();
            }

            return af;
        });
    }, [handleClose, files]);

    useEffect(() => {
        if (open) {
            psRef.current?.refreshCurrentSlideFavoriteButtonIfNeeded();
        }
    }, [favoriteFileIDs, pendingFavoriteUpdates, open]);

    useEffect(() => {
        if (open) {
            // We're open. Create psRef. This will show the file viewer dialog.
            log.debug(() => "Opening file viewer");

            const pswp = new FileViewerPhotoSwipe({
                initialIndex,
                disableDownload,
                haveUser,
                delegate: delegateRef.current!,
                onClose: () => {
                    if (psRef.current) handleClose();
                },
                onAnnotate: handleAnnotate,
                onViewInfo: handleViewInfo,
                onDownload: handleDownloadBarAction,
                onMore: handleMore,
            });

            psRef.current = pswp;

            return () => {
                // Close dialog in the effect callback.
                log.debug(() => "Closing file viewer");
                pswp.closeIfNeeded();
            };
        } else {
            return undefined;
        }
    }, [
        // Be careful with adding new dependencies here, or changing the source
        // of existing ones. If any of these dependencies change unnecessarily,
        // then the file viewer will start getting reloaded even when it is
        // already open.
        open,
        onClose,
        user,
        initialIndex,
        disableDownload,
        haveUser,
        handleClose,
        handleAnnotate,
        handleViewInfo,
        handleDownloadBarAction,
        handleMore,
    ]);

    const handleUpdateCaption = useCallback((updatedFile: EnteFile) => {
        updateItemDataAlt(updatedFile);
        psRef.current!.refreshCurrentSlideContent();
    }, []);

    useEffect(updateFullscreenStatus, [updateFullscreenStatus]);

    if (!activeAnnotatedFile) {
        return <></>;
    }

    return (
        <>
            <FileInfo
                open={openFileInfo}
                onClose={handleFileInfoClose}
                file={activeAnnotatedFile.file}
                exif={activeFileExif}
                allowEdits={!!activeAnnotatedFile.annotation.isOwnFile}
                allowMap={haveUser}
                showCollections={haveUser && !isInHiddenSection}
                fileCollectionIDs={fileNormalCollectionIDs}
                collectionNameByID={collectionNameByID}
                onNeedsRemoteSync={handleNeedsRemoteSync}
                onUpdateCaption={handleUpdateCaption}
                onSelectCollection={handleSelectCollection}
                onSelectPerson={handleSelectPerson}
            />
            <MoreMenu
                open={!!moreMenuAnchorEl}
                onClose={handleMoreMenuCloseIfNeeded}
                anchorEl={moreMenuAnchorEl}
                id={moreMenuID}
                slotProps={{ list: { "aria-labelledby": moreButtonID } }}
            >
                {activeAnnotatedFile.annotation.showDownload == "menu" && (
                    <MoreMenuItem onClick={handleDownloadMenuAction}>
                        <MoreMenuItemTitle>{t("download")}</MoreMenuItemTitle>
                        <FileDownloadOutlinedIcon />
                    </MoreMenuItem>
                )}
                {activeAnnotatedFile.annotation.showDelete && (
                    <MoreMenuItem onClick={handleConfirmDelete}>
                        <MoreMenuItemTitle>{t("delete")}</MoreMenuItemTitle>
                        <DeleteIcon />
                    </MoreMenuItem>
                )}
                {isArchived !== undefined && (
                    <MoreMenuItem
                        onClick={toggleArchived}
                        disabled={isPendingToggleArchive}
                    >
                        <MoreMenuItemTitle>
                            {isArchived ? t("unarchive") : t("archive")}
                        </MoreMenuItemTitle>
                        {isArchived ? (
                            <UnArchiveIcon />
                        ) : (
                            <ArchiveOutlinedIcon />
                        )}
                    </MoreMenuItem>
                )}
                {canCopyImage() && (
                    <MoreMenuItem onClick={handleCopyImage}>
                        <MoreMenuItemTitle>
                            {t("copy_as_png")}
                        </MoreMenuItemTitle>
                        {/* Tweak icon size to visually fit better with neighbours */}
                        <ContentCopyIcon sx={{ "&&": { fontSize: "18px" } }} />
                    </MoreMenuItem>
                )}
                {activeAnnotatedFile.annotation.showEditImage && (
                    <MoreMenuItem onClick={handleEditImage}>
                        <MoreMenuItemTitle>{t("edit_image")}</MoreMenuItemTitle>
                        <EditIcon />
                    </MoreMenuItem>
                )}
                <MoreMenuItem
                    onClick={handleToggleFullscreen}
                    divider
                    sx={{
                        borderColor: "fixed.dark.divider",
                        /* 12px + 2px */
                        pb: "14px",
                    }}
                >
                    <MoreMenuItemTitle>
                        {isFullscreen
                            ? t("exit_fullscreen")
                            : t("go_fullscreen")}
                    </MoreMenuItemTitle>
                    {isFullscreen ? (
                        <FullscreenExitOutlinedIcon />
                    ) : (
                        <FullscreenOutlinedIcon />
                    )}
                </MoreMenuItem>
                <MoreMenuItem onClick={handleShortcuts} sx={{ mt: "2px" }}>
                    <Typography sx={{ color: "fixed.dark.text.faint" }}>
                        {t("shortcuts")}
                    </Typography>
                </MoreMenuItem>
            </MoreMenu>
            <ConfirmDeleteFileDialog
                open={openConfirmDelete}
                onClose={handleConfirmDeleteClose}
                onConfirm={handleDelete}
            />
            {handleSaveEditedCopy && (
                <ImageEditorOverlay
                    open={openImageEditor}
                    onClose={handleImageEditorClose}
                    file={activeAnnotatedFile.file}
                    onSaveEditedCopy={handleSaveEditedCopy}
                />
            )}
            <Shortcuts
                open={openShortcuts}
                onClose={handleShortcutsClose}
                {...{ disableDownload, haveUser }}
            />
        </>
    );
};

const MoreMenu = styled(Menu)(
    ({ theme }) => `
    & .MuiPaper-root {
        background-color: ${theme.vars.palette.fixed.dark.background.paper};
    }
    & .MuiList-root {
        padding-block: 2px;
    }
`,
);

const MoreMenuItem = styled(MenuItem)(
    ({ theme }) => `
    min-width: 210px;

    /* MUI MenuItem default implementation has a minHeight of "48px" below the
       "sm" breakpoint, and auto after it. We always want the same height, so
       set minHeight auto and use an explicit padding always to come out to 44px
       (20px (icon or Typography height + 12 + 12) */
    padding-block: 12px;
    min-height: auto;

    gap: 1;
    justify-content: space-between;
    align-items: center;

    /* Same as other controls on the PhotoSwipe UI */
    color: rgba(255 255 255 / 0.85);
    &:hover {
        color: rgba(255 255 255 / 1);
        background-color: ${theme.vars.palette.fixed.dark.background.paper2}
    }

    .MuiSvgIcon-root {
        font-size: 20px;
    }
`,
);

const MoreMenuItemTitle: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Typography sx={{ fontWeight: "medium" }}>{children}</Typography>
);

type ConfirmDeleteFileDialogProps = ModalVisibilityProps & {
    /**
     * Called when the user confirms the deletion.
     *
     * The delete button will show an activity indicator until this async
     * operation completes.
     */
    onConfirm: () => Promise<void>;
};

/**
 * A bespoke variant of AttributedMiniDialog for use by the delete file
 * confirmation prompt that we show in the file viewer.
 *
 * - It auto focuses the primary action.
 * - It uses a lighter backdrop in light mode.
 */
const ConfirmDeleteFileDialog: React.FC<ConfirmDeleteFileDialogProps> = ({
    open,
    onClose,
    onConfirm,
}) => {
    const [phase, setPhase] = useState<"loading" | "failed" | undefined>();

    const resetPhaseAndClose = () => {
        setPhase(undefined);
        onClose();
    };

    const handleClick = async () => {
        setPhase("loading");
        try {
            await onConfirm();
            resetPhaseAndClose();
        } catch (e) {
            log.error(e);
            setPhase("failed");
        }
    };

    const handleClose: ModalProps["onClose"] = (_, reason) => {
        // Ignore backdrop clicks when we're processing the user request.
        if (reason == "backdropClick" && phase == "loading") return;
        resetPhaseAndClose();
    };

    return (
        <TitledMiniDialog
            open={open}
            onClose={handleClose}
            title={t("trash_file_title")}
            sx={(theme) => ({
                // See: [Note: Lighter backdrop for overlays on photo viewer]
                ...theme.applyStyles("light", {
                    ".MuiBackdrop-root": {
                        backgroundColor: theme.vars.palette.backdrop.faint,
                    },
                }),
            })}
        >
            <Typography sx={{ color: "text.muted" }}>
                {t("trash_file_message")}
            </Typography>
            <Stack sx={{ pt: 3, gap: 1 }}>
                {phase == "failed" && <InlineErrorIndicator />}
                <LoadingButton
                    loading={phase == "loading"}
                    fullWidth
                    color="critical"
                    autoFocus
                    onClick={handleClick}
                >
                    {t("move_to_trash")}
                </LoadingButton>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    disabled={phase == "loading"}
                    onClick={resetPhaseAndClose}
                >
                    {t("cancel")}
                </FocusVisibleButton>
            </Stack>
        </TitledMiniDialog>
    );
};

type ShortcutsProps = ModalVisibilityProps &
    Pick<FileViewerProps, "disableDownload"> & {
        /**
         * `true` if we're running in a context where there is a logged in user.
         */
        haveUser: boolean;
    };

const Shortcuts: React.FC<ShortcutsProps> = ({
    open,
    onClose,
    disableDownload,
    haveUser,
}) => (
    <Dialog
        {...{ open, onClose }}
        fullWidth
        fullScreen={useIsSmallWidth()}
        slotProps={{ backdrop: { sx: { backdropFilter: "blur(30px)" } } }}
    >
        <SpacedRow sx={{ pt: 2, px: 2.5 }}>
            <DialogTitle>{t("shortcuts")}</DialogTitle>
            <DialogCloseIconButton {...{ onClose }} />
        </SpacedRow>
        <ShortcutsContent>
            <Shortcut action={t("close")} shortcut={ut("Esc")} />
            <Shortcut
                action={formattedListJoin([t("previous"), t("next")])}
                shortcut={
                    // TODO(HLS):
                    shouldUsePlayerV2()
                        ? `${formattedListJoin([ut("←"), ut("→")])} (Option/Alt)`
                        : formattedListJoin([ut("←"), ut("→")])
                }
            />
            {
                /* TODO(HLS): */
                shouldUsePlayerV2() && (
                    <Shortcut
                        action={pt("Video seek")}
                        shortcut={formattedListJoin([ut("←"), ut("→")])}
                    />
                )
            }
            <Shortcut
                action={t("zoom")}
                shortcut={formattedListJoin([t("mouse_scroll"), t("pinch")])}
            />
            <Shortcut
                action={t("zoom_preset")}
                shortcut={formattedListJoin([ut("Z"), t("tap_inside_image")])}
            />
            <Shortcut
                action={t("toggle_controls")}
                shortcut={formattedListJoin([ut("H"), t("tap_outside_image")])}
            />
            <Shortcut
                action={t("pan")}
                shortcut={formattedListJoin([ut("W A S D"), t("drag")])}
            />
            {
                /* TODO(HLS): */
                shouldUsePlayerV2() && (
                    <Shortcut
                        action={pt("Play, Pause")}
                        shortcut={ut("Space")}
                    />
                )
            }
            <Shortcut action={t("toggle_live")} shortcut={ut("Space")} />
            <Shortcut action={t("toggle_audio")} shortcut={ut("M")} />
            {haveUser && (
                <Shortcut action={t("toggle_favorite")} shortcut={ut("L")} />
            )}
            <Shortcut action={t("view_info")} shortcut={ut("I")} />
            {!disableDownload && (
                <Shortcut action={t("download")} shortcut={ut("K")} />
            )}
            {haveUser && (
                <Shortcut
                    action={t("delete")}
                    shortcut={formattedListJoin([
                        ut("Delete"),
                        ut("Backspace"),
                    ])}
                />
            )}
            {haveUser && (
                <Shortcut action={t("toggle_archive")} shortcut={ut("X")} />
            )}
            {!disableDownload && (
                <Shortcut action={t("copy_as_png")} shortcut={ut("^C / ⌘C")} />
            )}
            <Shortcut action={t("toggle_fullscreen")} shortcut={ut("F")} />
            <Shortcut action={t("show_shortcuts")} shortcut={ut("?")} />
        </ShortcutsContent>
    </Dialog>
);

const ShortcutsContent: React.FC<React.PropsWithChildren> = ({ children }) => (
    <DialogContent sx={{ "&&": { pt: 1, pb: 5, px: 5 } }}>
        <ShortcutsTable>
            <tbody>{children}</tbody>
        </ShortcutsTable>
    </DialogContent>
);

const ShortcutsTable = styled("table")`
    border-collapse: separate;
    border-spacing: 0 14px;
`;

interface ShortcutProps {
    action: string;
    shortcut: string;
}

const Shortcut: React.FC<ShortcutProps> = ({ action, shortcut }) => (
    <tr>
        <Typography
            component="td"
            sx={{ color: "text.muted", width: "min(20ch, 40svw)" }}
        >
            {action}
        </Typography>

        <Typography component="td" sx={{ fontWeight: "medium" }}>
            {shortcut}
        </Typography>
    </tr>
);

const fileIsEditableImage = (file: EnteFile) => {
    // Only images are editable.
    if (file.metadata.fileType !== FileType.image) return false;

    const extension = lowercaseExtension(file.metadata.title);
    // Assume it is editable;
    let isRenderable = true;
    if (extension && needsJPEGConversion(extension)) {
        // See if the file is on the whitelist of extensions that we know
        // will not be directly renderable.
        if (!isDesktop) {
            // On the web, we only support HEIC conversion.
            isRenderable = isHEICExtension(extension);
        }
    }
    return isRenderable;
};

/**
 * Return a promise that resolves with a "image/png" blob derived from the given
 * {@link imageURL} that can be written to the navigator's clipboard.
 */
const createImagePNGBlob = async (imageURL: string): Promise<Blob> =>
    new Promise((resolve, reject) => {
        const image = new Image();
        image.onload = () => {
            const canvas = document.createElement("canvas");
            canvas.width = image.width;
            canvas.height = image.height;
            canvas.getContext("2d")!.drawImage(image, 0, 0);
            canvas.toBlob(
                (blob) =>
                    blob ? resolve(blob) : reject(new Error("toBlob failed")),
                "image/png",
            );
        };
        image.onerror = reject;
        image.src = imageURL;
    });
