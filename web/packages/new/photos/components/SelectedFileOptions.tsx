import ClockIcon from "@mui/icons-material/AccessTime";
import AddIcon from "@mui/icons-material/Add";
import ArchiveIcon from "@mui/icons-material/ArchiveOutlined";
import MoveIcon from "@mui/icons-material/ArrowForward";
import CloseIcon from "@mui/icons-material/Close";
import DeleteIcon from "@mui/icons-material/Delete";
import DownloadIcon from "@mui/icons-material/Download";
import FavoriteBorderIcon from "@mui/icons-material/FavoriteBorderRounded";
import RemoveIcon from "@mui/icons-material/RemoveCircleOutline";
import RestoreIcon from "@mui/icons-material/Restore";
import UnArchiveIcon from "@mui/icons-material/Unarchive";
import VisibilityOffOutlinedIcon from "@mui/icons-material/VisibilityOffOutlined";
import VisibilityOutlinedIcon from "@mui/icons-material/VisibilityOutlined";
import { IconButton, Tooltip, Typography } from "@mui/material";
import { SpacedRow } from "ente-base/components/containers";
import type { ButtonishProps } from "ente-base/components/mui";
import { useBaseContext } from "ente-base/context";
import type { Collection } from "ente-media/collection";
import type { CollectionSelectorAttributes } from "ente-new/photos/components/CollectionSelector";
import type { GalleryBarMode } from "ente-new/photos/components/gallery/reducer";
import {
    PseudoCollectionID,
    type CollectionSummary,
} from "ente-new/photos/services/collection-summary";
import { t } from "i18next";

/**
 * Operations on selected files.
 */
export type FileOp =
    | "download"
    | "fixTime"
    | "favorite"
    | "archive"
    | "unarchive"
    | "hide"
    | "trash"
    | "deletePermanently";

/**
 * Operations on selected files that also have an associated collection.
 */
export type CollectionOp = "add" | "move" | "restore" | "unhide";

interface SelectedFileOptionsProps {
    barMode?: GalleryBarMode;
    isInSearchMode: boolean;
    selectedCollection?: Collection;
    /**
     * If {@link collectionSummary} is set and is not a pseudo-collection, then
     * this will be set to the corresponding {@link Collection}.
     */
    collection: Collection | undefined;
    /**
     * The collection summary in whose context the selection happened.
     *
     * This will not be set if we are in the people section, or if we are
     * showing search results.
     */
    collectionSummary: CollectionSummary | undefined;
    /**
     * The total number of files selected by the user.
     */
    selectedFileCount: number;
    /**
     * The subset of {@link selectedFileCount} that are also owned by the user.
     */
    selectedOwnFileCount: number;
    /**
     * Called when the user clears the selection by pressing the cancel button
     * on the selection bar.
     */
    onClearSelection: () => void;
    /**
     * Called when the user wants to remove the selected files from the given
     * {@link collection}.
     */
    onRemoveFilesFromCollection: (collection: Collection) => void;
    /**
     * Callback to open a dialog where the user can choose a collection.
     *
     * The reason for opening the dialog and other properties are passed as the
     * {@link attributes} argument.
     */
    onOpenCollectionSelector: (
        attributes: CollectionSelectorAttributes,
    ) => void;
    /**
     * A function called to obtain a new album creation handler for the provided
     * {@link op}.
     *
     * This function will be passed the operation to be be performed. It will
     * return a new function G can be used as the {@link onCreateCollection}
     * attribute for {@link onOpenCollectionSelector}.
     *
     * Once the user enters the name and a new album with that name gets
     * created, the newly created collection will be passed to G.
     *
     * @param op The operation that should be performed on the selected files
     * using the newly created collection.
     *
     * @returns A function that can be called with to create a new collection
     * and then perform {@link op} on successful creation of the new collection.
     */
    createOnCreateForCollectionOp: (op: CollectionOp) => () => void;
    /**
     * A function called to obtain an existing album selection handler for the
     * provided {@link op}.
     *
     * This function will be passed the operation to be be performed. It will
     * return a new function G can be used as the {@link onSelectCollection}
     * attribute for {@link onOpenCollectionSelector}.
     *
     * Once the user selects a collection, then the selected collection will be
     * passed to G.
     *
     * @param op The operation that should be performed on the selected files,
     * using the selected collection.
     *
     * @returns A function that can be called with a selected collection.
     */
    createOnSelectForCollectionOp: (
        op: CollectionOp,
    ) => (selectedCollection: Collection) => void;
    /**
     * A function called to obtain a handler for the provided {@link op}.
     *
     * This function will be passed the file operation to be performed. It will
     * return a new function G that can be used as a {@link onClick} handler for
     * the button. Calling G will trigger the operation on the selected files.
     *
     * @param op The operation that should be performed on the selected files.
     * @returns
     */
    createFileOpHandler: (op: FileOp) => () => void;
}

/**
 * The selection bar shown at the top of the viewport when the user has selected
 * one or more files in the photos app gallery.
 */
export const SelectedFileOptions: React.FC<SelectedFileOptionsProps> = ({
    barMode,
    isInSearchMode,
    collection,
    collectionSummary,
    selectedFileCount,
    selectedOwnFileCount,
    onClearSelection,
    onRemoveFilesFromCollection,
    onOpenCollectionSelector,
    createOnCreateForCollectionOp,
    createOnSelectForCollectionOp,
    createFileOpHandler,
}) => {
    const { showMiniDialog } = useBaseContext();

    const isUserFavorites =
        !!collectionSummary?.attributes.has("userFavorites");

    const handleFavorite = createFileOpHandler("favorite");

    const handleFixTime = createFileOpHandler("fixTime");

    const handleDownload = createFileOpHandler("download");

    const handleArchive = createFileOpHandler("archive");

    const handleUnarchive = createFileOpHandler("unarchive");

    const handleDelete = () =>
        showMiniDialog({
            title: t("trash_files_title"),
            message: t("trash_files_message"),
            continue: {
                text: t("move_to_trash"),
                color: "critical",
                action: createFileOpHandler("trash"),
            },
        });

    const handleRestore = () =>
        onOpenCollectionSelector({
            action: "restore",
            onCreateCollection: createOnCreateForCollectionOp("restore"),
            onSelectCollection: createOnSelectForCollectionOp("restore"),
        });

    const handleDeletePermanently = () =>
        showMiniDialog({
            title: t("delete_files_title"),
            message: t("delete_files_message"),
            continue: {
                text: t("delete"),
                color: "critical",
                action: createFileOpHandler("deletePermanently"),
            },
        });

    const handleAddToCollection = () =>
        onOpenCollectionSelector({
            action: "add",
            sourceCollectionSummaryID: collectionSummary?.id,
            onCreateCollection: createOnCreateForCollectionOp("add"),
            onSelectCollection: createOnSelectForCollectionOp("add"),
        });

    const handleRemoveFromCollection = () => {
        const remove = () => onRemoveFilesFromCollection(collection!);

        if (collectionSummary?.attributes.has("sharedIncoming")) {
            remove();
        } else {
            const onlyUserFiles = selectedFileCount == selectedOwnFileCount;
            showMiniDialog({
                title: t("remove_from_album"),
                message: onlyUserFiles
                    ? t("confirm_remove_message")
                    : t("confirm_remove_incl_others_message"),
                continue: {
                    text: t("yes_remove"),
                    color: onlyUserFiles ? "primary" : "critical",
                    action: remove,
                },
            });
        }
    };

    const handleMoveToCollection = () => {
        onOpenCollectionSelector({
            action: "move",
            sourceCollectionSummaryID: collectionSummary?.id,
            onCreateCollection: createOnCreateForCollectionOp("move"),
            onSelectCollection: createOnSelectForCollectionOp("move"),
        });
    };

    const handleHide = createFileOpHandler("hide");

    const handleUnhide = () => {
        onOpenCollectionSelector({
            action: "unhide",
            onCreateCollection: createOnCreateForCollectionOp("unhide"),
            onSelectCollection: createOnSelectForCollectionOp("unhide"),
        });
    };

    return (
        <SpacedRow sx={{ flex: 1, gap: 1, flexWrap: "wrap" }}>
            <IconButton onClick={onClearSelection}>
                <CloseIcon />
            </IconButton>
            <Typography sx={{ mr: "auto" }}>
                {selectedFileCount == selectedOwnFileCount
                    ? t("selected_count", { selected: selectedFileCount })
                    : t("selected_and_yours_count", {
                          selected: selectedFileCount,
                          yours: selectedOwnFileCount,
                      })}
            </Typography>

            {isInSearchMode ? (
                <>
                    <FavoriteButton onClick={handleFavorite} />
                    <FixTimeButton onClick={handleFixTime} />
                    <DownloadButton onClick={handleDownload} />
                    <AddToCollectionButton onClick={handleAddToCollection} />
                    <ArchiveButton onClick={handleArchive} />
                    <HideButton onClick={handleHide} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : barMode == "people" ? (
                <>
                    <FavoriteButton onClick={handleFavorite} />
                    <DownloadButton onClick={handleDownload} />
                    <AddToCollectionButton onClick={handleAddToCollection} />
                    <ArchiveButton onClick={handleArchive} />
                    <HideButton onClick={handleHide} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : collectionSummary?.id == PseudoCollectionID.trash ? (
                <>
                    <RestoreButton onClick={handleRestore} />
                    <DeletePermanentlyButton
                        onClick={handleDeletePermanently}
                    />
                </>
            ) : collectionSummary?.attributes.has("uncategorized") ? (
                <>
                    <DownloadButton onClick={handleDownload} />
                    <MoveToCollectionButton onClick={handleMoveToCollection} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : collectionSummary?.attributes.has("sharedIncoming") ? (
                <>
                    <DownloadButton onClick={handleDownload} />
                    <RemoveFromCollectionButton
                        onClick={handleRemoveFromCollection}
                    />
                </>
            ) : barMode == "hidden-albums" ? (
                <>
                    <DownloadButton onClick={handleDownload} />
                    <UnhideButton onClick={handleUnhide} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : (
                <>
                    {!isUserFavorites &&
                        collectionSummary?.id !=
                            PseudoCollectionID.archiveItems && (
                            <FavoriteButton onClick={handleFavorite} />
                        )}
                    <FixTimeButton onClick={handleFixTime} />
                    <DownloadButton onClick={handleDownload} />
                    <AddToCollectionButton onClick={handleAddToCollection} />
                    {collectionSummary?.id === PseudoCollectionID.all ? (
                        <ArchiveButton onClick={handleArchive} />
                    ) : collectionSummary?.id ==
                      PseudoCollectionID.archiveItems ? (
                        <UnarchiveButton onClick={handleUnarchive} />
                    ) : (
                        !isUserFavorites && (
                            <>
                                <MoveToCollectionButton
                                    onClick={handleMoveToCollection}
                                />
                                <RemoveFromCollectionButton
                                    onClick={handleRemoveFromCollection}
                                />
                            </>
                        )
                    )}
                    <HideButton onClick={handleHide} />
                    <DeleteButton onClick={handleDelete} />
                </>
            )}
        </SpacedRow>
    );
};

const DownloadButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("download")}>
        <IconButton {...{ onClick }}>
            <DownloadIcon />
        </IconButton>
    </Tooltip>
);

const FavoriteButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("favorite")}>
        <IconButton {...{ onClick }}>
            <FavoriteBorderIcon />
        </IconButton>
    </Tooltip>
);

const ArchiveButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("archive")}>
        <IconButton {...{ onClick }}>
            <ArchiveIcon />
        </IconButton>
    </Tooltip>
);

const UnarchiveButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("unarchive")}>
        <IconButton {...{ onClick }}>
            <UnArchiveIcon />
        </IconButton>
    </Tooltip>
);

const HideButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("hide")}>
        <IconButton {...{ onClick }}>
            <VisibilityOffOutlinedIcon />
        </IconButton>
    </Tooltip>
);

const UnhideButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("unhide")}>
        <IconButton {...{ onClick }}>
            <VisibilityOutlinedIcon />
        </IconButton>
    </Tooltip>
);

const DeleteButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("delete")}>
        <IconButton {...{ onClick }}>
            <DeleteIcon />
        </IconButton>
    </Tooltip>
);

const RestoreButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("restore")}>
        <IconButton {...{ onClick }}>
            <RestoreIcon />
        </IconButton>
    </Tooltip>
);

const DeletePermanentlyButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("delete_permanently")}>
        <IconButton {...{ onClick }}>
            <DeleteIcon />
        </IconButton>
    </Tooltip>
);

const FixTimeButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("fix_creation_time")}>
        <IconButton {...{ onClick }}>
            <ClockIcon />
        </IconButton>
    </Tooltip>
);

const AddToCollectionButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("add")}>
        <IconButton {...{ onClick }}>
            <AddIcon />
        </IconButton>
    </Tooltip>
);

const MoveToCollectionButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("move")}>
        <IconButton {...{ onClick }}>
            <MoveIcon />
        </IconButton>
    </Tooltip>
);

const RemoveFromCollectionButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("remove")}>
        <IconButton {...{ onClick }}>
            <RemoveIcon />
        </IconButton>
    </Tooltip>
);
