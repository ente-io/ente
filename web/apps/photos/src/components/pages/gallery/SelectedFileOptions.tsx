import { SelectionBar } from "@/base/components/Navbar";
import type { Collection } from "@/media/collection";
import type { GalleryBarMode } from "@/new/photos/components/Gallery/BarImpl";
import { FluidContainer } from "@ente/shared/components/Container";
import ClockIcon from "@mui/icons-material/AccessTime";
import AddIcon from "@mui/icons-material/Add";
import ArchiveIcon from "@mui/icons-material/ArchiveOutlined";
import MoveIcon from "@mui/icons-material/ArrowForward";
import CloseIcon from "@mui/icons-material/Close";
import DeleteIcon from "@mui/icons-material/Delete";
import DownloadIcon from "@mui/icons-material/Download";
import RemoveIcon from "@mui/icons-material/RemoveCircleOutline";
import RestoreIcon from "@mui/icons-material/Restore";
import UnArchiveIcon from "@mui/icons-material/Unarchive";
import VisibilityOffOutlined from "@mui/icons-material/VisibilityOffOutlined";
import VisibilityOutlined from "@mui/icons-material/VisibilityOutlined";
import { Box, IconButton, Stack, Tooltip } from "@mui/material";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext } from "react";
import {
    CollectionSelectorIntent,
    SetCollectionSelectorAttributes,
} from "types/gallery";
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    COLLECTION_OPS_TYPE,
    TRASH_SECTION,
} from "utils/collection";
import { FILE_OPS_TYPE } from "utils/file";
import { formatNumber } from "utils/number/format";
import { getTrashFilesMessage } from "utils/ui";

interface Props {
    handleCollectionOps: (
        opsType: COLLECTION_OPS_TYPE,
    ) => (...args: any[]) => void;
    handleFileOps: (opsType: FILE_OPS_TYPE) => (...args: any[]) => void;
    showCreateCollectionModal: (opsType: COLLECTION_OPS_TYPE) => () => void;
    setCollectionSelectorAttributes: SetCollectionSelectorAttributes;
    count: number;
    ownCount: number;
    clearSelection: () => void;
    barMode?: GalleryBarMode;
    activeCollectionID: number;
    isFavoriteCollection: boolean;
    isUncategorizedCollection: boolean;
    isIncomingSharedCollection: boolean;
    isInSearchMode: boolean;
    selectedCollection: Collection;
    isInHiddenSection: boolean;
}

const SelectedFileOptions = ({
    showCreateCollectionModal,
    setCollectionSelectorAttributes,
    handleCollectionOps,
    handleFileOps,
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
    const { setDialogMessage } = useContext(AppContext);

    const peopleMode = barMode == "people";

    const addToCollection = () =>
        setCollectionSelectorAttributes({
            callback: handleCollectionOps(COLLECTION_OPS_TYPE.ADD),
            showNextModal: showCreateCollectionModal(COLLECTION_OPS_TYPE.ADD),
            intent: CollectionSelectorIntent.add,
            fromCollection:
                !isInSearchMode && !peopleMode ? activeCollectionID : undefined,
        });

    const trashHandler = () =>
        setDialogMessage(
            getTrashFilesMessage(handleFileOps(FILE_OPS_TYPE.TRASH)),
        );

    const permanentlyDeleteHandler = () =>
        setDialogMessage({
            title: t("DELETE_FILES_TITLE"),
            content: t("DELETE_FILES_MESSAGE"),
            proceed: {
                action: handleFileOps(FILE_OPS_TYPE.DELETE_PERMANENTLY),
                text: t("DELETE"),
                variant: "critical",
            },
            close: { text: t("cancel") },
        });

    const restoreHandler = () =>
        setCollectionSelectorAttributes({
            callback: handleCollectionOps(COLLECTION_OPS_TYPE.RESTORE),
            showNextModal: showCreateCollectionModal(
                COLLECTION_OPS_TYPE.RESTORE,
            ),
            intent: CollectionSelectorIntent.restore,
        });

    const removeFromCollectionHandler = () => {
        if (ownCount === count) {
            setDialogMessage({
                title: t("REMOVE_FROM_COLLECTION"),
                content: t("CONFIRM_SELF_REMOVE_MESSAGE"),

                proceed: {
                    action: () =>
                        handleCollectionOps(COLLECTION_OPS_TYPE.REMOVE)(
                            selectedCollection,
                        ),
                    text: t("YES_REMOVE"),
                    variant: "primary",
                },
                close: { text: t("cancel") },
            });
        } else {
            setDialogMessage({
                title: t("REMOVE_FROM_COLLECTION"),
                content: t("CONFIRM_SELF_AND_OTHER_REMOVE_MESSAGE"),

                proceed: {
                    action: () =>
                        handleCollectionOps(COLLECTION_OPS_TYPE.REMOVE)(
                            selectedCollection,
                        ),
                    text: t("YES_REMOVE"),
                    variant: "critical",
                },
                close: { text: t("cancel") },
            });
        }
    };

    const moveToCollection = () => {
        setCollectionSelectorAttributes({
            callback: handleCollectionOps(COLLECTION_OPS_TYPE.MOVE),
            showNextModal: showCreateCollectionModal(COLLECTION_OPS_TYPE.MOVE),
            intent: CollectionSelectorIntent.move,
            fromCollection:
                !isInSearchMode && !peopleMode ? activeCollectionID : undefined,
        });
    };

    const unhideToCollection = () => {
        setCollectionSelectorAttributes({
            callback: handleCollectionOps(COLLECTION_OPS_TYPE.UNHIDE),
            showNextModal: showCreateCollectionModal(
                COLLECTION_OPS_TYPE.UNHIDE,
            ),
            intent: CollectionSelectorIntent.unhide,
        });
    };

    return (
        <SelectionBar>
            <FluidContainer>
                <IconButton onClick={clearSelection}>
                    <CloseIcon />
                </IconButton>
                <Box ml={1.5}>
                    {formatNumber(count)} {t("SELECTED")}{" "}
                    {ownCount !== count &&
                        `(${formatNumber(ownCount)} ${t("YOURS")})`}
                </Box>
            </FluidContainer>
            <Stack spacing={2} direction="row" mr={2}>
                {isInSearchMode ? (
                    <>
                        <Tooltip title={t("FIX_CREATION_TIME")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.FIX_TIME)}
                            >
                                <ClockIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("download")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.DOWNLOAD)}
                            >
                                <DownloadIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("add")}>
                            <IconButton onClick={addToCollection}>
                                <AddIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("archive")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.ARCHIVE)}
                            >
                                <ArchiveIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("HIDE")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.HIDE)}
                            >
                                <VisibilityOffOutlined />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("DELETE")}>
                            <IconButton onClick={trashHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : peopleMode ? (
                    <>
                        <Tooltip title={t("download")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.DOWNLOAD)}
                            >
                                <DownloadIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("add")}>
                            <IconButton onClick={addToCollection}>
                                <AddIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("archive")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.ARCHIVE)}
                            >
                                <ArchiveIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("HIDE")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.HIDE)}
                            >
                                <VisibilityOffOutlined />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("DELETE")}>
                            <IconButton onClick={trashHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : activeCollectionID === TRASH_SECTION ? (
                    <>
                        <Tooltip title={t("RESTORE")}>
                            <IconButton onClick={restoreHandler}>
                                <RestoreIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("DELETE_PERMANENTLY")}>
                            <IconButton onClick={permanentlyDeleteHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : isUncategorizedCollection ? (
                    <>
                        <Tooltip title={t("download")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.DOWNLOAD)}
                            >
                                <DownloadIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("MOVE")}>
                            <IconButton onClick={moveToCollection}>
                                <MoveIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("DELETE")}>
                            <IconButton onClick={trashHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : isIncomingSharedCollection ? (
                    <Tooltip title={t("download")}>
                        <IconButton
                            onClick={handleFileOps(FILE_OPS_TYPE.DOWNLOAD)}
                        >
                            <DownloadIcon />
                        </IconButton>
                    </Tooltip>
                ) : isInHiddenSection ? (
                    <>
                        <Tooltip title={t("UNHIDE")}>
                            <IconButton onClick={unhideToCollection}>
                                <VisibilityOutlined />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("download")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.DOWNLOAD)}
                            >
                                <DownloadIcon />
                            </IconButton>
                        </Tooltip>

                        <Tooltip title={t("DELETE")}>
                            <IconButton onClick={trashHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : (
                    <>
                        <Tooltip title={t("FIX_CREATION_TIME")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.FIX_TIME)}
                            >
                                <ClockIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("download")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.DOWNLOAD)}
                            >
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
                                <IconButton
                                    onClick={handleFileOps(
                                        FILE_OPS_TYPE.UNARCHIVE,
                                    )}
                                >
                                    <UnArchiveIcon />
                                </IconButton>
                            </Tooltip>
                        )}
                        {activeCollectionID === ALL_SECTION && (
                            <Tooltip title={t("archive")}>
                                <IconButton
                                    onClick={handleFileOps(
                                        FILE_OPS_TYPE.ARCHIVE,
                                    )}
                                >
                                    <ArchiveIcon />
                                </IconButton>
                            </Tooltip>
                        )}
                        {activeCollectionID !== ALL_SECTION &&
                            activeCollectionID !== ARCHIVE_SECTION &&
                            !isFavoriteCollection && (
                                <>
                                    <Tooltip title={t("MOVE")}>
                                        <IconButton onClick={moveToCollection}>
                                            <MoveIcon />
                                        </IconButton>
                                    </Tooltip>

                                    <Tooltip title={t("REMOVE")}>
                                        <IconButton
                                            onClick={
                                                removeFromCollectionHandler
                                            }
                                        >
                                            <RemoveIcon />
                                        </IconButton>
                                    </Tooltip>
                                </>
                            )}
                        <Tooltip title={t("HIDE")}>
                            <IconButton
                                onClick={handleFileOps(FILE_OPS_TYPE.HIDE)}
                            >
                                <VisibilityOffOutlined />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t("DELETE")}>
                            <IconButton onClick={trashHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                )}
            </Stack>
        </SelectionBar>
    );
};

export default SelectedFileOptions;
