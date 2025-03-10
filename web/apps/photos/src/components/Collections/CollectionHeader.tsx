import { assertionFailed } from "@/base/assert";
import { SpacedRow } from "@/base/components/containers";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "@/base/components/OverflowMenu";
import { useModalVisibility } from "@/base/components/utils/modal";
import { useBaseContext } from "@/base/context";
import {
    isArchivedCollection,
    isPinnedCollection,
} from "@/gallery/services/magic-metadata";
import type { Collection } from "@/media/collection";
import { ItemVisibility } from "@/media/file-metadata";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "@/new/photos/components/gallery/ListHeader";
import {
    ALL_SECTION,
    HIDDEN_ITEMS_SECTION,
    isHiddenCollection,
} from "@/new/photos/services/collection";
import type {
    CollectionSummary,
    CollectionSummaryType,
} from "@/new/photos/services/collection/ui";
import { clearLocalTrash, emptyTrash } from "@/new/photos/services/collections";
import { usePhotosAppContext } from "@/new/photos/types/context";
import ArchiveOutlinedIcon from "@mui/icons-material/ArchiveOutlined";
import DeleteOutlinedIcon from "@mui/icons-material/DeleteOutlined";
import EditIcon from "@mui/icons-material/Edit";
import FavoriteRoundedIcon from "@mui/icons-material/FavoriteRounded";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import LinkIcon from "@mui/icons-material/Link";
import LogoutIcon from "@mui/icons-material/Logout";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import PeopleIcon from "@mui/icons-material/People";
import PushPinIcon from "@mui/icons-material/PushPin";
import PushPinOutlinedIcon from "@mui/icons-material/PushPinOutlined";
import SortIcon from "@mui/icons-material/Sort";
import TvIcon from "@mui/icons-material/Tv";
import UnarchiveIcon from "@mui/icons-material/Unarchive";
import VisibilityOffOutlinedIcon from "@mui/icons-material/VisibilityOffOutlined";
import VisibilityOutlinedIcon from "@mui/icons-material/VisibilityOutlined";
import { Box, IconButton, Menu, Stack, Tooltip } from "@mui/material";
import { SetCollectionNamerAttributes } from "components/Collections/CollectionNamer";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import React, { useCallback, useContext, useRef } from "react";
import { Trans } from "react-i18next";
import * as CollectionAPI from "services/collectionService";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";
import {
    changeCollectionOrder,
    changeCollectionSortOrder,
    changeCollectionVisibility,
    downloadCollectionHelper,
    downloadDefaultHiddenCollectionHelper,
} from "utils/collection";

interface CollectionHeaderProps {
    collectionSummary: CollectionSummary;
    activeCollection: Collection;
    setActiveCollectionID: (collectionID: number) => void;
    isActiveCollectionDownloadInProgress: () => boolean;
    onCollectionShare: () => void;
    onCollectionCast: () => void;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator;
}

/**
 * A header shown at the top of the list of photos in the gallery, when the
 * gallery is showing a collection.
 */
export const CollectionHeader: React.FC<CollectionHeaderProps> = (props) => {
    const { collectionSummary } = props;
    if (!collectionSummary) {
        assertionFailed("Gallery/CollectionHeader without a collection");
        return <></>;
    }

    const { name, type, fileCount } = collectionSummary;

    const EndIcon = ({ type }: { type: CollectionSummaryType }) => {
        switch (type) {
            case "favorites":
                return <FavoriteRoundedIcon />;
            case "archived":
                return <ArchiveOutlinedIcon />;
            case "incomingShareViewer":
            case "incomingShareCollaborator":
                return <PeopleIcon />;
            case "outgoingShare":
                return <PeopleIcon />;
            case "sharedOnlyViaLink":
                return <LinkIcon />;
            default:
                return <></>;
        }
    };

    return (
        <GalleryItemsHeaderAdapter>
            <SpacedRow>
                <GalleryItemsSummary
                    name={name}
                    fileCount={fileCount}
                    endIcon={<EndIcon type={type} />}
                />
                {shouldShowOptions(type) && <CollectionOptions {...props} />}
            </SpacedRow>
        </GalleryItemsHeaderAdapter>
    );
};

const shouldShowOptions = (type: CollectionSummaryType) =>
    type != "all" && type != "archive";

const CollectionOptions: React.FC<CollectionHeaderProps> = ({
    activeCollection,
    collectionSummary,
    setActiveCollectionID,
    onCollectionShare,
    onCollectionCast,
    setCollectionNamerAttributes,
    setFilesDownloadProgressAttributesCreator,
    isActiveCollectionDownloadInProgress,
}) => {
    const { showMiniDialog, onGenericError } = useBaseContext();
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();
    const { syncWithRemote } = useContext(GalleryContext);
    const overFlowMenuIconRef = useRef<SVGSVGElement>(null);

    const { show: showSortOrderMenu, props: sortOrderMenuVisibilityProps } =
        useModalVisibility();

    const { type: collectionSummaryType } = collectionSummary;

    /**
     * Return a new function by wrapping an async function in an error handler,
     * showing the global loading bar when the function runs, and syncing with
     * remote on completion.
     */
    const wrap = useCallback(
        (f: () => Promise<void>) => {
            const wrapped = async () => {
                showLoadingBar();
                try {
                    await f();
                } catch (e) {
                    onGenericError(e);
                } finally {
                    void syncWithRemote(false, true);
                    hideLoadingBar();
                }
            };
            return (): void => void wrapped();
        },
        [showLoadingBar, hideLoadingBar, onGenericError, syncWithRemote],
    );

    const showRenameCollectionModal = () => {
        setCollectionNamerAttributes({
            title: t("rename_album"),
            buttonText: t("rename"),
            autoFilledName: activeCollection.name,
            callback: renameCollection,
        });
    };

    const _renameCollection = async (newName: string) => {
        if (activeCollection.name !== newName) {
            await CollectionAPI.renameCollection(activeCollection, newName);
        }
    };

    const renameCollection = (newName: string) =>
        wrap(() => _renameCollection(newName))();

    const confirmDeleteCollection = () => {
        showMiniDialog({
            title: t("delete_album_title"),
            message: (
                <Trans
                    i18nKey={"delete_album_message"}
                    components={{
                        a: (
                            <Box
                                component={"span"}
                                sx={{ color: "text.base" }}
                            />
                        ),
                    }}
                />
            ),
            continue: {
                text: t("delete_photos"),
                color: "critical",
                action: deleteCollectionAlongWithFiles,
            },
            secondary: {
                text: t("keep_photos"),
                action: deleteCollectionButKeepFiles,
            },
        });
    };

    const deleteCollectionAlongWithFiles = wrap(async () => {
        await CollectionAPI.deleteCollection(activeCollection.id, false);
        setActiveCollectionID(ALL_SECTION);
    });

    const deleteCollectionButKeepFiles = wrap(async () => {
        await CollectionAPI.deleteCollection(activeCollection.id, true);
        setActiveCollectionID(ALL_SECTION);
    });

    const confirmEmptyTrash = () =>
        showMiniDialog({
            title: t("empty_trash_title"),
            message: t("empty_trash_message"),
            continue: {
                text: t("empty_trash"),
                color: "critical",
                action: doEmptyTrash,
            },
        });

    const doEmptyTrash = wrap(async () => {
        await emptyTrash();
        await clearLocalTrash();
        setActiveCollectionID(ALL_SECTION);
    });

    const _downloadCollection = () => {
        if (isActiveCollectionDownloadInProgress()) return;

        if (collectionSummaryType == "hiddenItems") {
            return downloadDefaultHiddenCollectionHelper(
                setFilesDownloadProgressAttributesCreator,
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
        void _downloadCollection().catch(onGenericError);

    const archiveAlbum = wrap(() =>
        changeCollectionVisibility(activeCollection, ItemVisibility.archived),
    );

    const unarchiveAlbum = wrap(() =>
        changeCollectionVisibility(activeCollection, ItemVisibility.visible),
    );

    const confirmLeaveSharedAlbum = () => {
        showMiniDialog({
            title: t("leave_shared_album_title"),
            message: t("leave_shared_album_message"),
            continue: {
                text: t("leave_shared_album"),
                color: "critical",
                action: leaveSharedAlbum,
            },
        });
    };

    const leaveSharedAlbum = wrap(async () => {
        await CollectionAPI.leaveSharedAlbum(activeCollection.id);
        setActiveCollectionID(ALL_SECTION);
    });

    const pinAlbum = wrap(() => changeCollectionOrder(activeCollection, 1));

    const unpinAlbum = wrap(() => changeCollectionOrder(activeCollection, 0));

    const hideAlbum = wrap(async () => {
        await changeCollectionVisibility(
            activeCollection,
            ItemVisibility.hidden,
        );
        setActiveCollectionID(ALL_SECTION);
    });

    const unhideAlbum = wrap(async () => {
        await changeCollectionVisibility(
            activeCollection,
            ItemVisibility.visible,
        );
        setActiveCollectionID(HIDDEN_ITEMS_SECTION);
    });

    const changeSortOrderAsc = wrap(() =>
        changeCollectionSortOrder(activeCollection, true),
    );

    const changeSortOrderDesc = wrap(() =>
        changeCollectionSortOrder(activeCollection, false),
    );

    return (
        <Box sx={{ display: "inline-flex", gap: "16px" }}>
            <QuickOptions
                collectionSummaryType={collectionSummaryType}
                isDownloadInProgress={isActiveCollectionDownloadInProgress}
                onEmptyTrashClick={confirmEmptyTrash}
                onDownloadClick={downloadCollection}
                onShareClick={onCollectionShare}
            />

            <OverflowMenu
                ariaID="collection-options"
                triggerButtonIcon={<MoreHorizIcon ref={overFlowMenuIconRef} />}
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
                        {t("download_favorites")}
                    </DownloadOption>
                ) : collectionSummaryType == "uncategorized" ? (
                    <DownloadOption onClick={downloadCollection}>
                        {t("download_uncategorized")}
                    </DownloadOption>
                ) : collectionSummaryType == "hiddenItems" ? (
                    <DownloadOption onClick={downloadCollection}>
                        {t("download_hidden_items")}
                    </DownloadOption>
                ) : collectionSummaryType == "incomingShareViewer" ||
                  collectionSummaryType == "incomingShareCollaborator" ? (
                    <SharedCollectionOptions
                        isArchived={isArchivedCollection(activeCollection)}
                        onArchiveClick={archiveAlbum}
                        onUnarchiveClick={unarchiveAlbum}
                        onLeaveSharedAlbumClick={confirmLeaveSharedAlbum}
                        onCastClick={onCollectionCast}
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
                        onShareClick={onCollectionShare}
                        onCastClick={onCollectionCast}
                    />
                )}
            </OverflowMenu>
            <CollectionSortOrderMenu
                {...sortOrderMenuVisibilityProps}
                overFlowMenuIconRef={overFlowMenuIconRef}
                onAscClick={changeSortOrderAsc}
                onDescClick={changeSortOrderDesc}
            />
        </Box>
    );
};

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
                <ActivityIndicator size="20px" sx={{ m: "12px" }} />
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
    <Tooltip title={t("empty_trash")}>
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
                ? t("download_favorites")
                : collectionSummaryType == "uncategorized"
                  ? t("download_uncategorized")
                  : collectionSummaryType == "hiddenItems"
                    ? t("download_hidden_items")
                    : t("download_album")
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
                ? t("sharing_details")
                : collectionSummaryType == "outgoingShare" ||
                    collectionSummaryType == "sharedOnlyViaLink"
                  ? t("modify_sharing")
                  : t("share_album")
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
        {t("empty_trash")}
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
            isDownloadInProgress?.() ? (
                <ActivityIndicator size="20px" sx={{ cursor: "not-allowed" }} />
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
                startIcon={<UnarchiveIcon />}
            >
                {t("unarchive_album")}
            </OverflowMenuOption>
        ) : (
            <OverflowMenuOption
                onClick={onArchiveClick}
                startIcon={<ArchiveOutlinedIcon />}
            >
                {t("archive_album")}
            </OverflowMenuOption>
        )}
        <OverflowMenuOption
            startIcon={<LogoutIcon />}
            onClick={onLeaveSharedAlbumClick}
        >
            {t("leave_album")}
        </OverflowMenuOption>
        <OverflowMenuOption startIcon={<TvIcon />} onClick={onCastClick}>
            {t("cast_album_to_tv")}
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
            {t("rename_album")}
        </OverflowMenuOption>
        <OverflowMenuOption onClick={onSortClick} startIcon={<SortIcon />}>
            {t("sort_by")}
        </OverflowMenuOption>
        {isPinned ? (
            <OverflowMenuOption
                onClick={onUnpinClick}
                startIcon={<PushPinOutlinedIcon />}
            >
                {t("unpin_album")}
            </OverflowMenuOption>
        ) : (
            <OverflowMenuOption
                onClick={onPinClick}
                startIcon={<PushPinIcon />}
            >
                {t("pin_album")}
            </OverflowMenuOption>
        )}
        {!isHidden && (
            <>
                {isArchived ? (
                    <OverflowMenuOption
                        onClick={onUnarchiveClick}
                        startIcon={<UnarchiveIcon />}
                    >
                        {t("unarchive_album")}
                    </OverflowMenuOption>
                ) : (
                    <OverflowMenuOption
                        onClick={onArchiveClick}
                        startIcon={<ArchiveOutlinedIcon />}
                    >
                        {t("archive_album")}
                    </OverflowMenuOption>
                )}
            </>
        )}
        {isHidden ? (
            <OverflowMenuOption
                onClick={onUnhideClick}
                startIcon={<VisibilityOutlinedIcon />}
            >
                {t("unhide_collection")}
            </OverflowMenuOption>
        ) : (
            <OverflowMenuOption
                onClick={onHideClick}
                startIcon={<VisibilityOffOutlinedIcon />}
            >
                {t("hide_collection")}
            </OverflowMenuOption>
        )}
        <OverflowMenuOption
            startIcon={<DeleteOutlinedIcon />}
            onClick={onDeleteClick}
        >
            {t("delete_album")}
        </OverflowMenuOption>
        <OverflowMenuOption onClick={onShareClick} startIcon={<PeopleIcon />}>
            {t("share_album")}
        </OverflowMenuOption>
        <OverflowMenuOption startIcon={<TvIcon />} onClick={onCastClick}>
            {t("cast_album_to_tv")}
        </OverflowMenuOption>
    </>
);

interface CollectionSortOrderMenuProps {
    open: boolean;
    onClose: () => void;
    overFlowMenuIconRef: React.RefObject<SVGSVGElement>;
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
        <Menu
            id="collection-files-sort"
            anchorEl={overFlowMenuIconRef.current}
            open={open}
            onClose={onClose}
            slotProps={{
                list: {
                    disablePadding: true,
                    "aria-labelledby": "collection-files-sort",
                },
            }}
            anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
            transformOrigin={{ vertical: "top", horizontal: "right" }}
        >
            <OverflowMenuOption onClick={handleDescClick}>
                {t("newest_first")}
            </OverflowMenuOption>
            <OverflowMenuOption onClick={handleAscClick}>
                {t("oldest_first")}
            </OverflowMenuOption>
        </Menu>
    );
};
