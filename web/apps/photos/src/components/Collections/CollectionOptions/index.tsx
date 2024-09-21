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

enum CollectionActions {
    SHOW_RENAME_DIALOG,
    RENAME,
    DOWNLOAD,
    ARCHIVE,
    UNARCHIVE,
    CONFIRM_DELETE,
    DELETE_WITH_FILES,
    DELETE_BUT_KEEP_FILES,
    SHOW_SHARE_DIALOG,
    CONFIRM_EMPTY_TRASH,
    EMPTY_TRASH,
    CONFIRM_LEAVE_SHARED_ALBUM,
    LEAVE_SHARED_ALBUM,
    SHOW_SORT_ORDER_MENU,
    UPDATE_COLLECTION_SORT_ORDER_ASC,
    UPDATE_COLLECTION_SORT_ORDER_DESC,
    PIN,
    UNPIN,
    HIDE,
    UNHIDE,
    SHOW_ALBUM_CAST_DIALOG,
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

    const openCollectionSortOrderMenu = () => {
        setCollectionSortOrderMenuView(true);
    };
    const closeCollectionSortOrderMenu = () => {
        setCollectionSortOrderMenuView(false);
    };

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
     * Return a new function that shows an generic error dialog if the original
     * function throws.
     */
    const wrapError = (f: () => Promise<void>) => () => f().catch(handleError);

    /**
     * Return a new function by wrapping an async function in an error handler,
     * and syncing on completion.
     */
    const wrapErrorAndSync = async (f: (...args: any) => Promise<void>) => {
        return async (...args: any) => {
            try {
                await f(...args);
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

    const handleCollectionAction = (
        action: CollectionActions,
        loader = true,
    ) => {
        let callback: Function;
        switch (action) {
            case CollectionActions.SHOW_RENAME_DIALOG:
                callback = showRenameCollectionModal;
                break;
            case CollectionActions.RENAME:
                callback = renameCollection;
                break;
            case CollectionActions.DOWNLOAD:
                callback = downloadCollection;
                break;
            case CollectionActions.ARCHIVE:
                callback = archiveCollection;
                break;
            case CollectionActions.UNARCHIVE:
                callback = unArchiveCollection;
                break;
            case CollectionActions.CONFIRM_DELETE:
                callback = confirmDeleteCollection;
                break;
            case CollectionActions.DELETE_WITH_FILES:
                callback = deleteCollectionAlongWithFiles;
                break;
            case CollectionActions.DELETE_BUT_KEEP_FILES:
                callback = deleteCollectionButKeepFiles;
                break;
            case CollectionActions.SHOW_SHARE_DIALOG:
                callback = showCollectionShareModal;
                break;
            case CollectionActions.CONFIRM_EMPTY_TRASH:
                callback = confirmEmptyTrash;
                break;
            case CollectionActions.EMPTY_TRASH:
                callback = emptyTrash;
                break;
            case CollectionActions.CONFIRM_LEAVE_SHARED_ALBUM:
                callback = confirmLeaveSharedAlbum;
                break;
            case CollectionActions.LEAVE_SHARED_ALBUM:
                callback = leaveSharedAlbum;
                break;
            case CollectionActions.SHOW_SORT_ORDER_MENU:
                callback = openCollectionSortOrderMenu;
                break;
            case CollectionActions.UPDATE_COLLECTION_SORT_ORDER_ASC:
                callback = updateCollectionSortOrderAsc;
                break;
            case CollectionActions.UPDATE_COLLECTION_SORT_ORDER_DESC:
                callback = updateCollectionSortOrderDesc;
                break;

            case CollectionActions.PIN:
                callback = pinAlbum;
                break;
            case CollectionActions.UNPIN:
                callback = unPinAlbum;
                break;
            case CollectionActions.HIDE:
                callback = hideAlbum;
                break;
            case CollectionActions.UNHIDE:
                callback = unHideAlbum;
                break;
            case CollectionActions.SHOW_ALBUM_CAST_DIALOG:
                callback = showCastAlbumDialog;
                break;
            default:
                log.error(`invalid collection action ${action}`);
        }
        return async (...args: any) => {
            try {
                loader && startLoading();
                await callback(...args);
            } catch (e) {
                log.error(`collection action ${action} failed`, e);
                setDialogMessage({
                    title: t("ERROR"),
                    content: t("UNKNOWN_ERROR"),
                    close: { variant: "critical" },
                });
            } finally {
                syncWithRemote(false, true);
                loader && finishLoading();
            }
        };
    };

    const renameCollection = async (newName: string) => {
        if (activeCollection.name !== newName) {
            await CollectionAPI.renameCollection(activeCollection, newName);
        }
    };

    const deleteCollectionAlongWithFiles = async () => {
        await CollectionAPI.deleteCollection(activeCollection.id, false);
        setActiveCollectionID(ALL_SECTION);
    };

    const deleteCollectionButKeepFiles = async () => {
        await CollectionAPI.deleteCollection(activeCollection.id, true);
        setActiveCollectionID(ALL_SECTION);
    };

    const leaveSharedAlbum = async () => {
        await CollectionAPI.leaveSharedAlbum(activeCollection.id);
        setActiveCollectionID(ALL_SECTION);
    };

    const archiveCollection = () => {
        changeCollectionVisibility(activeCollection, ItemVisibility.archived);
    };

    const unArchiveCollection = () => {
        changeCollectionVisibility(activeCollection, ItemVisibility.visible);
    };

    const downloadCollection = () => {
        if (isActiveCollectionDownloadInProgress()) {
            return;
        }
        if (collectionSummaryType == "hiddenItems") {
            const setFilesDownloadProgressAttributes =
                setFilesDownloadProgressAttributesCreator(
                    activeCollection.name,
                    HIDDEN_ITEMS_SECTION,
                    true,
                );
            downloadDefaultHiddenCollectionHelper(
                setFilesDownloadProgressAttributes,
            );
        } else {
            const setFilesDownloadProgressAttributes =
                setFilesDownloadProgressAttributesCreator(
                    activeCollection.name,
                    activeCollection.id,
                    isHiddenCollection(activeCollection),
                );
            downloadCollectionHelper(
                activeCollection.id,
                setFilesDownloadProgressAttributes,
            );
        }
    };

    const showRenameCollectionModal = () => {
        setCollectionNamerAttributes({
            title: t("RENAME_COLLECTION"),
            buttonText: t("RENAME"),
            autoFilledName: activeCollection.name,
            callback: handleCollectionAction(CollectionActions.RENAME),
        });
    };

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
                action: handleCollectionAction(
                    CollectionActions.DELETE_WITH_FILES,
                ),
                variant: "critical",
            },
            secondary: {
                text: t("KEEP_PHOTOS"),
                action: handleCollectionAction(
                    CollectionActions.DELETE_BUT_KEEP_FILES,
                ),
                variant: "primary",
            },
            close: {
                text: t("cancel"),
            },
        });
    };

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

    const handleDownloadCollection = () =>
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
                action: leaveSharedAlbum2,
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

    const leaveSharedAlbum2 = () =>
        void wrapErrorAndSyncLoading(_leaveSharedAlbum);

    const showCastAlbumDialog = () => setShowAlbumCastDialog(true);

    const _pinAlbum = () => changeCollectionOrder(activeCollection, 1);

    const _unpinAlbum = () => changeCollectionOrder(activeCollection, 0);

    const pinAlbum2 = () => wrapErrorAndSync(_pinAlbum);

    const unpinAlbum2 = () => wrapErrorAndSync(_unpinAlbum);

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

    const hideAlbum2 = () => wrapErrorAndSync(_hideAlbum);

    const unhideAlbum2 = () => wrapErrorAndSync(_unhideAlbum);


    const updateCollectionSortOrderAsc = async () => {
        await changeCollectionSortOrder(activeCollection, true);
    };

    const updateCollectionSortOrderDesc = async () => {
        await changeCollectionSortOrder(activeCollection, false);
    };

    const pinAlbum = async () => {
        await changeCollectionOrder(activeCollection, 1);
    };

    const unPinAlbum = async () => {
        await changeCollectionOrder(activeCollection, 0);
    };

    const hideAlbum = async () => {
        await changeCollectionVisibility(
            activeCollection,
            ItemVisibility.hidden,
        );
        setActiveCollectionID(ALL_SECTION);
    };
    const unHideAlbum = async () => {
        await changeCollectionVisibility(
            activeCollection,
            ItemVisibility.visible,
        );
        setActiveCollectionID(HIDDEN_ITEMS_SECTION);
    };

    return (
        <HorizontalFlex sx={{ display: "inline-flex", gap: "16px" }}>
            <QuickOptions
                collectionSummaryType={collectionSummaryType}
                isDownloadInProgress={isActiveCollectionDownloadInProgress}
                onEmptyTrashClick={confirmEmptyTrash}
                onDownloadClick={handleDownloadCollection}
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
                        onClick={handleDownloadCollection}
                    >
                        {t("DOWNLOAD_FAVORITES")}
                    </DownloadOption>
                ) : collectionSummaryType == "uncategorized" ? (
                    <DownloadOption onClick={handleDownloadCollection}>
                        {t("DOWNLOAD_UNCATEGORIZED")}
                    </DownloadOption>
                ) : collectionSummaryType == "hiddenItems" ? (
                    <DownloadOption onClick={handleDownloadCollection}>
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
                        onArchiveClick={archiveAlbum}
                        onUnarchiveClick={unarchiveAlbum}
                        onPinClick={pinAlbum2}
                        onUnpinClick={unpinAlbum2}
                        onHideClick={hideAlbum2}
                        onUnhideClick={unhideAlbum2}
                        onCastClick={showCastAlbumDialog}
                        handleCollectionAction={handleCollectionAction}
                    />
                )}
            </OverflowMenu>
            <CollectionSortOrderMenu
                handleCollectionAction={handleCollectionAction}
                overFlowMenuIconRef={overFlowMenuIconRef}
                collectionSortOrderMenuView={collectionSortOrderMenuView}
                closeCollectionSortOrderMenu={closeCollectionSortOrderMenu}
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
    onArchiveClick: () => void;
    onUnarchiveClick: () => void;
    onPinClick: () => void;
    onUnpinClick: () => void;
    onHideClick: () => void;
    onUnhideClick: () => void;
    onCastClick: () => void;
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => () => Promise<void>;
}

const AlbumCollectionOptions: React.FC<AlbumCollectionOptionsProps> = ({
    isArchived,
    isPinned,
    isHidden,
    onArchiveClick,
    onUnarchiveClick,
    onPinClick,
    onUnpinClick,
    onHideClick,
    onUnhideClick,
    onCastClick,
    handleCollectionAction,
}) => (
    <>
        <OverflowMenuOption
            onClick={handleCollectionAction(
                CollectionActions.SHOW_RENAME_DIALOG,
                false,
            )}
            startIcon={<EditIcon />}
        >
            {t("RENAME_COLLECTION")}
        </OverflowMenuOption>
        <OverflowMenuOption
            onClick={handleCollectionAction(
                CollectionActions.SHOW_SORT_ORDER_MENU,
                false,
            )}
            startIcon={<SortIcon />}
        >
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
            onClick={handleCollectionAction(
                CollectionActions.CONFIRM_DELETE,
                false,
            )}
        >
            {t("DELETE_COLLECTION")}
        </OverflowMenuOption>
        <OverflowMenuOption
            onClick={handleCollectionAction(
                CollectionActions.SHOW_SHARE_DIALOG,
                false,
            )}
            startIcon={<PeopleIcon />}
        >
            {t("SHARE_COLLECTION")}
        </OverflowMenuOption>
        <OverflowMenuOption startIcon={<TvIcon />} onClick={onCastClick}>
            {t("CAST_ALBUM_TO_TV")}
        </OverflowMenuOption>
    </>
);

interface CollectionSortOrderMenuProps {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => () => Promise<void>;
    overFlowMenuIconRef: React.MutableRefObject<SVGSVGElement>;
    collectionSortOrderMenuView: boolean;
    closeCollectionSortOrderMenu: () => void;
}

const CollectionSortOrderMenu: React.FC<CollectionSortOrderMenuProps> = ({
    handleCollectionAction,
    collectionSortOrderMenuView,
    closeCollectionSortOrderMenu,
    overFlowMenuIconRef,
}) => {
    const setCollectionSortOrderToAsc = () => {
        closeCollectionSortOrderMenu();
        handleCollectionAction(
            CollectionActions.UPDATE_COLLECTION_SORT_ORDER_ASC,
        )();
    };

    const setCollectionSortOrderToDesc = () => {
        closeCollectionSortOrderMenu();
        handleCollectionAction(
            CollectionActions.UPDATE_COLLECTION_SORT_ORDER_DESC,
        )();
    };
    return (
        <StyledMenu
            id={"collection-files-sort"}
            anchorEl={overFlowMenuIconRef.current}
            open={collectionSortOrderMenuView}
            onClose={closeCollectionSortOrderMenu}
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
            <OverflowMenuOption onClick={setCollectionSortOrderToDesc}>
                {t("NEWEST_FIRST")}
            </OverflowMenuOption>
            <OverflowMenuOption onClick={setCollectionSortOrderToAsc}>
                {t("OLDEST_FIRST")}
            </OverflowMenuOption>
        </StyledMenu>
    );
};
