/* eslint-disable @typescript-eslint/ban-ts-comment */
// @ts-nocheck

// TODO(PS): WIP gallery using upstream photoswipe
//
// Needs (not committed yet):
// yarn workspace gallery add photoswipe@^5.4.4
// mv node_modules/photoswipe packages/new/photos/components/ps5

if (process.env.NEXT_PUBLIC_ENTE_WIP_PS5) {
    console.warn("Using WIP upstream photoswipe");
} else {
    throw new Error("Whoa");
}

import { isDesktop } from "@/base/app";
import { SpacedRow } from "@/base/components/containers";
import { DialogCloseIconButton } from "@/base/components/mui/DialogCloseIconButton";
import { useIsSmallWidth } from "@/base/components/utils/hooks";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "@/base/components/utils/modal";
import { useBaseContext } from "@/base/context";
import { lowercaseExtension } from "@/base/file-name";
import { pt } from "@/base/i18n";
import type { LocalUser } from "@/base/local-user";
import log from "@/base/log";
import {
    FileInfo,
    type FileInfoExif,
    type FileInfoProps,
} from "@/gallery/components/FileInfo";
import type { Collection } from "@/media/collection";
import { FileType } from "@/media/file-type";
import type { EnteFile } from "@/media/file.js";
import { isHEICExtension, needsJPEGConversion } from "@/media/formats";
import { ConfirmDeleteFileDialog } from "@/new/photos/components/FileViewerComponents";
import {
    ImageEditorOverlay,
    type ImageEditorOverlayProps,
} from "@/new/photos/components/ImageEditorOverlay";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import FullscreenExitOutlinedIcon from "@mui/icons-material/FullscreenExitOutlined";
import FullscreenOutlinedIcon from "@mui/icons-material/FullscreenOutlined";
import {
    Box,
    Button,
    Dialog,
    DialogContent,
    DialogTitle,
    Menu,
    MenuItem,
    styled,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import { fileInfoExifForFile, updateItemDataAlt } from "./data-source";
import {
    FileViewerPhotoSwipe,
    moreButtonID,
    moreMenuID,
    resetMoreMenuButtonOnMenuClose,
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
 * A file and its annotation, in a nice cosy box.
 */
export interface FileViewerAnnotatedFile {
    file: EnteFile;
    annotation: FileViewerFileAnnotation;
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
     * If this is not provided then the favorite toggle button will not be shown
     * in the file actions.
     */
    favoriteFileIDs?: Set<number>;
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
     * Called when the favorite status of given {@link file} should be toggled
     * from its current value.
     *
     * If this is not provided then the favorite toggle button will not be shown
     * in the file actions.
     *
     * See also {@link favoriteFileIDs}.
     *
     * See also: [Note: File viewer update and dispatch]
     */
    onToggleFavorite?: (file: EnteFile) => Promise<void>;
    /**
     * Called when the given {@link file} should be downloaded.
     *
     * If this is not provided then the download action will not be shown.
     *
     * See also: [Note: File viewer update and dispatch]
     */
    onDownload?: (file: EnteFile) => void;
    /**
     * Called when the given {@link file} should be deleted.
     *
     * If this is not provided then the delete action will not be shown.
     *
     * See also: [Note: File viewer update and dispatch]
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
        | "fileCollectionIDs"
        | "allCollectionsNameByID"
        | "onSelectCollection"
        | "onSelectPerson"
    >;

/**
 * A PhotoSwipe based image and video viewer.
 */
const FileViewer: React.FC<FileViewerProps> = ({
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
    fileCollectionIDs,
    allCollectionsNameByID,
    onTriggerSyncWithRemote,
    onToggleFavorite,
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

    // With semantics similar to `activeAnnotatedFile`, this is the imageURL
    // associated with the `activeAnnotatedFile`, if any. However, unlike
    // `activeAnnotatedFile`, this is only set when the more menu is activated.
    const [activeImageURL, setActiveImageURL] = useState<string | undefined>(
        undefined,
    );

    const [openFileInfo, setOpenFileInfo] = useState(false);
    const [moreMenuAnchorEl, setMoreMenuAnchorEl] =
        useState<HTMLElement | null>(null);
    const [openImageEditor, setOpenImageEditor] = useState(false);
    const [isFullscreen, setIsFullscreen] = useState(false);

    const { show: showConfirmDelete, props: confirmDeleteVisibilityProps } =
        useModalVisibility();

    const { show: showShortcuts, props: shortcutsVisibilityProps } =
        useModalVisibility();

    // Callbacks to be invoked (only once) the next time we get an update to the
    // `files` or `favoriteFileIDs` props.
    //
    // The callback is passed the latest values of the `files` prop.
    //
    // Both of those trace their way back to the same reducer, so they get
    // updated in tandem. When we delete files, only the `files` prop gets
    // updated, while when we toggle favoriets, only the `favoriteFileIDs` prop
    // gets updated.
    const [, setOnNextFilesOrFavoritesUpdate] = useState<
        ((files: EnteFile[]) => void)[]
    >([]);

    // If `true`, then we need to trigger a sync with remote when we close.
    const [, setNeedsSync] = useState(false);

    /**
     * Add a callback to be fired (only once) the next time we get an update to
     * the `files` prop.
     */
    const awaitNextFilesOrFavoritesUpdate = useCallback(
        (cb: (files: EnteFile[]) => void) =>
            setOnNextFilesOrFavoritesUpdate((cbs) => cbs.concat(cb)),
        [],
    );

    const handleClose = useCallback(() => {
        setNeedsSync((needSync) => {
            if (needSync) onTriggerSyncWithRemote?.();
            return false;
        });
        setOpenFileInfo(false);
        setOpenImageEditor(false);
        // No need to `resetMoreMenuButtonOnMenuClose` since we're closing
        // anyway and it'll be removed from the DOM.
        setMoreMenuAnchorEl(null);
        onClose();
    }, [onTriggerSyncWithRemote, onClose]);

    const handleViewInfo = useCallback(
        (annotatedFile: FileViewerAnnotatedFile) => {
            setActiveAnnotatedFile(annotatedFile);
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
            setActiveAnnotatedFile(annotatedFile);
            onDownload!(annotatedFile.file);
        },
        [onDownload],
    );

    // Callback invoked when the download action is triggered by activating the
    // download menu item in the more menu.
    //
    // Not memoized since it uses the frequently changing `activeAnnotatedFile`.
    const handleDownloadMenuAction = () => {
        handleMoreMenuClose();
        onDownload!(activeAnnotatedFile!.file);
    };

    const handleMore = useCallback(
        (
            annotatedFile: FileViewerAnnotatedFile,
            imageURL: string | undefined,
            buttonElement: HTMLElement,
        ) => {
            setActiveAnnotatedFile(annotatedFile);
            setActiveImageURL(imageURL);
            setMoreMenuAnchorEl(buttonElement);
        },
        [],
    );

    const handleMoreMenuClose = useCallback(() => {
        setMoreMenuAnchorEl((el) => {
            resetMoreMenuButtonOnMenuClose(el);
            return null;
        });
    }, []);

    const handleConfirmDelete = useMemo(() => {
        return onDelete
            ? () => {
                  handleMoreMenuClose();
                  showConfirmDelete();
              }
            : undefined;
    }, [onDelete, showConfirmDelete, handleMoreMenuClose]);

    // Not memoized since it uses the frequently changing `activeAnnotatedFile`.
    const handleDelete = async () => {
        const file = activeAnnotatedFile!.file;
        await onDelete(file);
        // [Note: File viewer update and dispatch]
        //
        // This relies on the assumption that `onDelete` will asynchronously
        // result in updates to the `files` prop. Currently that indeed is what
        // happens as the last call in the `onDelete` implementation is a call
        // to a dispatcher, but we need to be careful about preserving this
        // assumption when changing `onDelete` implementation in the future.
        awaitNextFilesOrFavoritesUpdate((files: EnteFile[]) => {
            handleNeedsRemoteSync();
            if (files.length) {
                // Refreshing the current slide after the current file has gone
                // will show the subsequent slide (since that would've now moved
                // down to the current index).
                psRef.current!.refreshCurrentSlideContent();
            } else {
                // If there are no more files left, close the viewer.
                handleClose();
            }
        });
    };

    // Not memoized since it uses the frequently changing `activeAnnotatedFile`.
    const handleCopyImage = () => {
        handleMoreMenuClose();
        // Safari does not copy if we do not call `navigator.clipboard.write`
        // synchronously within the click event handler, but it does supports
        // passing a promise in lieu of the blob.
        void window.navigator.clipboard
            .write([
                new ClipboardItem({
                    "image/png": createImagePNGBlob(activeImageURL!),
                }),
            ])
            .catch(onGenericError);
    };

    const handleEditImage = useMemo(() => {
        return onSaveEditedImageCopy
            ? () => {
                  handleMoreMenuClose();
                  setOpenImageEditor(true);
              }
            : undefined;
    }, [onSaveEditedImageCopy, handleMoreMenuClose]);

    const handleImageEditorClose = useCallback(
        () => setOpenImageEditor(false),
        [],
    );

    const handleSaveEditedCopy = useCallback(
        (editedFile: File, collection: Collection, enteFile: EnteFile) => {
            onSaveEditedImageCopy(editedFile, collection, enteFile);
            handleClose();
        },
        [onSaveEditedImageCopy, handleClose],
    );

    const handleAnnotate = useCallback(
        (file: EnteFile): FileViewerFileAnnotation => {
            const fileID = file.id;
            const isOwnFile = file.ownerID == user?.id;

            const canModify =
                isOwnFile && !isInTrashSection && !isInHiddenSection;

            const showFavorite = canModify;

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
                switch (file.metadata.fileType) {
                    case FileType.image:
                    case FileType.livePhoto:
                        return true;
                    default:
                        return false;
                }
            })();

            return {
                fileID,
                isOwnFile,
                showFavorite,
                showDownload,
                showDelete,
                showCopyImage,
                showEditImage,
            };
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

    const handleNeedsRemoteSync = useCallback(() => setNeedsSync(true), []);

    const handleSelectCollection = useCallback(
        (collectionID: number) => {
            onSelectCollection(collectionID);
            handleClose();
        },
        [onSelectCollection, handleClose],
    );

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
            if (!haveUser || !favoriteFileIDs || !onToggleFavorite) {
                return undefined;
            }
            return favoriteFileIDs.has(file.id);
        },
        [haveUser, favoriteFileIDs, onToggleFavorite],
    );

    const toggleFavorite = useCallback(
        ({ file }: FileViewerAnnotatedFile) => {
            return new Promise((resolve) => {
                // See: [Note: File viewer update and dispatch]
                onToggleFavorite!(file)
                    .then(
                        () => awaitNextFilesOrFavoritesUpdate(resolve),
                        (e: unknown) => {
                            onGenericError(e);
                            resolve();
                        },
                    )
                    .finally(handleNeedsRemoteSync);
            });
        },
        [
            onToggleFavorite,
            onGenericError,
            awaitNextFilesOrFavoritesUpdate,
            handleNeedsRemoteSync,
        ],
    );

    const updateFullscreenStatus = useCallback(() => {
        setIsFullscreen(!!document.fullscreenElement);
    }, []);

    const handleToggleFullscreen = useCallback(() => {
        handleMoreMenuClose();
        void (
            document.fullscreenElement
                ? document.exitFullscreen()
                : document.body.requestFullscreen()
        ).then(updateFullscreenStatus);
    }, [handleMoreMenuClose, updateFullscreenStatus]);

    const handleShortcuts = useCallback(() => {
        handleMoreMenuClose();
        showShortcuts();
    }, [handleMoreMenuClose, showShortcuts]);

    // Initial value of delegate.
    if (!delegateRef.current) {
        delegateRef.current = { getFiles, isFavorite, toggleFavorite };
    }

    // Updates to delegate callbacks.
    useEffect(() => {
        const delegate = delegateRef.current!;
        delegate.getFiles = getFiles;
        delegate.isFavorite = isFavorite;
        delegate.toggleFavorite = toggleFavorite;
    }, [getFiles, isFavorite, toggleFavorite]);

    // Notify the listeners, if any, for updates to files or favorites.
    useEffect(() => {
        setOnNextFilesOrFavoritesUpdate((cbs) => {
            cbs.forEach((cb) => cb(files));
            return [];
        });
    }, [files, favoriteFileIDs]);

    useEffect(() => {
        if (open) {
            // We're open. Create psRef. This will show the file viewer dialog.
            log.debug(() => ["viewer", { action: "open" }]);

            const pswp = new FileViewerPhotoSwipe({
                initialIndex,
                disableDownload,
                haveUser,
                delegate: delegateRef.current!,
                onClose: handleClose,
                onAnnotate: handleAnnotate,
                onViewInfo: handleViewInfo,
                onDownload: handleDownloadBarAction,
                onMore: handleMore,
            });

            psRef.current = pswp;

            return () => {
                // Close dialog in the effect callback.
                log.debug(() => ["viewer", { action: "close" }]);
                pswp.closeIfNeeded();
            };
        }
    }, [
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

    log.debug(() => ["viewer", { action: "render", psRef: psRef.current }]);

    return (
        <Container>
            <Button>Test</Button>
            <FileInfo
                open={openFileInfo}
                onClose={handleFileInfoClose}
                file={activeAnnotatedFile?.file}
                exif={activeFileExif}
                allowEdits={!!activeAnnotatedFile?.annotation.isOwnFile}
                allowMap={haveUser}
                showCollections={haveUser}
                onNeedsRemoteSync={handleNeedsRemoteSync}
                onUpdateCaption={handleUpdateCaption}
                onSelectCollection={handleSelectCollection}
                onSelectPerson={handleSelectPerson}
                {...{ fileCollectionIDs, allCollectionsNameByID }}
            />
            <MoreMenu
                open={!!moreMenuAnchorEl}
                onClose={handleMoreMenuClose}
                anchorEl={moreMenuAnchorEl}
                id={moreMenuID}
                slotProps={{
                    list: { "aria-labelledby": moreButtonID },
                }}
            >
                {activeAnnotatedFile?.annotation.showDownload == "menu" && (
                    <MoreMenuItem onClick={handleDownloadMenuAction}>
                        <MoreMenuItemTitle>
                            {/*TODO */ t("download")}
                        </MoreMenuItemTitle>
                        <FileDownloadOutlinedIcon />
                    </MoreMenuItem>
                )}
                {activeAnnotatedFile?.annotation.showDelete && (
                    <MoreMenuItem onClick={handleConfirmDelete}>
                        <MoreMenuItemTitle>
                            {/*TODO */ t("delete")}
                        </MoreMenuItemTitle>
                        <DeleteIcon />
                    </MoreMenuItem>
                )}
                {activeAnnotatedFile?.annotation.showCopyImage &&
                    activeImageURL && (
                        <MoreMenuItem onClick={handleCopyImage}>
                            <MoreMenuItemTitle>
                                {/*TODO */ pt("Copy as PNG")}
                            </MoreMenuItemTitle>
                            {/* Tweak icon size to visually fit better with neighbours */}
                            <ContentCopyIcon
                                sx={{ "&&": { fontSize: "18px" } }}
                            />
                        </MoreMenuItem>
                    )}
                {activeAnnotatedFile?.annotation.showEditImage && (
                    <MoreMenuItem onClick={handleEditImage}>
                        <MoreMenuItemTitle>
                            {/*TODO */ pt("Edit image")}
                        </MoreMenuItemTitle>
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
                        {
                            /*TODO */ isFullscreen
                                ? pt("Exit fullscreen")
                                : pt("Go fullscreen")
                        }
                    </MoreMenuItemTitle>
                    {isFullscreen ? (
                        <FullscreenExitOutlinedIcon />
                    ) : (
                        <FullscreenOutlinedIcon />
                    )}
                </MoreMenuItem>
                <MoreMenuItem onClick={handleShortcuts} sx={{ mt: "2px" }}>
                    <Typography sx={{ color: "fixed.dark.text.faint" }}>
                        {pt("Shortcuts")}
                    </Typography>
                </MoreMenuItem>
            </MoreMenu>
            {/* TODO(PS): Fix imports */}
            <ConfirmDeleteFileDialog
                {...confirmDeleteVisibilityProps}
                onConfirm={handleDelete}
            />
            <ImageEditorOverlay
                open={openImageEditor}
                onClose={handleImageEditorClose}
                file={activeAnnotatedFile?.file}
                onSaveEditedCopy={handleSaveEditedCopy}
            />
            <Shortcuts {...shortcutsVisibilityProps} />
        </Container>
    );
};

export default FileViewer;

const Container = styled("div")`
    border: 1px solid red;

    #test-gallery {
        border: 1px solid red;
        min-height: 10px;
    }
`;

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

const Shortcuts: React.FC<ModalVisibilityProps> = ({ open, onClose }) => (
    <Dialog
        {...{ open, onClose }}
        fullWidth
        fullScreen={useIsSmallWidth()}
        slotProps={{ backdrop: { sx: { backdropFilter: "blur(30px)" } } }}
    >
        <SpacedRow sx={{ pt: 2, px: 2.5 }}>
            <DialogTitle>{pt("Shortcuts")}</DialogTitle>
            <DialogCloseIconButton {...{ onClose }} />
        </SpacedRow>
        <ShortcutsContent sx={{ "&&": { pt: 2, pb: 5, px: 5 } }}>
            <Shortcut action="Close" shortcut="Esc" />
            <Shortcut action="Previous, Next" shortcut="←, →" />
            <Shortcut action="Zoom" shortcut="Mouse scroll" />
            <Shortcut action="Zoom preset" shortcut="Tap inside image" />
            <Shortcut action="Toggle controls" shortcut="Tap outside image" />
            <Shortcut action="Toggle favorite" shortcut="L" />
            <Shortcut action="View info" shortcut="I" />
            <Shortcut action="Download" shortcut="D" />
            <Shortcut action="Delete" shortcut="Delete, Backspace" />
            <Shortcut action="Copy as PNG" shortcut="^C, ⌘C" />
            <Shortcut action="Toggle fullscreen" shortcut="F" />
        </ShortcutsContent>
    </Dialog>
);

const ShortcutsContent = styled(DialogContent)`
    display: flex;
    flex-direction: column;
    gap: 16px;
`;

interface ShortcutProps {
    action: string;
    shortcut: string;
}

const Shortcut: React.FC<ShortcutProps> = ({ action, shortcut }) => (
    <Box sx={{ display: "flex", gap: 2 }}>
        <Typography sx={{ color: "text.muted", minWidth: "min(20ch, 40svw)" }}>
            {action}
        </Typography>
        <Typography sx={{ fontWeight: "medium" }}>{shortcut}</Typography>
    </Box>
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
const createImagePNGBlob = async (imageURL: string) =>
    new Promise((resolve, reject) => {
        const image = new Image();
        image.onload = () => {
            const canvas = document.createElement("canvas");
            canvas.width = image.width;
            canvas.height = image.height;
            canvas.getContext("2d").drawImage(image, 0, 0);
            canvas.toBlob(resolve, "image/png");
        };
        image.onerror = reject;
        image.src = imageURL;
    });
