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
import { useBaseContext } from "ente-base/context";
import type { Collection } from "ente-media/collection";
import type { CollectionSelectorAttributes } from "ente-new/photos/components/CollectionSelector";
import type { GalleryBarMode } from "ente-new/photos/components/gallery/reducer";
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    TRASH_SECTION,
} from "ente-new/photos/services/collection";
import { t } from "i18next";
import { type CollectionOp } from "utils/collection";
import { type FileOp } from "utils/file";

interface Props {
    handleCollectionOp: (op: CollectionOp) => (...args: any[]) => void;
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
    count: number;
    ownCount: number;
    clearSelection: () => void;
    barMode?: GalleryBarMode;
    activeCollectionID: number;
    isFavoriteCollection: boolean;
    isUncategorizedCollection: boolean;
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
    isIncomingSharedCollection: boolean;
    isInSearchMode: boolean;
    selectedCollection: Collection;
    isInHiddenSection: boolean;
}

const SelectedFileOptions = ({
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
    isFavoriteCollection,
    isUncategorizedCollection,
    isIncomingSharedCollection,
    isInSearchMode,
    isInHiddenSection,
}: Props) => {
    const { showMiniDialog } = useBaseContext();

    const peopleMode = barMode == "people";

    const addToCollection = () =>
        onOpenCollectionSelector({
            action: "add",
            onSelectCollection: handleCollectionOp("add"),
            onCreateCollection: showCreateCollectionModal("add"),
            relatedCollectionID:
                isInSearchMode || peopleMode ? undefined : activeCollectionID,
        });

    const trashHandler = () =>
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

    const removeFromCollectionHandler = () => {
        if (ownCount === count) {
            showMiniDialog({
                title: t("remove_from_album"),
                message: t("confirm_remove_message"),
                continue: {
                    text: t("yes_remove"),
                    color: "primary",

                    action: () =>
                        handleCollectionOp("remove")(selectedCollection),
                },
            });
        } else {
            showMiniDialog({
                title: t("remove_from_album"),
                message: t("confirm_remove_incl_others_message"),
                continue: {
                    text: t("yes_remove"),
                    color: "critical",
                    action: () =>
                        handleCollectionOp("remove")(selectedCollection),
                },
            });
        }
    };

    const moveToCollection = () => {
        onOpenCollectionSelector({
            action: "move",
            onSelectCollection: handleCollectionOp("move"),
            onCreateCollection: showCreateCollectionModal("move"),
            relatedCollectionID:
                isInSearchMode || peopleMode ? undefined : activeCollectionID,
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
                    <Tooltip title={t("fix_creation_time")}>
                        <IconButton onClick={handleFileOp("fixTime")}>
                            <ClockIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("download")}>
                        <IconButton onClick={handleFileOp("download")}>
                            <DownloadIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("add")}>
                        <IconButton onClick={addToCollection}>
                            <AddIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("archive")}>
                        <IconButton onClick={handleFileOp("archive")}>
                            <ArchiveIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("hide")}>
                        <IconButton onClick={handleFileOp("hide")}>
                            <VisibilityOffOutlinedIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("delete")}>
                        <IconButton onClick={trashHandler}>
                            <DeleteIcon />
                        </IconButton>
                    </Tooltip>
                </>
            ) : peopleMode ? (
                <>
                    <Tooltip title={t("download")}>
                        <IconButton onClick={handleFileOp("download")}>
                            <DownloadIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("add")}>
                        <IconButton onClick={addToCollection}>
                            <AddIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("archive")}>
                        <IconButton onClick={handleFileOp("archive")}>
                            <ArchiveIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("hide")}>
                        <IconButton onClick={handleFileOp("hide")}>
                            <VisibilityOffOutlinedIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("delete")}>
                        <IconButton onClick={trashHandler}>
                            <DeleteIcon />
                        </IconButton>
                    </Tooltip>
                </>
            ) : activeCollectionID === TRASH_SECTION ? (
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
                    <Tooltip title={t("download")}>
                        <IconButton onClick={handleFileOp("download")}>
                            <DownloadIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("move")}>
                        <IconButton onClick={moveToCollection}>
                            <MoveIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("delete")}>
                        <IconButton onClick={trashHandler}>
                            <DeleteIcon />
                        </IconButton>
                    </Tooltip>
                </>
            ) : isIncomingSharedCollection ? (
                <Tooltip title={t("download")}>
                    <IconButton onClick={handleFileOp("download")}>
                        <DownloadIcon />
                    </IconButton>
                </Tooltip>
            ) : isInHiddenSection ? (
                <>
                    <Tooltip title={t("unhide")}>
                        <IconButton onClick={unhideToCollection}>
                            <VisibilityOutlinedIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("download")}>
                        <IconButton onClick={handleFileOp("download")}>
                            <DownloadIcon />
                        </IconButton>
                    </Tooltip>

                    <Tooltip title={t("delete")}>
                        <IconButton onClick={trashHandler}>
                            <DeleteIcon />
                        </IconButton>
                    </Tooltip>
                </>
            ) : (
                <>
                    <Tooltip title={t("fix_creation_time")}>
                        <IconButton onClick={handleFileOp("fixTime")}>
                            <ClockIcon />
                        </IconButton>
                    </Tooltip>
                    {!isFavoriteCollection &&
                        activeCollectionID != ARCHIVE_SECTION && (
                            <Tooltip title={t("favorite")}>
                                <IconButton onClick={handleFileOp("favorite")}>
                                    <FavoriteBorderIcon />
                                </IconButton>
                            </Tooltip>
                        )}
                    <Tooltip title={t("download")}>
                        <IconButton onClick={handleFileOp("download")}>
                            <DownloadIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("add")}>
                        <IconButton onClick={addToCollection}>
                            <AddIcon />
                        </IconButton>
                    </Tooltip>
                    {activeCollectionID === ARCHIVE_SECTION && (
                        <Tooltip title={t("unarchive")}>
                            <IconButton onClick={handleFileOp("unarchive")}>
                                <UnArchiveIcon />
                            </IconButton>
                        </Tooltip>
                    )}
                    {activeCollectionID === ALL_SECTION && (
                        <Tooltip title={t("archive")}>
                            <IconButton onClick={handleFileOp("archive")}>
                                <ArchiveIcon />
                            </IconButton>
                        </Tooltip>
                    )}
                    {activeCollectionID !== ALL_SECTION &&
                        activeCollectionID !== ARCHIVE_SECTION &&
                        !isFavoriteCollection && (
                            <>
                                <Tooltip title={t("move")}>
                                    <IconButton onClick={moveToCollection}>
                                        <MoveIcon />
                                    </IconButton>
                                </Tooltip>

                                <Tooltip title={t("remove")}>
                                    <IconButton
                                        onClick={removeFromCollectionHandler}
                                    >
                                        <RemoveIcon />
                                    </IconButton>
                                </Tooltip>
                            </>
                        )}
                    <Tooltip title={t("hide")}>
                        <IconButton onClick={handleFileOp("hide")}>
                            <VisibilityOffOutlinedIcon />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t("delete")}>
                        <IconButton onClick={trashHandler}>
                            <DeleteIcon />
                        </IconButton>
                    </Tooltip>
                </>
            )}
        </SpacedRow>
    );
};

export default SelectedFileOptions;
