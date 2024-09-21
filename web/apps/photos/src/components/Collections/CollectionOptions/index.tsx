import log from "@/base/log";
import type { Collection } from "@/media/collection";
import { ItemVisibility } from "@/media/file-metadata";
import type { CollectionSummaryType } from "@/new/photos/types/collection";
import { HorizontalFlex } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import OverflowMenu, {
    StyledMenu,
} from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import ArchiveOutlined from "@mui/icons-material/ArchiveOutlined";
import DeleteOutlinedIcon from "@mui/icons-material/DeleteOutlined";
import EditIcon from "@mui/icons-material/Edit";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import LogoutIcon from "@mui/icons-material/Logout";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import PeopleIcon from "@mui/icons-material/People";
import PushPinOutlined from "@mui/icons-material/PushPinOutlined";
import SortIcon from "@mui/icons-material/Sort";
import TvIcon from "@mui/icons-material/Tv";
import Unarchive from "@mui/icons-material/Unarchive";
import VisibilityOffOutlined from "@mui/icons-material/VisibilityOffOutlined";
import VisibilityOutlined from "@mui/icons-material/VisibilityOutlined";
import { Box, IconButton, Stack, Tooltip } from "@mui/material";
import { UnPinIcon } from "components/icons/UnPinIcon";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import type { Dispatch, SetStateAction } from "react";
import { useCallback, useContext, useRef, useState } from "react";
import { Trans } from "react-i18next";
import * as CollectionAPI from "services/collectionService";
import * as TrashService from "services/trashService";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";
import {
    ALL_SECTION,
    changeCollectionOrder,
    changeCollectionSortOrder,
    changeCollectionVisibility,
    downloadCollectionHelper,
    downloadDefaultHiddenCollectionHelper,
    HIDDEN_ITEMS_SECTION,
    isHiddenCollection,
} from "utils/collection";
import { isArchivedCollection, isPinnedCollection } from "utils/magicMetadata";
import { SetCollectionNamerAttributes } from "../CollectionNamer";

interface CollectionOptionsProps {
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator;
    isActiveCollectionDownloadInProgress: () => boolean;
    activeCollection: Collection;
    collectionSummaryType: CollectionSummaryType;
    showCollectionShareModal: () => void;
    setActiveCollectionID: (collectionID: number) => void;
    setShowAlbumCastDialog: Dispatch<SetStateAction<boolean>>;
}

const CollectionOptions = (props: CollectionOptionsProps) => {
    const {
        activeCollection,
        collectionSummaryType,
        setActiveCollectionID,
        setCollectionNamerAttributes,
        showCollectionShareModal,
        setFilesDownloadProgressAttributesCreator,
        isActiveCollectionDownloadInProgress,
        setShowAlbumCastDialog,
    } = props;

    const { startLoading, finishLoading, setDialogMessage } =
        useContext(AppContext);
    const { syncWithRemote } = useContext(GalleryContext);
    const overFlowMenuIconRef = useRef<SVGSVGElement>(null);
    const [collectionSortOrderMenuView, setCollectionSortOrderMenuView] =
        useState(false);

    const handleError = useCallback(
        (e: unknown) => {
            log.error("Collection action failed", e);
            setDialogMessage({
                title: t("ERROR"),
                content: t("UNKNOWN_ERROR"),
                close: { variant: "critical" },
            });
        },
        [setDialogMessage],
    );

    /**
     * Return a new function by wrapping an async function in an error handler,
     * and syncing on completion.
     */
    const wrapErrorAndSync = async (f: () => Promise<void>) => {
        return async () => {
            try {
                await f();
            } catch (e) {
                handleError(e);
            } finally {
                syncWithRemote(false, true);
            }
        };
    };

    /**
     * Variant of {@link wrapErrorAndSync} that also shows the global
     * loading bar.
     */
    const wrapErrorAndSyncLoading = async (f: () => Promise<void>) => {
        return async () => {
            startLoading();
            try {
                await f();
            } catch (e) {
                handleError(e);
            } finally {
                syncWithRemote(false, true);
                finishLoading();
            }
        };
    };

    /**
     * Variant of {@link wrapErrorAndSyncLoading} with a string arg.
     */
    const wrapErrorAndSyncLoadingString = async (
        f: (s: string) => Promise<void>,
    ) => {
        return async (s: string) => {
            startLoading();
            try {
                await f(s);
            } catch (e) {
                handleError(e);
            } finally {
                syncWithRemote(false, true);
                finishLoading();
            }
        };
    };

    const showRenameCollectionModal = () => {
        setCollectionNamerAttributes({
            title: t("RENAME_COLLECTION"),
            buttonText: t("RENAME"),
            autoFilledName: activeCollection.name,
            callback: renameCollection,
        });
    };

    const _renameCollection = async (newName: string) => {
        if (activeCollection.name !== newName) {
            await CollectionAPI.renameCollection(activeCollection, newName);
        }
    };

    const renameCollection = () =>
        void wrapErrorAndSyncLoadingString(_renameCollection);

    const confirmDeleteCollection = () => {
        setDialogMessage({
            title: t("DELETE_COLLECTION_TITLE"),
            content: (
                <Trans
                    i18nKey={"DELETE_COLLECTION_MESSAGE"}
                    components={{
                        a: <Box component={"span"} color="text.base" />,
                    }}
                />
            ),
            proceed: {
                text: t("DELETE_PHOTOS"),
                action: deleteCollectionAlongWithFiles,
                variant: "critical",
            },
            secondary: {
                text: t("KEEP_PHOTOS"),
                action: deleteCollectionButKeepFiles,
                variant: "primary",
            },
            close: {
                text: t("cancel"),
            },
        });
    };

    const _deleteCollectionAlongWithFiles = async () => {
        await CollectionAPI.deleteCollection(activeCollection.id, false);
        setActiveCollectionID(ALL_SECTION);
    };

    const _deleteCollectionButKeepFiles = async () => {
        await CollectionAPI.deleteCollection(activeCollection.id, true);
        setActiveCollectionID(ALL_SECTION);
    };

    const deleteCollectionAlongWithFiles = () =>
        void wrapErrorAndSyncLoading(_deleteCollectionAlongWithFiles);

    const deleteCollectionButKeepFiles = () =>
        void wrapErrorAndSyncLoading(_deleteCollectionButKeepFiles);

    const confirmEmptyTrash = () =>
        setDialogMessage({
            title: t("EMPTY_TRASH_TITLE"),
            content: t("EMPTY_TRASH_MESSAGE"),
            proceed: {
                action: emptyTrash,
                text: t("EMPTY_TRASH"),
                variant: "critical",
            },
            close: { text: t("cancel") },
        });

    const _emptyTrash = async () => {
        await TrashService.emptyTrash();
        await TrashService.clearLocalTrash();
        setActiveCollectionID(ALL_SECTION);
    };

    const emptyTrash = () => void wrapErrorAndSyncLoading(_emptyTrash);

    const _downloadCollection = () => {
        if (isActiveCollectionDownloadInProgress()) return;

        if (collectionSummaryType == "hiddenItems") {
            return downloadDefaultHiddenCollectionHelper(
                setFilesDownloadProgressAttributesCreator(
                    activeCollection.name,
                    HIDDEN_ITEMS_SECTION,
                    true,
                ),
            );
        } else {
            return downloadCollectionHelper(
                activeCollection.id,
                setFilesDownloadProgressAttributesCreator(
                    activeCollection.name,
                    activeCollection.id,
                    isHiddenCollection(activeCollection),
                ),
            );
        }
    };

    const downloadCollection = () =>
        void _downloadCollection().catch(handleError);

    const _archiveAlbum = () =>
        changeCollectionVisibility(activeCollection, ItemVisibility.archived);

    const _unarchiveAlbum = () =>
        changeCollectionVisibility(activeCollection, ItemVisibility.visible);

    const archiveAlbum = () => void wrapErrorAndSyncLoading(_archiveAlbum);

    const unarchiveAlbum = () => void wrapErrorAndSyncLoading(_unarchiveAlbum);

    const confirmLeaveSharedAlbum = () => {
        setDialogMessage({
            title: t("LEAVE_SHARED_ALBUM_TITLE"),
            content: t("LEAVE_SHARED_ALBUM_MESSAGE"),
            proceed: {
                text: t("LEAVE_SHARED_ALBUM"),
                action: leaveSharedAlbum,
                variant: "critical",
            },
            close: {
                text: t("cancel"),
            },
        });
    };

    const _leaveSharedAlbum = async () => {
        await CollectionAPI.leaveSharedAlbum(activeCollection.id);
        setActiveCollectionID(ALL_SECTION);
    };

    const leaveSharedAlbum = () =>
        void wrapErrorAndSyncLoading(_leaveSharedAlbum);

    const showCastAlbumDialog = () => setShowAlbumCastDialog(true);

    const _pinAlbum = () => changeCollectionOrder(activeCollection, 1);

    const _unpinAlbum = () => changeCollectionOrder(activeCollection, 0);

    const pinAlbum = () => void wrapErrorAndSync(_pinAlbum);

    const unpinAlbum = () => void wrapErrorAndSync(_unpinAlbum);

    const _hideAlbum = async () => {
        await changeCollectionVisibility(
            activeCollection,
            ItemVisibility.hidden,
        );
        setActiveCollectionID(ALL_SECTION);
    };

    const _unhideAlbum = async () => {
        await changeCollectionVisibility(
            activeCollection,
            ItemVisibility.visible,
        );
        setActiveCollectionID(HIDDEN_ITEMS_SECTION);
    };

    const hideAlbum = () => void wrapErrorAndSync(_hideAlbum);

    const unhideAlbum = () => void wrapErrorAndSync(_unhideAlbum);

    const showSortOrderMenu = () => setCollectionSortOrderMenuView(true);

    const closeSortOrderMenu = () => setCollectionSortOrderMenuView(false);

    const _changeSortOrderAsc = () =>
        changeCollectionSortOrder(activeCollection, true);

    const _changeSortOrderDesc = () =>
        changeCollectionSortOrder(activeCollection, false);

    const changeSortOrderAsc = () => void wrapErrorAndSync(_changeSortOrderAsc);

    const changeSortOrderDesc = () =>
        void wrapErrorAndSync(_changeSortOrderDesc);

    return (
        <HorizontalFlex sx={{ display: "inline-flex", gap: "16px" }}>
            <QuickOptions
                collectionSummaryType={collectionSummaryType}
                isDownloadInProgress={isActiveCollectionDownloadInProgress}
                onEmptyTrashClick={confirmEmptyTrash}
                onDownloadClick={downloadCollection}
                onShareClick={showCollectionShareModal}
            />

            <OverflowMenu
                ariaControls={"collection-options"}
                triggerButtonIcon={<MoreHoriz ref={overFlowMenuIconRef} />}
            >
                {collectionSummaryType == "trash" ? (
                    <EmptyTrashOption onClick={confirmEmptyTrash} />
                ) : collectionSummaryType == "favorites" ? (
                    <DownloadOption
                        isDownloadInProgress={
                            isActiveCollectionDownloadInProgress
                        }
                        onClick={downloadCollection}
                    >
                        {t("DOWNLOAD_FAVORITES")}
                    </DownloadOption>
                ) : collectionSummaryType == "uncategorized" ? (
                    <DownloadOption onClick={downloadCollection}>
                        {t("DOWNLOAD_UNCATEGORIZED")}
                    </DownloadOption>
                ) : collectionSummaryType == "hiddenItems" ? (
                    <DownloadOption onClick={downloadCollection}>
                        {t("DOWNLOAD_HIDDEN_ITEMS")}
                    </DownloadOption>
                ) : collectionSummaryType == "incomingShareViewer" ||
                  collectionSummaryType == "incomingShareCollaborator" ? (
                    <SharedCollectionOptions
                        isArchived={isArchivedCollection(activeCollection)}
                        onArchiveClick={archiveAlbum}
                        onUnarchiveClick={unarchiveAlbum}
                        onLeaveSharedAlbumClick={confirmLeaveSharedAlbum}
                        onCastClick={showCastAlbumDialog}
                    />
                ) : (
                    <AlbumCollectionOptions
                        isArchived={isArchivedCollection(activeCollection)}
                        isHidden={isHiddenCollection(activeCollection)}
                        isPinned={isPinnedCollection(activeCollection)}
                        onRenameClick={showRenameCollectionModal}
                        onSortClick={showSortOrderMenu}
                        onArchiveClick={archiveAlbum}
                        onUnarchiveClick={unarchiveAlbum}
                        onPinClick={pinAlbum}
                        onUnpinClick={unpinAlbum}
                        onHideClick={hideAlbum}
                        onUnhideClick={unhideAlbum}
                        onDeleteClick={confirmDeleteCollection}
                        onShareClick={showCollectionShareModal}
                        onCastClick={showCastAlbumDialog}
                    />
                )}
            </OverflowMenu>
            <CollectionSortOrderMenu
                open={collectionSortOrderMenuView}
                onClose={closeSortOrderMenu}
                overFlowMenuIconRef={overFlowMenuIconRef}
                onAscClick={changeSortOrderAsc}
                onDescClick={changeSortOrderDesc}
            />
        </HorizontalFlex>
    );
};

export default CollectionOptions;

/** Props for a generic option. */
interface OptionProps {
    onClick: () => void;
}

interface QuickOptionsProps {
    collectionSummaryType: CollectionSummaryType;
    isDownloadInProgress: () => boolean;
    onEmptyTrashClick: () => void;
    onDownloadClick: () => void;
    onShareClick: () => void;
}

const QuickOptions: React.FC<QuickOptionsProps> = ({
    onEmptyTrashClick,
    onDownloadClick,
    onShareClick,
    collectionSummaryType: type,
    isDownloadInProgress,
}) => (
    <Stack direction="row" sx={{ alignItems: "center", gap: "16px" }}>
        {showEmptyTrashQuickOption(type) && (
            <EmptyTrashQuickOption onClick={onEmptyTrashClick} />
        )}
        {showDownloadQuickOption(type) &&
            (isDownloadInProgress() ? (
                <EnteSpinner size="20px" sx={{ m: "12px" }} />
            ) : (
                <DownloadQuickOption
                    onClick={onDownloadClick}
                    collectionSummaryType={type}
                />
            ))}
        {showShareQuickOption(type) && (
            <ShareQuickOption
                onClick={onShareClick}
                collectionSummaryType={type}
            />
        )}
    </Stack>
);

const showEmptyTrashQuickOption = (type: CollectionSummaryType) =>
    type == "trash";

const EmptyTrashQuickOption: React.FC<OptionProps> = ({ onClick }) => (
    <Tooltip title={t("EMPTY_TRASH")}>
        <IconButton onClick={onClick}>
            <DeleteOutlinedIcon />
        </IconButton>
    </Tooltip>
);

const showDownloadQuickOption = (type: CollectionSummaryType) =>
    type == "folder" ||
    type == "favorites" ||
    type == "album" ||
    type == "uncategorized" ||
    type == "hiddenItems" ||
    type == "incomingShareViewer" ||
    type == "incomingShareCollaborator" ||
    type == "outgoingShare" ||
    type == "sharedOnlyViaLink" ||
    type == "archived" ||
    type == "pinned";

type DownloadQuickOptionProps = OptionProps & {
    collectionSummaryType: CollectionSummaryType;
};

const DownloadQuickOption: React.FC<DownloadQuickOptionProps> = ({
    onClick,
    collectionSummaryType,
}) => (
    <Tooltip
        title={
            collectionSummaryType == "favorites"
                ? t("DOWNLOAD_FAVORITES")
                : collectionSummaryType == "uncategorized"
                  ? t("DOWNLOAD_UNCATEGORIZED")
                  : collectionSummaryType == "hiddenItems"
                    ? t("DOWNLOAD_HIDDEN_ITEMS")
                    : t("DOWNLOAD_COLLECTION")
        }
    >
        <IconButton onClick={onClick}>
            <FileDownloadOutlinedIcon />
        </IconButton>
    </Tooltip>
);

const showShareQuickOption = (type: CollectionSummaryType) =>
    type == "folder" ||
    type == "album" ||
    type == "outgoingShare" ||
    type == "sharedOnlyViaLink" ||
    type == "archived" ||
    type == "incomingShareViewer" ||
    type == "incomingShareCollaborator" ||
    type == "pinned";

interface ShareQuickOptionProps {
    onClick: () => void;
    collectionSummaryType: CollectionSummaryType;
}

const ShareQuickOption: React.FC<ShareQuickOptionProps> = ({
    onClick,
    collectionSummaryType,
}) => (
    <Tooltip
        title={
            collectionSummaryType == "incomingShareViewer" ||
            collectionSummaryType == "incomingShareCollaborator"
                ? t("SHARING_DETAILS")
                : collectionSummaryType == "outgoingShare" ||
                    collectionSummaryType == "sharedOnlyViaLink"
                  ? t("MODIFY_SHARING")
                  : t("SHARE_COLLECTION")
        }
    >
        <IconButton onClick={onClick}>
            <PeopleIcon />
        </IconButton>
    </Tooltip>
);

const EmptyTrashOption: React.FC<OptionProps> = ({ onClick }) => (
    <OverflowMenuOption
        color="critical"
        startIcon={<DeleteOutlinedIcon />}
        onClick={onClick}
    >
        {t("EMPTY_TRASH")}
    </OverflowMenuOption>
);

type DownloadOptionProps = OptionProps & {
    isDownloadInProgress?: () => boolean;
};

const DownloadOption: React.FC<
    React.PropsWithChildren<DownloadOptionProps>
> = ({ isDownloadInProgress, onClick, children }) => (
    <OverflowMenuOption
        startIcon={
            isDownloadInProgress && isDownloadInProgress() ? (
                <EnteSpinner size="20px" sx={{ cursor: "not-allowed" }} />
            ) : (
                <FileDownloadOutlinedIcon />
            )
        }
        onClick={onClick}
    >
        {children}
    </OverflowMenuOption>
);

interface SharedCollectionOptionProps {
    isArchived: boolean;
    onArchiveClick: () => void;
    onUnarchiveClick: () => void;
    onLeaveSharedAlbumClick: () => void;
    onCastClick: () => void;
}

const SharedCollectionOptions: React.FC<SharedCollectionOptionProps> = ({
    isArchived,
    onArchiveClick,
    onUnarchiveClick,
    onLeaveSharedAlbumClick,
    onCastClick,
}) => (
    <>
        {isArchived ? (
            <OverflowMenuOption
                onClick={onUnarchiveClick}
                startIcon={<Unarchive />}
            >
                {t("UNARCHIVE_COLLECTION")}
            </OverflowMenuOption>
        ) : (
            <OverflowMenuOption
                onClick={onArchiveClick}
                startIcon={<ArchiveOutlined />}
            >
                {t("ARCHIVE_COLLECTION")}
            </OverflowMenuOption>
        )}
        <OverflowMenuOption
            startIcon={<LogoutIcon />}
            onClick={onLeaveSharedAlbumClick}
        >
            {t("LEAVE_ALBUM")}
        </OverflowMenuOption>
        <OverflowMenuOption startIcon={<TvIcon />} onClick={onCastClick}>
            {t("CAST_ALBUM_TO_TV")}
        </OverflowMenuOption>
    </>
);

interface AlbumCollectionOptionsProps {
    isArchived: boolean;
    isPinned: boolean;
    isHidden: boolean;
    onRenameClick: () => void;
    onSortClick: () => void;
    onArchiveClick: () => void;
    onUnarchiveClick: () => void;
    onPinClick: () => void;
    onUnpinClick: () => void;
    onHideClick: () => void;
    onUnhideClick: () => void;
    onDeleteClick: () => void;
    onShareClick: () => void;
    onCastClick: () => void;
}

const AlbumCollectionOptions: React.FC<AlbumCollectionOptionsProps> = ({
    isArchived,
    isPinned,
    isHidden,
    onRenameClick,
    onSortClick,
    onArchiveClick,
    onUnarchiveClick,
    onPinClick,
    onUnpinClick,
    onHideClick,
    onUnhideClick,
    onDeleteClick,
    onShareClick,
    onCastClick,
}) => (
    <>
        <OverflowMenuOption onClick={onRenameClick} startIcon={<EditIcon />}>
            {t("RENAME_COLLECTION")}
        </OverflowMenuOption>
        <OverflowMenuOption onClick={onSortClick} startIcon={<SortIcon />}>
            {t("SORT_BY")}
        </OverflowMenuOption>
        {isPinned ? (
            <OverflowMenuOption
                onClick={onUnpinClick}
                startIcon={<UnPinIcon />}
            >
                {t("UNPIN_ALBUM")}
            </OverflowMenuOption>
        ) : (
            <OverflowMenuOption
                onClick={onPinClick}
                startIcon={<PushPinOutlined />}
            >
                {t("PIN_ALBUM")}
            </OverflowMenuOption>
        )}
        {!isHidden && (
            <>
                {isArchived ? (
                    <OverflowMenuOption
                        onClick={onUnarchiveClick}
                        startIcon={<Unarchive />}
                    >
                        {t("UNARCHIVE_COLLECTION")}
                    </OverflowMenuOption>
                ) : (
                    <OverflowMenuOption
                        onClick={onArchiveClick}
                        startIcon={<ArchiveOutlined />}
                    >
                        {t("ARCHIVE_COLLECTION")}
                    </OverflowMenuOption>
                )}
            </>
        )}
        {isHidden ? (
            <OverflowMenuOption
                onClick={onUnhideClick}
                startIcon={<VisibilityOutlined />}
            >
                {t("UNHIDE_COLLECTION")}
            </OverflowMenuOption>
        ) : (
            <OverflowMenuOption
                onClick={onHideClick}
                startIcon={<VisibilityOffOutlined />}
            >
                {t("HIDE_COLLECTION")}
            </OverflowMenuOption>
        )}
        <OverflowMenuOption
            startIcon={<DeleteOutlinedIcon />}
            onClick={onDeleteClick}
        >
            {t("DELETE_COLLECTION")}
        </OverflowMenuOption>
        <OverflowMenuOption onClick={onShareClick} startIcon={<PeopleIcon />}>
            {t("SHARE_COLLECTION")}
        </OverflowMenuOption>
        <OverflowMenuOption startIcon={<TvIcon />} onClick={onCastClick}>
            {t("CAST_ALBUM_TO_TV")}
        </OverflowMenuOption>
    </>
);

interface CollectionSortOrderMenuProps {
    open: boolean;
    onClose: () => void;
    overFlowMenuIconRef: React.MutableRefObject<SVGSVGElement>;
    onAscClick: () => void;
    onDescClick: () => void;
}

const CollectionSortOrderMenu: React.FC<CollectionSortOrderMenuProps> = ({
    open,
    onClose,
    overFlowMenuIconRef,
    onAscClick,
    onDescClick,
}) => {
    const handleAscClick = () => {
        onClose();
        onAscClick();
    };

    const handleDescClick = () => {
        onClose();
        onDescClick();
    };

    return (
        <StyledMenu
            id={"collection-files-sort"}
            anchorEl={overFlowMenuIconRef.current}
            open={open}
            onClose={onClose}
            MenuListProps={{
                disablePadding: true,
                "aria-labelledby": "collection-files-sort",
            }}
            anchorOrigin={{
                vertical: "bottom",
                horizontal: "right",
            }}
            transformOrigin={{
                vertical: "top",
                horizontal: "right",
            }}
        >
            <OverflowMenuOption onClick={handleDescClick}>
                {t("NEWEST_FIRST")}
            </OverflowMenuOption>
            <OverflowMenuOption onClick={handleAscClick}>
                {t("OLDEST_FIRST")}
            </OverflowMenuOption>
        </StyledMenu>
    );
};
