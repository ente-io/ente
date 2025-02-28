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
import { type ModalVisibilityProps } from "@/base/components/utils/modal";
import { useBaseContext } from "@/base/context";
import { lowercaseExtension } from "@/base/file-name";
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
import {
    ImageEditorOverlay,
    type ImageEditorOverlayProps,
} from "@/new/photos/components/ImageEditorOverlay";
import { Button, styled } from "@mui/material";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { fileInfoExifForFile } from "./data-source";
import {
    FileViewerPhotoSwipe,
    type FileViewerAnnotatedFile,
    type FileViewerFileAnnotation,
    type FileViewerPhotoSwipeDelegate,
} from "./photoswipe";

// TODO
// import {
//     addToFavorites,
//     removeFromFavorites,
// } from "apps/photos/services/collectionService";
// import { wait } from "@/utils/promise";
// const addToFavorites = async (file: EnteFile) => {
//     console.log(file);
//     await wait(3000);
//     throw new Error("test");
// };
// const removeFromFavorites = addToFavorites;

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
     * `true` when we are viewing files in the Trash.
     */
    isInTrashSection?: boolean;
    /**
     * `true` when we are viewing files in the hidden section.
     */
    isInHiddenSection?: boolean;
    /**
     * If true then the viewer does not show controls for downloading the file.
     */
    disableDownload?: boolean;
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
    isInTrashSection,
    isInHiddenSection,
    disableDownload,
    favoriteFileIDs,
    fileCollectionIDs,
    allCollectionsNameByID,
    onTriggerSyncWithRemote,
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
    const [openImageEditor, setOpenImageEditor] = useState(false);

    // If `true`, then we need to trigger a sync with remote when we close.
    const [, setNeedsSync] = useState(false);

    const handleClose = useCallback(() => {
        setNeedsSync((needSync) => {
            if (needSync) onTriggerSyncWithRemote?.();
            return false;
        });
        setOpenFileInfo(false);
        setOpenImageEditor(false);
        onClose();
    }, [onTriggerSyncWithRemote, onClose]);

    const handleAnnotate = useCallback(
        (file: EnteFile): FileViewerFileAnnotation => {
            log.debug(() => ["viewer", { action: "annotate", file }]);
            const fileID = file.id;
            const isOwnFile = file.ownerID == user?.id;
            const canModify =
                isOwnFile && !isInTrashSection && !isInHiddenSection;
            const showFavorite = canModify;
            const isEditableImage =
                onSaveEditedImageCopy && canModify
                    ? fileIsEditableImage(file)
                    : undefined;
            return { fileID, isOwnFile, showFavorite, isEditableImage };
        },
        [user, isInTrashSection, isInHiddenSection, onSaveEditedImageCopy],
    );

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

    const handleInfoClose = useCallback(() => setOpenFileInfo(false), []);

    const handleScheduleUpdate = useCallback(() => setNeedsSync(true), []);

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

    const handleEditImage = useMemo(() => {
        return onSaveEditedImageCopy
            ? (annotatedFile: FileViewerAnnotatedFile) => {
                  setActiveAnnotatedFile(annotatedFile);
                  setOpenImageEditor(true);
              }
            : undefined;
    }, [onSaveEditedImageCopy]);

    const handleImageEditorClose = useCallback(
        () => setOpenImageEditor(false),
        [],
    );

    const handleSaveEditedCopy = useCallback(
        (editedFile: File, collection: Collection, enteFile: EnteFile) => {
            onSaveEditedImageCopy(editedFile, collection, enteFile);
            handleImageEditorClose();
            handleClose();
        },
        [onSaveEditedImageCopy, handleImageEditorClose, handleClose],
    );

    const haveUser = !!user;
    const showModifyActions = haveUser;

    const getFiles = useCallback(() => files, [files]);

    const isFavorite = useCallback(
        ({ file }: FileViewerAnnotatedFile) => {
            if (!showModifyActions || !favoriteFileIDs) return undefined;
            return favoriteFileIDs.has(file.id);
        },
        [showModifyActions, favoriteFileIDs],
    );

    const toggleFavorite = useCallback(
        async ({ file, annotation }: FileViewerAnnotatedFile) => {
            if (!showModifyActions || !favoriteFileIDs)
                throw new Error("Unexpected invocation");

            try {
                await new Promise((r) => setTimeout(r, 3000));
                throw new Error("test");
            } catch (e) {
                onGenericError(e);
            }
            console.log({ file, annotation });
            // TODO
            //   const isFavorite = annotation.isFavorite;
            //   if (isFavorite === undefined) {
            //       assertionFailed();
            //       return;
            //   }

            //   onMarkUnsyncedFavoriteUpdate(file.id, !isFavorite);
            //   void (isFavorite ? removeFromFavorites : addToFavorites)(
            //       file,
            //   ).catch((e: unknown) => {
            //       log.error("Failed to remove favorite", e);
            //       onMarkUnsyncedFavoriteUpdate(file.id, undefined);
            //   });
        },
        [showModifyActions, onGenericError, favoriteFileIDs],
    );

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

    useEffect(() => {
        if (open) {
            // We're open. Create psRef. This will show the file viewer dialog.
            log.debug(() => ["viewer", { action: "open" }]);

            const pswp = new FileViewerPhotoSwipe({
                initialIndex,
                disableDownload,
                showModifyActions,
                delegate: delegateRef.current!,
                onClose: handleClose,
                onAnnotate: handleAnnotate,
                onViewInfo: handleViewInfo,
                onEditImage: handleEditImage,
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
        showModifyActions,
        handleClose,
        handleAnnotate,
        handleViewInfo,
        handleEditImage,
    ]);

    const handleRefreshPhotoswipe = useCallback(() => {
        psRef.current!.refreshCurrentSlideContent();
    }, []);

    log.debug(() => ["viewer", { action: "render", psRef: psRef.current }]);

    return (
        <Container>
            <Button>Test</Button>
            <FileInfo
                open={openFileInfo}
                onClose={handleInfoClose}
                file={activeAnnotatedFile?.file}
                exif={activeFileExif}
                allowEdits={!!activeAnnotatedFile?.annotation.isOwnFile}
                allowMap={haveUser}
                showCollections={haveUser}
                scheduleUpdate={handleScheduleUpdate}
                refreshPhotoswipe={handleRefreshPhotoswipe}
                onSelectCollection={handleSelectCollection}
                onSelectPerson={handleSelectPerson}
                {...{ fileCollectionIDs, allCollectionsNameByID }}
            />
            <ImageEditorOverlay
                open={openImageEditor}
                onClose={handleImageEditorClose}
                file={activeAnnotatedFile?.file}
                onSaveEditedCopy={handleSaveEditedCopy}
            />
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
