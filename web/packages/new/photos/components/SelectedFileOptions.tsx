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

export type CollectionOp = "add" | "move" | "remove" | "restore" | "unhide";

export type FileOp =
    | "download"
    | "fixTime"
    | "favorite"
    | "archive"
    | "unarchive"
    | "hide"
    | "trash"
    | "deletePermanently";

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
     *
     * TODO: Need to implement delete-equivalent from shared albums.
     *
     * Notes:
     *
     * - Delete action should not be enabled  3 selected (0 Yours). There should
     *   be separate remove action.
     *
     * - On remove, if the file and collection both belong to current user, we
     *   just use move api to existing or uncat collection.
     *
     * - Otherwise, we call /collections/v3/remove-files (when collection and
     *   file belong to different users).
     *
     * - Album owner can remove files of all other users from their collection.
     *   Particiapant (viewer/collaborator) can only remove files that belong to
     *   them.
     *
     * Also note that that user cannot delete files that are not owned by the
     * user, even if they are in an album owned by the user.
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
     * Called when an operation requires prompting the user to create a new
     * collection (e.g. adding to a new album).
     *
     * The callback is also passed the operation that caused it to be shown.
     */
    onShowCreateCollectionModal: (op: CollectionOp) => () => void;
    /**
     * Callback to open a dialog where the user can choose a collection.
     *
     * The reason for opening the dialog and other properties are passed as the
     * {@link attributes} argument.
     */
    onOpenCollectionSelector: (
        attributes: CollectionSelectorAttributes,
    ) => void;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    handleCollectionOp: (op: CollectionOp) => (...args: any[]) => void;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    handleFileOp: (op: FileOp) => (...args: any[]) => void;
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
    onShowCreateCollectionModal,
    onOpenCollectionSelector,
    handleCollectionOp,
    handleFileOp,
}) => {
    const { showMiniDialog } = useBaseContext();

    const isUserFavorites =
        !!collectionSummary?.attributes.has("userFavorites");

    const handleUnhide = () => {
        onOpenCollectionSelector({
            action: "unhide",
            onSelectCollection: handleCollectionOp("unhide"),
            onCreateCollection: onShowCreateCollectionModal("unhide"),
        });
    };

    const handleDelete = () =>
        showMiniDialog({
            title: t("trash_files_title"),
            message: t("trash_files_message"),
            continue: {
                text: t("move_to_trash"),
                color: "critical",
                action: handleFileOp("trash"),
            },
        });

    const handleRestore = () =>
        onOpenCollectionSelector({
            action: "restore",
            onSelectCollection: handleCollectionOp("restore"),
            onCreateCollection: onShowCreateCollectionModal("restore"),
        });

    const handleDeletePermanently = () =>
        showMiniDialog({
            title: t("delete_files_title"),
            message: t("delete_files_message"),
            continue: {
                text: t("delete"),
                color: "critical",
                action: handleFileOp("deletePermanently"),
            },
        });

    const handleAddToCollection = () =>
        onOpenCollectionSelector({
            action: "add",
            sourceCollectionSummaryID: collectionSummary?.id,
            onSelectCollection: handleCollectionOp("add"),
            onCreateCollection: onShowCreateCollectionModal("add"),
        });

    const handleRemoveFromOwnCollection = () => {
        showMiniDialog(
            selectedFileCount == selectedOwnFileCount
                ? {
                      title: t("remove_from_album"),
                      message: t("confirm_remove_message"),
                      continue: {
                          text: t("yes_remove"),
                          color: "primary",
                          action: () =>
                              handleCollectionOp("remove")(collection),
                      },
                  }
                : {
                      title: t("remove_from_album"),
                      message: t("confirm_remove_incl_others_message"),
                      continue: {
                          text: t("yes_remove"),
                          color: "critical",
                          action: () =>
                              handleCollectionOp("remove")(collection),
                      },
                  },
        );
    };

    const handleMoveToCollection = () => {
        onOpenCollectionSelector({
            action: "move",
            sourceCollectionSummaryID: collectionSummary?.id,
            onSelectCollection: handleCollectionOp("move"),
            onCreateCollection: onShowCreateCollectionModal("move"),
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
                    <FixTimeButton onClick={handleFileOp("fixTime")} />
                    <DownloadButton onClick={handleFileOp("download")} />
                    <AddToCollectionButton onClick={handleAddToCollection} />
                    <ArchiveButton onClick={handleFileOp("archive")} />
                    <HideButton onClick={handleFileOp("hide")} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : barMode == "people" ? (
                <>
                    <DownloadButton onClick={handleFileOp("download")} />
                    <AddToCollectionButton onClick={handleAddToCollection} />
                    <ArchiveButton onClick={handleFileOp("archive")} />
                    <HideButton onClick={handleFileOp("hide")} />
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
                    <DownloadButton onClick={handleFileOp("download")} />
                    <MoveToCollectionButton onClick={handleMoveToCollection} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : collectionSummary?.attributes.has("sharedIncoming") ? (
                <DownloadButton onClick={handleFileOp("download")} />
            ) : barMode == "hidden-albums" ? (
                <>
                    <DownloadButton onClick={handleFileOp("download")} />
                    <UnhideButton onClick={handleUnhide} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : (
                <>
                    {!isUserFavorites &&
                        collectionSummary?.id !=
                            PseudoCollectionID.archiveItems && (
                            <FavoriteButton
                                onClick={handleFileOp("favorite")}
                            />
                        )}
                    <FixTimeButton onClick={handleFileOp("fixTime")} />
                    <DownloadButton onClick={handleFileOp("download")} />
                    <AddToCollectionButton onClick={handleAddToCollection} />
                    {collectionSummary?.id === PseudoCollectionID.all ? (
                        <ArchiveButton onClick={handleFileOp("archive")} />
                    ) : collectionSummary?.id ==
                      PseudoCollectionID.archiveItems ? (
                        <UnarchiveButton onClick={handleFileOp("unarchive")} />
                    ) : (
                        !isUserFavorites && (
                            <>
                                <MoveToCollectionButton
                                    onClick={handleMoveToCollection}
                                />
                                <RemoveFromCollectionButton
                                    onClick={handleRemoveFromOwnCollection}
                                />
                            </>
                        )
                    )}
                    <HideButton onClick={handleFileOp("hide")} />
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
