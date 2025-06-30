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
    activeCollectionID: number;
    selectedCollection?: Collection;
    /**
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
    activeCollectionSummary: CollectionSummary | undefined;
    count: number;
    ownCount: number;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    handleCollectionOp: (op: CollectionOp) => (...args: any[]) => void;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    handleFileOp: (op: FileOp) => (...args: any[]) => void;
    showCreateCollectionModal: (op: CollectionOp) => () => void;
    /**
     * Callback to open a dialog where the user can choose a collection.
     *
     * The reason for opening the dialog and other properties are passed as the
     * {@link attributes} argument.
     */
    onOpenCollectionSelector: (
        attributes: CollectionSelectorAttributes,
    ) => void;
    clearSelection: () => void;
}

export const SelectedFileOptions: React.FC<SelectedFileOptionsProps> = ({
    showCreateCollectionModal,
    onOpenCollectionSelector,
    handleCollectionOp,
    handleFileOp,
    selectedCollection,
    count,
    ownCount,
    clearSelection,
    barMode,
    activeCollectionID,
    activeCollectionSummary,
    isInSearchMode,
}) => {
    const { showMiniDialog } = useBaseContext();

    const isFavoriteCollection =
        !!activeCollectionSummary?.attributes.has("userFavorites");

    const isUncategorizedCollection =
        activeCollectionSummary?.type == "uncategorized";

    const isSharedIncomingCollection =
        !!activeCollectionSummary?.attributes.has("sharedIncoming");

    const addToCollection = () =>
        onOpenCollectionSelector({
            action: "add",
            onSelectCollection: handleCollectionOp("add"),
            onCreateCollection: showCreateCollectionModal("add"),
            relatedCollectionID:
                isInSearchMode || barMode == "people"
                    ? undefined
                    : activeCollectionID,
        });

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

    const permanentlyDeleteHandler = () =>
        showMiniDialog({
            title: t("delete_files_title"),
            message: t("delete_files_message"),
            continue: {
                text: t("delete"),
                color: "critical",
                action: handleFileOp("deletePermanently"),
            },
        });

    const restoreHandler = () =>
        onOpenCollectionSelector({
            action: "restore",
            onSelectCollection: handleCollectionOp("restore"),
            onCreateCollection: showCreateCollectionModal("restore"),
        });

    const handleRemoveFromOwnCollection = () => {
        showMiniDialog(
            ownCount == count
                ? {
                      title: t("remove_from_album"),
                      message: t("confirm_remove_message"),
                      continue: {
                          text: t("yes_remove"),
                          color: "primary",
                          action: () =>
                              handleCollectionOp("remove")(selectedCollection),
                      },
                  }
                : {
                      title: t("remove_from_album"),
                      message: t("confirm_remove_incl_others_message"),
                      continue: {
                          text: t("yes_remove"),
                          color: "critical",
                          action: () =>
                              handleCollectionOp("remove")(selectedCollection),
                      },
                  },
        );
    };

    const handleMoveToCollection = () => {
        onOpenCollectionSelector({
            action: "move",
            onSelectCollection: handleCollectionOp("move"),
            onCreateCollection: showCreateCollectionModal("move"),
            relatedCollectionID:
                isInSearchMode || barMode == "people"
                    ? undefined
                    : activeCollectionID,
        });
    };

    const unhideToCollection = () => {
        onOpenCollectionSelector({
            action: "unhide",
            onSelectCollection: handleCollectionOp("unhide"),
            onCreateCollection: showCreateCollectionModal("unhide"),
        });
    };

    return (
        <SpacedRow sx={{ flex: 1, gap: 1, flexWrap: "wrap" }}>
            <IconButton onClick={clearSelection}>
                <CloseIcon />
            </IconButton>
            <Typography sx={{ mr: "auto" }}>
                {ownCount === count
                    ? t("selected_count", { selected: count })
                    : t("selected_and_yours_count", {
                          selected: count,
                          yours: ownCount,
                      })}
            </Typography>

            {isInSearchMode ? (
                <>
                    <FixTimeButton onClick={handleFileOp("fixTime")} />
                    <DownloadButton onClick={handleFileOp("download")} />
                    <AddToCollectionButton onClick={addToCollection} />
                    <ArchiveButton onClick={handleFileOp("archive")} />
                    <HideButton onClick={handleFileOp("hide")} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : barMode == "people" ? (
                <>
                    <DownloadButton onClick={handleFileOp("download")} />
                    <AddToCollectionButton onClick={addToCollection} />
                    <ArchiveButton onClick={handleFileOp("archive")} />
                    <HideButton onClick={handleFileOp("hide")} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : activeCollectionID == PseudoCollectionID.trash ? (
                <>
                    <Tooltip title={t("restore")}>
                        <IconButton onClick={restoreHandler}>
                            <RestoreIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("delete_permanently")}>
                        <IconButton onClick={permanentlyDeleteHandler}>
                            <DeleteIcon />
                        </IconButton>
                    </Tooltip>
                </>
            ) : isUncategorizedCollection ? (
                <>
                    <DownloadButton onClick={handleFileOp("download")} />
                    <MoveToCollectionButton onClick={handleMoveToCollection} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : isSharedIncomingCollection ? (
                <DownloadButton onClick={handleFileOp("download")} />
            ) : barMode == "hidden-albums" ? (
                <>
                    <Tooltip title={t("unhide")}>
                        <IconButton onClick={unhideToCollection}>
                            <VisibilityOutlinedIcon />
                        </IconButton>
                    </Tooltip>
                    <DownloadButton onClick={handleFileOp("download")} />
                    <DeleteButton onClick={handleDelete} />
                </>
            ) : (
                <>
                    <FixTimeButton onClick={handleFileOp("fixTime")} />
                    {!isFavoriteCollection &&
                        activeCollectionID !=
                            PseudoCollectionID.archiveItems && (
                            <Tooltip title={t("favorite")}>
                                <IconButton onClick={handleFileOp("favorite")}>
                                    <FavoriteBorderIcon />
                                </IconButton>
                            </Tooltip>
                        )}
                    <DownloadButton onClick={handleFileOp("download")} />
                    <AddToCollectionButton onClick={addToCollection} />
                    {activeCollectionID == PseudoCollectionID.archiveItems && (
                        <Tooltip title={t("unarchive")}>
                            <IconButton onClick={handleFileOp("unarchive")}>
                                <UnArchiveIcon />
                            </IconButton>
                        </Tooltip>
                    )}
                    {activeCollectionID === PseudoCollectionID.all && (
                        <ArchiveButton onClick={handleFileOp("archive")} />
                    )}
                    {activeCollectionID !== PseudoCollectionID.all &&
                        activeCollectionID != PseudoCollectionID.archiveItems &&
                        !isFavoriteCollection && (
                            <>
                                <MoveToCollectionButton
                                    onClick={handleMoveToCollection}
                                />

                                <Tooltip title={t("remove")}>
                                    <IconButton
                                        onClick={handleRemoveFromOwnCollection}
                                    >
                                        <RemoveIcon />
                                    </IconButton>
                                </Tooltip>
                            </>
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

const ArchiveButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("archive")}>
        <IconButton {...{ onClick }}>
            <ArchiveIcon />
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

const DeleteButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <Tooltip title={t("delete")}>
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
