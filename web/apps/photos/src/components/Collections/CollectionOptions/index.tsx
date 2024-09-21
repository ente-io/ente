import log from "@/base/log";
import type { Collection } from "@/media/collection";
import { ItemVisibility } from "@/media/file-metadata";
import type { CollectionSummaryType } from "@/new/photos/types/collection";
import { FlexWrapper, HorizontalFlex } from "@ente/shared/components/Container";
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
import { Box, IconButton, Tooltip } from "@mui/material";
import { UnPinIcon } from "components/icons/UnPinIcon";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import type { Dispatch, SetStateAction } from "react";
import { useContext, useRef, useState } from "react";
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

    const showCastAlbumDialog = () => {
        setShowAlbumCastDialog(true);
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

    const emptyTrash = async () => {
        await TrashService.emptyTrash();
        await TrashService.clearLocalTrash();
        setActiveCollectionID(ALL_SECTION);
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
                action: handleCollectionAction(CollectionActions.EMPTY_TRASH),
                text: t("EMPTY_TRASH"),
                variant: "critical",
            },
            close: { text: t("cancel") },
        });

    const confirmLeaveSharedAlbum = () => {
        setDialogMessage({
            title: t("LEAVE_SHARED_ALBUM_TITLE"),
            content: t("LEAVE_SHARED_ALBUM_MESSAGE"),
            proceed: {
                text: t("LEAVE_SHARED_ALBUM"),
                action: handleCollectionAction(
                    CollectionActions.LEAVE_SHARED_ALBUM,
                ),
                variant: "critical",
            },
            close: {
                text: t("cancel"),
            },
        });
    };

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
                handleCollectionAction={handleCollectionAction}
                collectionSummaryType={collectionSummaryType}
                isDownloadInProgress={isActiveCollectionDownloadInProgress()}
            />

            <OverflowMenu
                ariaControls={"collection-options"}
                triggerButtonIcon={<MoreHoriz ref={overFlowMenuIconRef} />}
            >
                {collectionSummaryType == "trash" ? (
                    <TrashCollectionOption
                        handleCollectionAction={handleCollectionAction}
                    />
                ) : collectionSummaryType == "favorites" ? (
                    <OnlyDownloadCollectionOption
                        isDownloadInProgress={isActiveCollectionDownloadInProgress()}
                        handleCollectionAction={handleCollectionAction}
                        downloadOptionText={t("DOWNLOAD_FAVORITES")}
                    />
                ) : collectionSummaryType == "uncategorized" ? (
                    <OnlyDownloadCollectionOption
                        handleCollectionAction={handleCollectionAction}
                        downloadOptionText={t("DOWNLOAD_UNCATEGORIZED")}
                    />
                ) : collectionSummaryType == "hiddenItems" ? (
                    <OnlyDownloadCollectionOption
                        handleCollectionAction={handleCollectionAction}
                        downloadOptionText={t("DOWNLOAD_HIDDEN_ITEMS")}
                    />
                ) : collectionSummaryType == "incomingShareViewer" ||
                  collectionSummaryType == "incomingShareCollaborator" ? (
                    <SharedCollectionOptions
                        isArchived={isArchivedCollection(activeCollection)}
                        handleCollectionAction={handleCollectionAction}
                    />
                ) : (
                    <AlbumCollectionOptions
                        isArchived={isArchivedCollection(activeCollection)}
                        isHidden={isHiddenCollection(activeCollection)}
                        isPinned={isPinnedCollection(activeCollection)}
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

interface QuickOptionsProps {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => () => Promise<void>;
    collectionSummaryType: CollectionSummaryType;
    isDownloadInProgress: boolean;
}

const QuickOptions: React.FC<QuickOptionsProps> = ({
    handleCollectionAction,
    collectionSummaryType,
    isDownloadInProgress,
}) => {
    return (
        <FlexWrapper sx={{ gap: "16px" }}>
            {showEmptyTrashQuickOption(collectionSummaryType) && (
                <EmptyTrashQuickOption
                    handleCollectionAction={handleCollectionAction}
                />
            )}
            {showDownloadQuickOption(collectionSummaryType) &&
                (!isDownloadInProgress ? (
                    <DownloadQuickOption
                        handleCollectionAction={handleCollectionAction}
                        collectionSummaryType={collectionSummaryType}
                    />
                ) : (
                    <EnteSpinner size="20px" sx={{ cursor: "not-allowed" }} />
                ))}
            {showShareQuickOption(collectionSummaryType) && (
                <ShareQuickOption
                    handleCollectionAction={handleCollectionAction}
                    collectionSummaryType={collectionSummaryType}
                />
            )}
        </FlexWrapper>
    );
};

const showEmptyTrashQuickOption = (type: CollectionSummaryType) => {
    return type == "trash";
};

interface EmptyTrashQuickOptionProps {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => () => Promise<void>;
}

const EmptyTrashQuickOption: React.FC<EmptyTrashQuickOptionProps> = ({
    handleCollectionAction,
}) => (
    <Tooltip title={t("EMPTY_TRASH")}>
        <IconButton
            onClick={handleCollectionAction(
                CollectionActions.CONFIRM_EMPTY_TRASH,
                false,
            )}
        >
            <DeleteOutlinedIcon />
        </IconButton>
    </Tooltip>
);

const showDownloadQuickOption = (type: CollectionSummaryType) => {
    return (
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
        type == "pinned"
    );
};

interface DownloadQuickOptionProps {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => () => Promise<void>;
    collectionSummaryType: CollectionSummaryType;
}

const DownloadQuickOption: React.FC<DownloadQuickOptionProps> = ({
    handleCollectionAction,
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
        <IconButton
            onClick={handleCollectionAction(CollectionActions.DOWNLOAD, false)}
        >
            <FileDownloadOutlinedIcon />
        </IconButton>
    </Tooltip>
);

const showShareQuickOption = (type: CollectionSummaryType) => {
    return (
        type == "folder" ||
        type == "album" ||
        type == "outgoingShare" ||
        type == "sharedOnlyViaLink" ||
        type == "archived" ||
        type == "incomingShareViewer" ||
        type == "incomingShareCollaborator" ||
        type == "pinned"
    );
};

interface ShareQuickOptionProps {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => () => Promise<void>;
    collectionSummaryType: CollectionSummaryType;
}

const ShareQuickOption: React.FC<ShareQuickOptionProps> = ({
    handleCollectionAction,
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
        <IconButton
            onClick={handleCollectionAction(
                CollectionActions.SHOW_SHARE_DIALOG,
                false,
            )}
        >
            <PeopleIcon />
        </IconButton>
    </Tooltip>
);

interface TrashCollectionOptionProps {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => () => Promise<void>;
}

export const TrashCollectionOption: React.FC<TrashCollectionOptionProps> = ({
    handleCollectionAction,
}) => (
    <OverflowMenuOption
        color="critical"
        startIcon={<DeleteOutlinedIcon />}
        onClick={handleCollectionAction(
            CollectionActions.CONFIRM_EMPTY_TRASH,
            false,
        )}
    >
        {t("EMPTY_TRASH")}
    </OverflowMenuOption>
);

interface OnlyDownloadCollectionOptionProps {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => () => Promise<void>;
    downloadOptionText?: string;
    isDownloadInProgress?: boolean;
}

const OnlyDownloadCollectionOption: React.FC<
    OnlyDownloadCollectionOptionProps
> = ({
    handleCollectionAction,
    downloadOptionText = t("DOWNLOAD"),
    isDownloadInProgress,
}) => (
    <OverflowMenuOption
        startIcon={
            !isDownloadInProgress ? (
                <FileDownloadOutlinedIcon />
            ) : (
                <EnteSpinner size="20px" sx={{ cursor: "not-allowed" }} />
            )
        }
        onClick={handleCollectionAction(CollectionActions.DOWNLOAD, false)}
    >
        {downloadOptionText}
    </OverflowMenuOption>
);

interface SharedCollectionOptionProps {
    isArchived: boolean;
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => () => Promise<void>;
}

const SharedCollectionOptions: React.FC<SharedCollectionOptionProps> = ({
    isArchived,
    handleCollectionAction,
}) => (
    <>
        {isArchived ? (
            <OverflowMenuOption
                onClick={handleCollectionAction(CollectionActions.UNARCHIVE)}
                startIcon={<Unarchive />}
            >
                {t("UNARCHIVE_COLLECTION")}
            </OverflowMenuOption>
        ) : (
            <OverflowMenuOption
                onClick={handleCollectionAction(CollectionActions.ARCHIVE)}
                startIcon={<ArchiveOutlined />}
            >
                {t("ARCHIVE_COLLECTION")}
            </OverflowMenuOption>
        )}
        <OverflowMenuOption
            startIcon={<LogoutIcon />}
            onClick={handleCollectionAction(
                CollectionActions.CONFIRM_LEAVE_SHARED_ALBUM,
                false,
            )}
        >
            {t("LEAVE_ALBUM")}
        </OverflowMenuOption>
        <OverflowMenuOption
            startIcon={<TvIcon />}
            onClick={handleCollectionAction(
                CollectionActions.SHOW_ALBUM_CAST_DIALOG,
                false,
            )}
        >
            {t("CAST_ALBUM_TO_TV")}
        </OverflowMenuOption>
    </>
);

interface AlbumCollectionOptionsProps {
    isArchived: boolean;
    isPinned: boolean;
    isHidden: boolean;
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => () => Promise<void>;
}

const AlbumCollectionOptions: React.FC<AlbumCollectionOptionsProps> = ({
    isArchived,
    isPinned,
    isHidden,
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
                onClick={handleCollectionAction(CollectionActions.UNPIN, false)}
                startIcon={<UnPinIcon />}
            >
                {t("UNPIN_ALBUM")}
            </OverflowMenuOption>
        ) : (
            <OverflowMenuOption
                onClick={handleCollectionAction(CollectionActions.PIN, false)}
                startIcon={<PushPinOutlined />}
            >
                {t("PIN_ALBUM")}
            </OverflowMenuOption>
        )}
        {!isHidden && (
            <>
                {isArchived ? (
                    <OverflowMenuOption
                        onClick={handleCollectionAction(
                            CollectionActions.UNARCHIVE,
                        )}
                        startIcon={<Unarchive />}
                    >
                        {t("UNARCHIVE_COLLECTION")}
                    </OverflowMenuOption>
                ) : (
                    <OverflowMenuOption
                        onClick={handleCollectionAction(
                            CollectionActions.ARCHIVE,
                        )}
                        startIcon={<ArchiveOutlined />}
                    >
                        {t("ARCHIVE_COLLECTION")}
                    </OverflowMenuOption>
                )}
            </>
        )}
        {isHidden ? (
            <OverflowMenuOption
                onClick={handleCollectionAction(
                    CollectionActions.UNHIDE,
                    false,
                )}
                startIcon={<VisibilityOutlined />}
            >
                {t("UNHIDE_COLLECTION")}
            </OverflowMenuOption>
        ) : (
            <OverflowMenuOption
                onClick={handleCollectionAction(CollectionActions.HIDE, false)}
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
        <OverflowMenuOption
            startIcon={<TvIcon />}
            onClick={handleCollectionAction(
                CollectionActions.SHOW_ALBUM_CAST_DIALOG,
                false,
            )}
        >
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
