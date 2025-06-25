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
import { assertionFailed } from "ente-base/assert";
import { SpacedRow } from "ente-base/components/containers";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import { SingleInputDialog } from "ente-base/components/SingleInputDialog";
import { useModalVisibility } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import {
    isArchivedCollection,
    isPinnedCollection,
} from "ente-gallery/services/magic-metadata";
import { CollectionOrder, type Collection } from "ente-media/collection";
import { ItemVisibility } from "ente-media/file-metadata";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "ente-new/photos/components/gallery/ListHeader";
import {
    isHiddenCollection,
    leaveSharedCollection,
    renameCollection,
    updateCollectionOrder,
    updateCollectionSortOrder,
    updateCollectionVisibility,
} from "ente-new/photos/services/collection";
import {
    PseudoCollectionID,
    type CollectionSummary,
    type CollectionSummaryType,
} from "ente-new/photos/services/collection-summary";
import { emptyTrash } from "ente-new/photos/services/trash";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import React, { useCallback, useContext, useRef } from "react";
import { Trans } from "react-i18next";
import * as CollectionAPI from "services/collectionService";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";
import {
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
    setFilesDownloadProgressAttributesCreator,
    isActiveCollectionDownloadInProgress,
}) => {
    const { showMiniDialog, onGenericError } = useBaseContext();
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();
    const { syncWithRemote } = useContext(GalleryContext);
    const overflowMenuIconRef = useRef<SVGSVGElement>(null);

    const { show: showSortOrderMenu, props: sortOrderMenuVisibilityProps } =
        useModalVisibility();
    const { show: showAlbumNameInput, props: albumNameInputVisibilityProps } =
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

    const handleRenameCollection = useCallback(
        async (newName: string) => {
            if (activeCollection.name !== newName) {
                await renameCollection(activeCollection, newName);
                void syncWithRemote(false, true);
            }
        },
        [activeCollection],
    );

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
        setActiveCollectionID(PseudoCollectionID.all);
    });

    const deleteCollectionButKeepFiles = wrap(async () => {
        await CollectionAPI.deleteCollection(activeCollection.id, true);
        setActiveCollectionID(PseudoCollectionID.all);
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
        setActiveCollectionID(PseudoCollectionID.all);
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
        updateCollectionVisibility(activeCollection, ItemVisibility.archived),
    );

    const unarchiveAlbum = wrap(() =>
        updateCollectionVisibility(activeCollection, ItemVisibility.visible),
    );

    const confirmLeaveSharedAlbum = () =>
        showMiniDialog({
            title: t("leave_shared_album_title"),
            message: t("leave_shared_album_message"),
            continue: {
                text: t("leave_shared_album"),
                color: "critical",
                action: leaveSharedAlbum,
            },
        });

    const leaveSharedAlbum = wrap(async () => {
        await leaveSharedCollection(activeCollection.id);
        setActiveCollectionID(PseudoCollectionID.all);
    });

    const pinAlbum = wrap(() =>
        updateCollectionOrder(activeCollection, CollectionOrder.pinned),
    );

    const unpinAlbum = wrap(() =>
        updateCollectionOrder(activeCollection, CollectionOrder.default),
    );

    const hideAlbum = wrap(async () => {
        await updateCollectionVisibility(
            activeCollection,
            ItemVisibility.hidden,
        );
        setActiveCollectionID(PseudoCollectionID.all);
    });

    const unhideAlbum = wrap(async () => {
        await updateCollectionVisibility(
            activeCollection,
            ItemVisibility.visible,
        );
        setActiveCollectionID(PseudoCollectionID.hiddenItems);
    });

    const changeSortOrderAsc = wrap(() =>
        updateCollectionSortOrder(activeCollection, true),
    );

    const changeSortOrderDesc = wrap(() =>
        updateCollectionSortOrder(activeCollection, false),
    );

    let menuOptions: React.ReactNode[] = [];
    // MUI doesn't let us use fragments to pass multiple menu items, so we need
    // to instead put them in an array. This also necessitates giving each a
    // unique key.
    switch (collectionSummaryType) {
        case "trash":
            menuOptions = [
                <EmptyTrashOption key="trash" onClick={confirmEmptyTrash} />,
            ];
            break;

        case "favorites":
            menuOptions = [
                <DownloadOption
                    key="download"
                    isDownloadInProgress={isActiveCollectionDownloadInProgress}
                    onClick={downloadCollection}
                >
                    {t("download_favorites")}
                </DownloadOption>,
                <OverflowMenuOption
                    key="share"
                    onClick={onCollectionShare}
                    startIcon={<PeopleIcon />}
                >
                    {t("share_favorites")}
                </OverflowMenuOption>,
                <OverflowMenuOption
                    key="cast"
                    startIcon={<TvIcon />}
                    onClick={onCollectionCast}
                >
                    {t("cast_to_tv")}
                </OverflowMenuOption>,
            ];
            break;

        case "uncategorized":
            menuOptions = [
                <DownloadOption key="download" onClick={downloadCollection}>
                    {t("download_uncategorized")}
                </DownloadOption>,
            ];
            break;

        case "hiddenItems":
            menuOptions = [
                <DownloadOption
                    key="download-hidden"
                    onClick={downloadCollection}
                >
                    {t("download_hidden_items")}
                </DownloadOption>,
            ];
            break;

        case "incomingShareViewer":
        case "incomingShareCollaborator":
            menuOptions = [
                isArchivedCollection(activeCollection) ? (
                    <OverflowMenuOption
                        key="unarchive"
                        onClick={unarchiveAlbum}
                        startIcon={<UnarchiveIcon />}
                    >
                        {t("unarchive_album")}
                    </OverflowMenuOption>
                ) : (
                    <OverflowMenuOption
                        key="archive"
                        onClick={archiveAlbum}
                        startIcon={<ArchiveOutlinedIcon />}
                    >
                        {t("archive_album")}
                    </OverflowMenuOption>
                ),
                <OverflowMenuOption
                    key="leave"
                    startIcon={<LogoutIcon />}
                    onClick={confirmLeaveSharedAlbum}
                >
                    {t("leave_album")}
                </OverflowMenuOption>,
                <OverflowMenuOption
                    key="cast"
                    startIcon={<TvIcon />}
                    onClick={onCollectionCast}
                >
                    {t("cast_album_to_tv")}
                </OverflowMenuOption>,
            ];
            break;

        default:
            menuOptions = [
                <OverflowMenuOption
                    key="rename"
                    onClick={showAlbumNameInput}
                    startIcon={<EditIcon />}
                >
                    {t("rename_album")}
                </OverflowMenuOption>,
                <OverflowMenuOption
                    key="sort"
                    onClick={showSortOrderMenu}
                    startIcon={<SortIcon />}
                >
                    {t("sort_by")}
                </OverflowMenuOption>,
                isPinnedCollection(activeCollection) ? (
                    <OverflowMenuOption
                        key="unpin"
                        onClick={unpinAlbum}
                        startIcon={<PushPinOutlinedIcon />}
                    >
                        {t("unpin_album")}
                    </OverflowMenuOption>
                ) : (
                    <OverflowMenuOption
                        key="pin"
                        onClick={pinAlbum}
                        startIcon={<PushPinIcon />}
                    >
                        {t("pin_album")}
                    </OverflowMenuOption>
                ),
                ...(!isHiddenCollection(activeCollection)
                    ? [
                          isArchivedCollection(activeCollection) ? (
                              <OverflowMenuOption
                                  key="unarchive"
                                  onClick={unarchiveAlbum}
                                  startIcon={<UnarchiveIcon />}
                              >
                                  {t("unarchive_album")}
                              </OverflowMenuOption>
                          ) : (
                              <OverflowMenuOption
                                  key="archive"
                                  onClick={archiveAlbum}
                                  startIcon={<ArchiveOutlinedIcon />}
                              >
                                  {t("archive_album")}
                              </OverflowMenuOption>
                          ),
                      ]
                    : []),
                isHiddenCollection(activeCollection) ? (
                    <OverflowMenuOption
                        key="unhide"
                        onClick={unhideAlbum}
                        startIcon={<VisibilityOutlinedIcon />}
                    >
                        {t("unhide_collection")}
                    </OverflowMenuOption>
                ) : (
                    <OverflowMenuOption
                        key="hide"
                        onClick={hideAlbum}
                        startIcon={<VisibilityOffOutlinedIcon />}
                    >
                        {t("hide_collection")}
                    </OverflowMenuOption>
                ),
                <OverflowMenuOption
                    key="delete"
                    startIcon={<DeleteOutlinedIcon />}
                    onClick={confirmDeleteCollection}
                >
                    {t("delete_album")}
                </OverflowMenuOption>,
                <OverflowMenuOption
                    key="share"
                    onClick={onCollectionShare}
                    startIcon={<PeopleIcon />}
                >
                    {t("share_album")}
                </OverflowMenuOption>,
                <OverflowMenuOption
                    key="cast"
                    startIcon={<TvIcon />}
                    onClick={onCollectionCast}
                >
                    {t("cast_album_to_tv")}
                </OverflowMenuOption>,
            ];
            break;
    }

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
                triggerButtonIcon={<MoreHorizIcon ref={overflowMenuIconRef} />}
            >
                {...menuOptions}
            </OverflowMenu>
            <CollectionSortOrderMenu
                {...sortOrderMenuVisibilityProps}
                overflowMenuIconRef={overflowMenuIconRef}
                onAscClick={changeSortOrderAsc}
                onDescClick={changeSortOrderDesc}
            />
            <SingleInputDialog
                {...albumNameInputVisibilityProps}
                title={t("rename_album")}
                label={t("album_name")}
                initialValue={activeCollection?.name}
                submitButtonColor="primary"
                submitButtonTitle={t("rename")}
                onSubmit={handleRenameCollection}
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
    type == "album" ||
    type == "folder" ||
    type == "favorites" ||
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
    type == "album" ||
    type == "folder" ||
    type == "favorites" ||
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
                  : collectionSummaryType == "favorites"
                    ? t("share_favorites")
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

interface CollectionSortOrderMenuProps {
    open: boolean;
    onClose: () => void;
    overflowMenuIconRef: React.RefObject<SVGSVGElement>;
    onAscClick: () => void;
    onDescClick: () => void;
}

const CollectionSortOrderMenu: React.FC<CollectionSortOrderMenuProps> = ({
    open,
    onClose,
    overflowMenuIconRef,
    onAscClick,
    onDescClick,
}) => {
    const handleAscClick = () => {
        onAscClick();
        onClose();
    };

    const handleDescClick = () => {
        onDescClick();
        onClose();
    };

    return (
        <Menu
            id="collection-files-sort"
            anchorEl={overflowMenuIconRef.current}
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
