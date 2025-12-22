import ArchiveOutlinedIcon from "@mui/icons-material/ArchiveOutlined";
import CheckIcon from "@mui/icons-material/Check";
import DeleteOutlinedIcon from "@mui/icons-material/DeleteOutlined";
import EditIcon from "@mui/icons-material/Edit";
import FavoriteRoundedIcon from "@mui/icons-material/FavoriteRounded";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import LinkIcon from "@mui/icons-material/Link";
import LogoutIcon from "@mui/icons-material/Logout";
import MapOutlinedIcon from "@mui/icons-material/MapOutlined";
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
import { SpacedRow } from "ente-base/components/containers";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import { SingleInputDialog } from "ente-base/components/SingleInputDialog";
import { useModalVisibility } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import type { AddSaveGroup } from "ente-gallery/components/utils/save-groups";
import { downloadAndSaveCollectionFiles } from "ente-gallery/services/save";
import { uniqueFilesByID } from "ente-gallery/utils/file";
import { CollectionOrder, type Collection } from "ente-media/collection";
import { ItemVisibility } from "ente-media/file-metadata";
import type { RemotePullOpts } from "ente-new/photos/components/gallery";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "ente-new/photos/components/gallery/ListHeader";
import { useSettingsSnapshot } from "ente-new/photos/components/utils/use-snapshot";
import {
    defaultHiddenCollectionUserFacingName,
    deleteCollection,
    findDefaultHiddenCollectionIDs,
    isHiddenCollection,
    leaveSharedCollection,
    renameCollection,
    updateCollectionOrder,
    updateCollectionSortOrder,
    updateCollectionVisibility,
    updateShareeCollectionOrder,
} from "ente-new/photos/services/collection";
import {
    PseudoCollectionID,
    type CollectionSummary,
    type CollectionSummaryType,
} from "ente-new/photos/services/collection-summary";
import {
    savedCollectionFiles,
    savedCollections,
} from "ente-new/photos/services/photos-fdb";
import { updateMapEnabled } from "ente-new/photos/services/settings";
import { emptyTrash } from "ente-new/photos/services/trash";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { t } from "i18next";
import React, { useCallback, useRef } from "react";
import { Trans } from "react-i18next";
import type { FileListWithViewerProps } from "../FileListWithViewer";
import { CollectionMapDialog } from "./CollectionMapDialog";

export interface CollectionHeaderProps
    extends Pick<
        FileListWithViewerProps,
        | "onMarkTempDeleted"
        | "onAddFileToCollection"
        | "onRemoteFilesPull"
        | "onVisualFeedback"
        | "fileNormalCollectionIDs"
        | "collectionNameByID"
        | "onSelectCollection"
        | "onSelectPerson"
    > {
    collectionSummary: CollectionSummary;
    activeCollection: Collection | undefined;
    setActiveCollectionID: (collectionID: number) => void;
    isActiveCollectionDownloadInProgress: () => boolean;
    /**
     * Called when an operation (e.g. renaming a collection) completes and wants
     * to perform a full remote pull.
     */
    onRemotePull: (opts?: RemotePullOpts) => Promise<void>;
    onCollectionShare: () => void;
    onCollectionCast: () => void;
    /**
     * A function that can be used to create a UI notification to track the
     * progress of user-initiated download, and to cancel it if needed.
     */
    onAddSaveGroup: AddSaveGroup;
}

/**
 * A header shown at the top of the list of photos in the gallery, when the
 * gallery is showing a collection.
 */
export const CollectionHeader: React.FC<CollectionHeaderProps> = (props) => {
    const { collectionSummary } = props;

    const { name, type, attributes, fileCount } = collectionSummary;

    const EndIcon = () => {
        if (attributes.has("archived")) return <ArchiveOutlinedIcon />;
        if (attributes.has("sharedOnlyViaLink")) return <LinkIcon />;
        if (attributes.has("shared")) return <PeopleIcon />;
        if (attributes.has("userFavorites")) return <FavoriteRoundedIcon />;
        return <></>;
    };

    return (
        <GalleryItemsHeaderAdapter>
            <SpacedRow>
                <GalleryItemsSummary
                    name={name}
                    fileCount={fileCount}
                    endIcon={<EndIcon />}
                />
                {shouldShowOptions(type) && (
                    <CollectionHeaderOptions {...props} />
                )}
            </SpacedRow>
        </GalleryItemsHeaderAdapter>
    );
};

const shouldShowOptions = (type: CollectionSummaryType) =>
    type != "all" && type != "archiveItems";

const CollectionHeaderOptions: React.FC<CollectionHeaderProps> = ({
    activeCollection,
    collectionSummary,
    setActiveCollectionID,
    onRemotePull,
    onCollectionShare,
    onCollectionCast,
    onAddSaveGroup,
    isActiveCollectionDownloadInProgress,
    onMarkTempDeleted,
    onAddFileToCollection,
    onRemoteFilesPull,
    onVisualFeedback,
    fileNormalCollectionIDs,
    collectionNameByID,
    onSelectCollection,
    onSelectPerson,
}) => {
    const { showMiniDialog, onGenericError } = useBaseContext();
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();
    const { mapEnabled, isShareePinEnabled } = useSettingsSnapshot();
    const overflowMenuIconRef = useRef<SVGSVGElement | null>(null);

    const { show: showSortOrderMenu, props: sortOrderMenuVisibilityProps } =
        useModalVisibility();
    const { show: showAlbumNameInput, props: albumNameInputVisibilityProps } =
        useModalVisibility();
    const { show: showMapDialog, props: mapDialogVisibilityProps } =
        useModalVisibility();

    const { type: collectionSummaryType, fileCount } = collectionSummary;

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
                    void onRemotePull({ silent: true });
                    hideLoadingBar();
                }
            };
            return (): void => void wrapped();
        },
        [showLoadingBar, hideLoadingBar, onGenericError, onRemotePull],
    );

    const handleRenameCollection = useCallback(
        async (newName: string) => {
            if (!activeCollection) return;
            if (activeCollection.name !== newName) {
                await renameCollection(activeCollection, newName);
                void onRemotePull({ silent: true });
            }
        },
        [activeCollection, onRemotePull],
    );

    const hasAlbumFiles = fileCount > 0;

    const confirmDeleteCollection = () => {
        if (hasAlbumFiles) {
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
                    text: t("keep_photos"),
                    color: "primary",
                    action: deleteCollectionButKeepFiles,
                },
                secondary: {
                    text: t("delete_photos"),
                    color: "critical",
                    action: deleteCollectionAlongWithFiles,
                },
            });
            return;
        }

        showMiniDialog({
            title: t("delete_album_title"),
            message: (
                <Trans
                    i18nKey={"delete_album_message_no_photos"}
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
                text: t("delete_album"),
                color: "critical",
                action: deleteCollectionAlongWithFiles,
            },
        });
    };

    const deleteCollectionAlongWithFiles = wrap(async () => {
        if (!activeCollection) return;
        await deleteCollection(activeCollection.id);
        setActiveCollectionID(PseudoCollectionID.all);
    });

    const deleteCollectionButKeepFiles = wrap(async () => {
        if (!activeCollection) return;
        await deleteCollection(activeCollection.id, { keepFiles: true });
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

    const _downloadCollection = async () => {
        if (isActiveCollectionDownloadInProgress()) return;

        if (collectionSummaryType == "hiddenItems") {
            const defaultHiddenCollectionsIDs = findDefaultHiddenCollectionIDs(
                await savedCollections(),
            );
            const collectionFiles = await savedCollectionFiles();
            const defaultHiddenCollectionFiles = uniqueFilesByID(
                collectionFiles.filter((file) =>
                    defaultHiddenCollectionsIDs.has(file.collectionID),
                ),
            );
            await downloadAndSaveCollectionFiles(
                defaultHiddenCollectionUserFacingName,
                PseudoCollectionID.hiddenItems,
                defaultHiddenCollectionFiles,
                true,
                onAddSaveGroup,
            );
        } else if (activeCollection) {
            await downloadAndSaveCollectionFiles(
                activeCollection.name,
                activeCollection.id,
                (await savedCollectionFiles()).filter(
                    (file) => file.collectionID == activeCollection.id,
                ),
                isHiddenCollection(activeCollection),
                onAddSaveGroup,
            );
        }
    };

    const downloadCollection = () =>
        void _downloadCollection().catch(onGenericError);

    const archiveAlbum = wrap(async () => {
        if (!activeCollection) return;
        await updateCollectionVisibility(
            activeCollection,
            ItemVisibility.archived,
        );
    });

    const unarchiveAlbum = wrap(async () => {
        if (!activeCollection) return;
        await updateCollectionVisibility(
            activeCollection,
            ItemVisibility.visible,
        );
    });

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
        if (!activeCollection) return;
        await leaveSharedCollection(activeCollection.id);
        setActiveCollectionID(PseudoCollectionID.all);
    });

    const pinAlbum = wrap(async () => {
        if (!activeCollection) return;
        await updateCollectionOrder(activeCollection, CollectionOrder.pinned);
    });

    const unpinAlbum = wrap(async () => {
        if (!activeCollection) return;
        await updateCollectionOrder(activeCollection, CollectionOrder.default);
    });

    const pinSharedAlbum = wrap(async () => {
        if (!activeCollection) return;
        await updateShareeCollectionOrder(
            activeCollection,
            CollectionOrder.pinned,
        );
    });

    const unpinSharedAlbum = wrap(async () => {
        if (!activeCollection) return;
        await updateShareeCollectionOrder(
            activeCollection,
            CollectionOrder.default,
        );
    });

    const hideAlbum = wrap(async () => {
        if (!activeCollection) return;
        await updateCollectionVisibility(
            activeCollection,
            ItemVisibility.hidden,
        );
        setActiveCollectionID(PseudoCollectionID.all);
    });

    const unhideAlbum = wrap(async () => {
        if (!activeCollection) return;
        await updateCollectionVisibility(
            activeCollection,
            ItemVisibility.visible,
        );
        setActiveCollectionID(PseudoCollectionID.hiddenItems);
    });

    const changeSortOrderAsc = wrap(async () => {
        if (!activeCollection) return;
        await updateCollectionSortOrder(activeCollection, true);
    });

    const changeSortOrderDesc = wrap(async () => {
        if (!activeCollection) return;
        await updateCollectionSortOrder(activeCollection, false);
    });

    const handleShowMap = useCallback(async () => {
        if (!mapEnabled) {
            try {
                await updateMapEnabled(true);
            } catch (e) {
                onGenericError(e);
                return;
            }
        }
        showMapDialog();
    }, [mapEnabled, onGenericError, showMapDialog]);

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

        case "userFavorites":
            menuOptions = [
                fileCount && (
                    <DownloadOption
                        key="download"
                        isDownloadInProgress={
                            isActiveCollectionDownloadInProgress
                        }
                        onClick={downloadCollection}
                    >
                        {t("download_favorites")}
                    </DownloadOption>
                ),
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
                fileCount && (
                    <DownloadOption key="download" onClick={downloadCollection}>
                        {t("download_uncategorized")}
                    </DownloadOption>
                ),
            ];
            break;

        case "hiddenItems":
            menuOptions = [
                fileCount && (
                    <DownloadOption
                        key="download-hidden"
                        onClick={downloadCollection}
                    >
                        {t("download_hidden_items")}
                    </DownloadOption>
                ),
            ];
            break;

        case "sharedIncoming":
            menuOptions = [
                // Pin/Unpin for shared incoming collections (behind feature flag)
                ...(isShareePinEnabled
                    ? [
                          collectionSummary.attributes.has("shareePinned") ? (
                              <OverflowMenuOption
                                  key="unpin"
                                  onClick={unpinSharedAlbum}
                                  startIcon={<PushPinOutlinedIcon />}
                              >
                                  {t("unpin_album")}
                              </OverflowMenuOption>
                          ) : (
                              <OverflowMenuOption
                                  key="pin"
                                  onClick={pinSharedAlbum}
                                  startIcon={<PushPinIcon />}
                              >
                                  {t("pin_album")}
                              </OverflowMenuOption>
                          ),
                      ]
                    : []),
                collectionSummary.attributes.has("archived") ? (
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
                shouldShowMapOption(collectionSummary) && (
                    <OverflowMenuOption
                        key="map"
                        onClick={handleShowMap}
                        startIcon={<MapOutlinedIcon />}
                    >
                        {t("map")}
                    </OverflowMenuOption>
                ),
                collectionSummary.attributes.has("pinned") ? (
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
                ...(!activeCollection || !isHiddenCollection(activeCollection)
                    ? [
                          collectionSummary.attributes.has("archived") ? (
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
                activeCollection && isHiddenCollection(activeCollection) ? (
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

    const validMenuOptions = menuOptions.filter((o) => !!o);

    return (
        <Box sx={{ display: "inline-flex", gap: "16px" }}>
            <QuickOptions
                collectionSummary={collectionSummary}
                isDownloadInProgress={isActiveCollectionDownloadInProgress}
                onEmptyTrashClick={confirmEmptyTrash}
                onDownloadClick={downloadCollection}
                onShareClick={onCollectionShare}
            />
            {validMenuOptions.length > 0 && (
                <OverflowMenu
                    ariaID="collection-options"
                    triggerButtonIcon={
                        <MoreHorizIcon ref={overflowMenuIconRef} />
                    }
                >
                    {validMenuOptions}
                </OverflowMenu>
            )}
            <CollectionSortOrderMenu
                {...sortOrderMenuVisibilityProps}
                overflowMenuIconRef={overflowMenuIconRef}
                sortAsc={activeCollection?.pubMagicMetadata?.data.asc ?? false}
                onAscClick={changeSortOrderAsc}
                onDescClick={changeSortOrderDesc}
            />
            <CollectionMapDialog
                {...mapDialogVisibilityProps}
                collectionSummary={collectionSummary}
                activeCollection={activeCollection}
                onRemotePull={onRemotePull}
                onAddSaveGroup={onAddSaveGroup}
                onMarkTempDeleted={onMarkTempDeleted}
                onAddFileToCollection={onAddFileToCollection}
                onRemoteFilesPull={onRemoteFilesPull}
                onVisualFeedback={onVisualFeedback}
                fileNormalCollectionIDs={fileNormalCollectionIDs}
                collectionNameByID={collectionNameByID}
                onSelectCollection={onSelectCollection}
                onSelectPerson={onSelectPerson}
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
    collectionSummary: CollectionSummary;
    isDownloadInProgress: () => boolean;
    onEmptyTrashClick: () => void;
    onDownloadClick: () => void;
    onShareClick: () => void;
}

const QuickOptions: React.FC<QuickOptionsProps> = ({
    onEmptyTrashClick,
    onDownloadClick,
    onShareClick,
    collectionSummary,
    isDownloadInProgress,
}) => (
    <Stack direction="row" sx={{ alignItems: "center", gap: "16px" }}>
        {showEmptyTrashQuickOption(collectionSummary) && (
            <EmptyTrashQuickOption onClick={onEmptyTrashClick} />
        )}
        {showDownloadQuickOption(collectionSummary) &&
            collectionSummary.fileCount > 0 &&
            (isDownloadInProgress() ? (
                <ActivityIndicator size="20px" sx={{ m: "12px" }} />
            ) : (
                <DownloadQuickOption
                    collectionSummary={collectionSummary}
                    onClick={onDownloadClick}
                />
            ))}
        {showShareQuickOption(collectionSummary) && (
            <ShareQuickOption
                collectionSummary={collectionSummary}
                onClick={onShareClick}
            />
        )}
    </Stack>
);

const showEmptyTrashQuickOption = ({ type }: CollectionSummary) =>
    type == "trash";

const EmptyTrashQuickOption: React.FC<OptionProps> = ({ onClick }) => (
    <Tooltip title={t("empty_trash")}>
        <IconButton onClick={onClick}>
            <DeleteOutlinedIcon />
        </IconButton>
    </Tooltip>
);

const showDownloadQuickOption = ({ type, attributes }: CollectionSummary) =>
    type == "album" ||
    type == "folder" ||
    type == "uncategorized" ||
    type == "hiddenItems" ||
    attributes.has("favorites") ||
    attributes.has("shared");

const shouldShowMapOption = ({ type, fileCount }: CollectionSummary) =>
    fileCount > 0 &&
    type !== "all" &&
    type !== "archiveItems" &&
    type !== "trash" &&
    type !== "hiddenItems";

type DownloadQuickOptionProps = OptionProps & {
    collectionSummary: CollectionSummary;
};

const DownloadQuickOption: React.FC<DownloadQuickOptionProps> = ({
    collectionSummary: { type },
    onClick,
}) => (
    <Tooltip
        title={
            type == "userFavorites"
                ? t("download_favorites")
                : type == "uncategorized"
                  ? t("download_uncategorized")
                  : type == "hiddenItems"
                    ? t("download_hidden_items")
                    : t("download_album")
        }
    >
        <IconButton onClick={onClick}>
            <FileDownloadOutlinedIcon />
        </IconButton>
    </Tooltip>
);

const showShareQuickOption = ({ type, attributes }: CollectionSummary) =>
    type == "album" ||
    type == "folder" ||
    attributes.has("favorites") ||
    attributes.has("shared");

interface ShareQuickOptionProps {
    collectionSummary: CollectionSummary;
    onClick: () => void;
}

const ShareQuickOption: React.FC<ShareQuickOptionProps> = ({
    collectionSummary: { attributes },
    onClick,
}) => (
    <Tooltip
        title={
            attributes.has("userFavorites")
                ? t("share_favorites")
                : attributes.has("sharedIncoming")
                  ? t("sharing_details")
                  : attributes.has("shared")
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

interface CollectionSortOrderMenuProps {
    open: boolean;
    onClose: () => void;
    overflowMenuIconRef: React.RefObject<SVGSVGElement | null>;
    sortAsc: boolean;
    onAscClick: () => void;
    onDescClick: () => void;
}

const CollectionSortOrderMenu: React.FC<CollectionSortOrderMenuProps> = ({
    open,
    onClose,
    overflowMenuIconRef,
    sortAsc,
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
            <OverflowMenuOption
                onClick={handleDescClick}
                endIcon={!sortAsc ? <CheckIcon /> : undefined}
            >
                {t("newest_first")}
            </OverflowMenuOption>
            <OverflowMenuOption
                onClick={handleAscClick}
                endIcon={sortAsc ? <CheckIcon /> : undefined}
            >
                {t("oldest_first")}
            </OverflowMenuOption>
        </Menu>
    );
};
