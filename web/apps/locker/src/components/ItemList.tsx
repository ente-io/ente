import AddOutlinedIcon from "@mui/icons-material/AddOutlined";
import CheckCircleRoundedIcon from "@mui/icons-material/CheckCircleRounded";
import ClearRoundedIcon from "@mui/icons-material/ClearRounded";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import DeleteSweepOutlinedIcon from "@mui/icons-material/DeleteSweepOutlined";
import EditOutlinedIcon from "@mui/icons-material/EditOutlined";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import FolderOutlinedIcon from "@mui/icons-material/FolderOutlined";
import SearchIcon from "@mui/icons-material/Search";
import ShareOutlinedIcon from "@mui/icons-material/ShareOutlined";
import StarIcon from "@mui/icons-material/Star";
import {
    Box,
    Button,
    ButtonBase,
    Chip,
    Dialog,
    DialogContent,
    DialogTitle,
    IconButton,
    InputAdornment,
    Snackbar,
    Stack,
    TextField,
    Tooltip,
    Typography,
} from "@mui/material";
import { ensureLocalUser } from "ente-accounts-rs/services/user";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import { isHTTPErrorWithStatus } from "ente-base/http";
import { formattedDate } from "ente-base/i18n-date";
import log from "ente-base/log";
import { t } from "i18next";
import React, { useCallback, useMemo, useState } from "react";
import {
    deleteLockerFileShareLink,
    downloadLockerFile,
    getOrCreateLockerFileShareLink,
    type LockerFileShareLinkSummary,
} from "services/remote";
import type { LockerCollection, LockerItem } from "types";
import {
    canEditCollection,
    canOpenCollectionSharing,
    canShareLockerFileLink,
    getItemTitle,
    hasDownloadableObject,
    isImportantCollection,
    visibleLockerCollections,
} from "types";
import { ItemCard } from "./ItemCard";
import { ItemDetailView } from "./ItemDetailView";
import { LockerFileLinkDialog } from "./LockerFileLinkDialog";

interface ItemListProps {
    collections: LockerCollection[];
    masterKey?: string;
    trashItems?: LockerItem[];
    isTrashView: boolean;
    isCollectionsView: boolean;
    selectedCollectionID: number | null;
    fileShareLinksByFileID: Map<number, LockerFileShareLinkSummary>;
    onSelectCollection: (id: number | null) => void;
    onEditItem?: (item: LockerItem) => void;
    onDeleteItem?: (item: LockerItem) => void;
    onDeleteItems?: (items: LockerItem[]) => void;
    onPermanentlyDelete?: (items: LockerItem[]) => void;
    onRestoreItem?: (item: LockerItem, collectionID: number) => void;
    onEmptyTrash?: () => void;
    onRenameCollection?: (collectionID: number, newName: string) => void;
    onDeleteCollection?: (collectionID: number) => void;
    onCreateCollection?: (name: string) => Promise<number>;
    onShareCollection?: (collection: LockerCollection) => void;
}

const contentMaxWidth = 620;

export const ItemList: React.FC<ItemListProps> = ({
    collections,
    masterKey,
    trashItems,
    isTrashView,
    isCollectionsView,
    selectedCollectionID,
    fileShareLinksByFileID,
    onSelectCollection,
    onEditItem,
    onDeleteItem,
    onDeleteItems,
    onPermanentlyDelete,
    onRestoreItem,
    onEmptyTrash,
    onRenameCollection,
    onDeleteCollection,
    onCreateCollection,
    onShareCollection,
}) => {
    const currentUserID = ensureLocalUser().id;
    const [searchTerm, setSearchTerm] = useState("");
    const [selectedItem, setSelectedItem] = useState<LockerItem | null>(null);
    const [restoreItem, setRestoreItem] = useState<LockerItem | null>(null);
    const [restoreCollectionID, setRestoreCollectionID] = useState<
        number | null
    >(null);
    const [renameCollectionID, setRenameCollectionID] = useState<number | null>(
        null,
    );
    const [renameValue, setRenameValue] = useState("");
    const [createCollectionOpen, setCreateCollectionOpen] = useState(false);
    const [createCollectionName, setCreateCollectionName] = useState("");
    const [creatingCollection, setCreatingCollection] = useState(false);
    const [createCollectionError, setCreateCollectionError] = useState<
        string | null
    >(null);
    const [homeSelectedCollectionIDs, setHomeSelectedCollectionIDs] = useState<
        number[]
    >([]);
    const [selectionMode, setSelectionMode] = useState(false);
    const [selectedItemIDs, setSelectedItemIDs] = useState<number[]>([]);
    const [bulkDownloading, setBulkDownloading] = useState(false);
    const [bulkDownloadProgress, setBulkDownloadProgress] = useState<{
        completed: number;
        total: number;
    } | null>(null);
    const [activeFileLinkItem, setActiveFileLinkItem] =
        useState<LockerItem | null>(null);
    const [activeFileLink, setActiveFileLink] = useState<{
        linkID: string;
        url: string;
    } | null>(null);
    const [isCreatingFileLink, setIsCreatingFileLink] = useState(false);
    const [isDeletingFileLink, setIsDeletingFileLink] = useState(false);
    const [feedbackMessage, setFeedbackMessage] = useState<string | null>(null);
    const [knownFileShareLinksByID, setKnownFileShareLinksByID] = useState(
        fileShareLinksByFileID,
    );

    React.useEffect(() => {
        setKnownFileShareLinksByID(fileShareLinksByFileID);
    }, [fileShareLinksByFileID]);

    const displayCollections = useMemo(
        () => visibleLockerCollections(collections),
        [collections],
    );
    const allItems = useMemo(() => {
        const itemsByID = new Map<number, LockerItem>();
        for (const collection of collections) {
            for (const item of collection.items) {
                const existing = itemsByID.get(item.id);
                if (!existing) {
                    itemsByID.set(item.id, item);
                    continue;
                }

                itemsByID.set(item.id, {
                    ...existing,
                    ownerID: existing.ownerID ?? item.ownerID,
                    collectionIDs: Array.from(
                        new Set([
                            ...existing.collectionIDs,
                            ...item.collectionIDs,
                        ]),
                    ),
                });
            }
        }
        return [...itemsByID.values()];
    }, [collections]);
    const selectedCollection = useMemo(
        () =>
            selectedCollectionID === null
                ? null
                : (collections.find(
                      (collection) => collection.id === selectedCollectionID,
                  ) ?? null),
        [collections, selectedCollectionID],
    );
    const trimmedSearch = searchTerm.trim();
    const searchQuery = trimmedSearch.toLowerCase();
    const searchActive = searchQuery.length > 0;
    const isHomeView =
        !searchActive &&
        !isTrashView &&
        !isCollectionsView &&
        selectedCollectionID === null;

    const searchBaseItems = useMemo(() => {
        if (isTrashView) {
            return trashItems ?? [];
        }
        if (selectedCollection) {
            return selectedCollection.items;
        }
        return allItems;
    }, [allItems, isTrashView, selectedCollection, trashItems]);

    const filteredItems = useMemo(() => {
        if (!searchActive) {
            return searchBaseItems;
        }

        return searchBaseItems.filter((item) => {
            if (getItemTitle(item).toLowerCase().includes(searchQuery)) {
                return true;
            }

            return Object.values(
                item.data as unknown as Record<string, unknown>,
            ).some(
                (value) =>
                    typeof value === "string" &&
                    value.toLowerCase().includes(searchQuery),
            );
        });
    }, [searchActive, searchBaseItems, searchQuery]);

    const filteredCollections = useMemo(() => {
        if (!searchActive || isTrashView) {
            return [];
        }

        return displayCollections.filter((collection) =>
            collection.name.toLowerCase().includes(searchQuery),
        );
    }, [displayCollections, isTrashView, searchActive, searchQuery]);

    const sortedItems = useMemo(
        () =>
            [...filteredItems].sort(
                (a, b) =>
                    (b.updatedAt ?? b.createdAt ?? 0) -
                    (a.updatedAt ?? a.createdAt ?? 0),
            ),
        [filteredItems],
    );
    const homeFilteredItems = useMemo(() => {
        if (!isHomeView || homeSelectedCollectionIDs.length === 0) {
            return sortedItems;
        }

        return sortedItems.filter((item) =>
            homeSelectedCollectionIDs.every((collectionID) =>
                item.collectionIDs.includes(collectionID),
            ),
        );
    }, [homeSelectedCollectionIDs, isHomeView, sortedItems]);
    const visibleItems = useMemo(() => {
        if (isCollectionsView) {
            return [];
        }
        return isHomeView ? homeFilteredItems : sortedItems;
    }, [homeFilteredItems, isCollectionsView, isHomeView, sortedItems]);
    const visibleSelectableItems = useMemo(() => visibleItems, [visibleItems]);
    const visibleSelectableItemIDs = useMemo(
        () => visibleSelectableItems.map((item) => item.id),
        [visibleSelectableItems],
    );
    const selectedVisibleItems = useMemo(() => {
        const selectedIDSet = new Set(selectedItemIDs);
        return visibleSelectableItems.filter((item) =>
            selectedIDSet.has(item.id),
        );
    }, [selectedItemIDs, visibleSelectableItems]);
    const selectedDownloadableItems = useMemo(
        () =>
            selectedVisibleItems.filter(
                (item) => item.type === "file" && hasDownloadableObject(item),
            ),
        [selectedVisibleItems],
    );
    const selectedOwnedItems = useMemo(
        () =>
            selectedVisibleItems.filter(
                (item) => (item.ownerID ?? currentUserID) === currentUserID,
            ),
        [currentUserID, selectedVisibleItems],
    );
    const selectedItemIDSet = useMemo(
        () => new Set(selectedItemIDs),
        [selectedItemIDs],
    );
    const canBulkSelectVisibleItems =
        !isTrashView && !isCollectionsView && visibleSelectableItems.length > 0;
    const skippedSharedSelectionCount =
        selectedVisibleItems.length - selectedOwnedItems.length;
    const skippedDownloadSelectionCount =
        selectedVisibleItems.length - selectedDownloadableItems.length;
    const allVisibleItemsSelected =
        visibleSelectableItemIDs.length > 0 &&
        selectedVisibleItems.length === visibleSelectableItemIDs.length;
    const canNativeShare =
        typeof navigator !== "undefined" &&
        typeof navigator.share === "function";

    const handleRestoreConfirm = useCallback(() => {
        if (restoreItem && restoreCollectionID !== null && onRestoreItem) {
            onRestoreItem(restoreItem, restoreCollectionID);
        }
        setRestoreItem(null);
        setRestoreCollectionID(null);
    }, [onRestoreItem, restoreCollectionID, restoreItem]);

    const handleRenameConfirm = useCallback(() => {
        if (
            renameCollectionID !== null &&
            renameValue.trim() &&
            onRenameCollection
        ) {
            onRenameCollection(renameCollectionID, renameValue.trim());
        }
        setRenameCollectionID(null);
        setRenameValue("");
    }, [onRenameCollection, renameCollectionID, renameValue]);

    const handleCreateCollectionConfirm = useCallback(async () => {
        if (!onCreateCollection || !createCollectionName.trim()) {
            return;
        }

        setCreatingCollection(true);
        setCreateCollectionError(null);
        try {
            const newCollectionID = await onCreateCollection(
                createCollectionName.trim(),
            );
            setCreateCollectionOpen(false);
            setCreateCollectionName("");
            onSelectCollection(newCollectionID);
        } catch (error) {
            setCreateCollectionError(
                error instanceof Error
                    ? error.message
                    : t("failedToCreateCollection"),
            );
        } finally {
            setCreatingCollection(false);
        }
    }, [createCollectionName, onCreateCollection, onSelectCollection]);

    const canEditSelectedCollection =
        selectedCollection !== null &&
        canEditCollection(selectedCollection, currentUserID);
    const canShareSelectedCollection =
        selectedCollection !== null &&
        canOpenCollectionSharing(selectedCollection);
    const handleShareSelectedCollection = useCallback(() => {
        if (selectedCollection && onShareCollection) {
            onShareCollection(selectedCollection);
        }
    }, [onShareCollection, selectedCollection]);
    const itemTypeLabel = useCallback((item: LockerItem) => {
        switch (item.type) {
            case "note":
                return t("personalNote");
            case "accountCredential":
                return t("secret");
            case "physicalRecord":
                return t("thing");
            case "emergencyContact":
                return t("emergencyContact");
            case "file":
                return t("document");
        }
    }, []);
    const getItemSecondaryText = useCallback(
        (item: LockerItem) => {
            const parts = [itemTypeLabel(item)];
            const isSharedWithUser =
                (item.ownerID ?? currentUserID) !== currentUserID;
            if (isSharedWithUser) {
                parts.push(t("sharedWithYou"));
            }
            if (item.updatedAt ?? item.createdAt) {
                parts.push(
                    formattedDate(
                        new Date((item.updatedAt ?? item.createdAt!) / 1000),
                    ),
                );
            }
            return parts.join(" • ");
        },
        [currentUserID, itemTypeLabel],
    );
    const toggleHomeCollection = useCallback((collectionID: number) => {
        setHomeSelectedCollectionIDs((current) =>
            current.includes(collectionID)
                ? current.filter((id) => id !== collectionID)
                : [...current, collectionID],
        );
    }, []);
    const clearHomeCollectionSelection = useCallback(() => {
        setHomeSelectedCollectionIDs([]);
    }, []);
    const startSelectionModeForItem = useCallback((item: LockerItem) => {
        setSelectionMode(true);
        setSelectedItemIDs([item.id]);
        setSelectedItem(null);
    }, []);
    const stopSelectionMode = useCallback(() => {
        setSelectionMode(false);
        setSelectedItemIDs([]);
        setBulkDownloadProgress(null);
    }, []);
    const toggleItemSelection = useCallback((item: LockerItem) => {
        setSelectedItemIDs((current) =>
            current.includes(item.id)
                ? current.filter((id) => id !== item.id)
                : [...current, item.id],
        );
    }, []);
    const toggleSelectAllVisibleItems = useCallback(() => {
        setSelectedItemIDs((current) =>
            current.length === visibleSelectableItemIDs.length
                ? []
                : visibleSelectableItemIDs,
        );
    }, [visibleSelectableItemIDs]);
    const closeFileLinkDialog = useCallback(() => {
        if (isCreatingFileLink || isDeletingFileLink) {
            return;
        }
        setActiveFileLinkItem(null);
        setActiveFileLink(null);
    }, [isCreatingFileLink, isDeletingFileLink]);
    const openFileLinkDialog = useCallback(
        async (item: LockerItem) => {
            if (!masterKey) {
                return;
            }
            if (!canShareLockerFileLink(item, currentUserID)) {
                setFeedbackMessage(t("shareNotSupportedForSharedFiles"));
                return;
            }

            setActiveFileLinkItem(item);
            setActiveFileLink(null);
            setIsCreatingFileLink(true);
            try {
                const link = await getOrCreateLockerFileShareLink(
                    item.id,
                    masterKey,
                );
                setActiveFileLink(link);
                setKnownFileShareLinksByID((current) => {
                    const next = new Map(current);
                    next.set(item.id, {
                        linkID: link.linkID,
                        fileID: item.id,
                        validTill: link.validTill,
                        enableDownload: link.enableDownload ?? true,
                        passwordEnabled: link.passwordEnabled ?? false,
                    });
                    return next;
                });
            } catch (error) {
                log.error(
                    `Failed to create share link for file ${item.id}`,
                    error,
                );
                setFeedbackMessage(
                    isHTTPErrorWithStatus(error, 402)
                        ? t("sharingRequiresPaidPlan")
                        : t("failedToCreateShareLink"),
                );
                setActiveFileLinkItem(null);
            } finally {
                setIsCreatingFileLink(false);
            }
        },
        [currentUserID, masterKey],
    );
    const copyActiveFileLink = useCallback(async () => {
        if (!activeFileLink?.url) {
            return;
        }
        await navigator.clipboard.writeText(activeFileLink.url);
        setFeedbackMessage(t("linkCopiedToClipboard"));
    }, [activeFileLink?.url]);
    const shareActiveFileLink = useCallback(async () => {
        if (!activeFileLink?.url) {
            return;
        }

        if (canNativeShare) {
            try {
                await navigator.share({
                    title: activeFileLinkItem
                        ? getItemTitle(activeFileLinkItem)
                        : undefined,
                    url: activeFileLink.url,
                });
                return;
            } catch (error) {
                if (
                    error instanceof DOMException &&
                    error.name === "AbortError"
                ) {
                    return;
                }
            }
        }

        await navigator.clipboard.writeText(activeFileLink.url);
        setFeedbackMessage(t("linkCopiedToClipboard"));
    }, [activeFileLink?.url, activeFileLinkItem, canNativeShare]);
    const deleteActiveFileLink = useCallback(async () => {
        if (!activeFileLinkItem) {
            return;
        }
        if (
            !window.confirm(
                `${t("deleteShareLinkDialogTitle")}\n\n${t("deleteShareLinkConfirmation")}`,
            )
        ) {
            return;
        }

        setIsDeletingFileLink(true);
        try {
            await deleteLockerFileShareLink(
                activeFileLinkItem.id,
                activeFileLink?.linkID,
            );
            setKnownFileShareLinksByID((current) => {
                const next = new Map(current);
                next.delete(activeFileLinkItem.id);
                return next;
            });
            setFeedbackMessage(t("shareLinkDeletedSuccessfully"));
            setActiveFileLinkItem(null);
            setActiveFileLink(null);
        } catch (error) {
            log.error(
                `Failed to delete share link for file ${activeFileLinkItem.id}`,
                error,
            );
            setFeedbackMessage(t("failedToDeleteShareLink"));
        } finally {
            setIsDeletingFileLink(false);
        }
    }, [activeFileLink?.linkID, activeFileLinkItem]);
    const downloadSelectedFiles = useCallback(async () => {
        if (
            !masterKey ||
            bulkDownloading ||
            selectedDownloadableItems.length === 0
        ) {
            return;
        }

        setBulkDownloading(true);
        setBulkDownloadProgress({
            completed: 0,
            total: selectedDownloadableItems.length,
        });
        try {
            for (const [index, item] of selectedDownloadableItems.entries()) {
                await downloadLockerFile(
                    item.id,
                    getItemTitle(item),
                    masterKey,
                );
                setBulkDownloadProgress({
                    completed: index + 1,
                    total: selectedDownloadableItems.length,
                });
            }
            if (skippedDownloadSelectionCount > 0) {
                setFeedbackMessage(
                    t("downloadSkippedUnavailableFiles", {
                        count: skippedDownloadSelectionCount,
                    }),
                );
            }
            stopSelectionMode();
        } catch (error) {
            log.error("Failed to download selected Locker files", error);
            setFeedbackMessage(t("downloadFailed"));
        } finally {
            setBulkDownloading(false);
            setBulkDownloadProgress(null);
        }
    }, [
        bulkDownloading,
        masterKey,
        selectedDownloadableItems,
        skippedDownloadSelectionCount,
        stopSelectionMode,
    ]);
    const deleteSelectedFiles = useCallback(() => {
        if (selectedOwnedItems.length === 0) {
            if (skippedSharedSelectionCount > 0) {
                setFeedbackMessage(
                    t("actionNotSupportedForSharedFiles", {
                        count: skippedSharedSelectionCount,
                    }),
                );
            }
            return;
        }

        if (skippedSharedSelectionCount > 0) {
            setFeedbackMessage(
                t("actionNotSupportedForSharedFiles", {
                    count: skippedSharedSelectionCount,
                }),
            );
        }

        onDeleteItems?.(selectedOwnedItems);
    }, [onDeleteItems, selectedOwnedItems, skippedSharedSelectionCount]);

    React.useEffect(() => {
        if (!isHomeView && homeSelectedCollectionIDs.length > 0) {
            setHomeSelectedCollectionIDs([]);
        }
    }, [homeSelectedCollectionIDs.length, isHomeView]);
    React.useEffect(() => {
        if (selectionMode && selectedItemIDs.length === 0) {
            setSelectionMode(false);
        }
    }, [selectedItemIDs.length, selectionMode]);
    React.useEffect(() => {
        if (
            isTrashView ||
            isCollectionsView ||
            visibleSelectableItemIDs.length === 0
        ) {
            setSelectionMode(false);
            setSelectedItemIDs([]);
            return;
        }

        const visibleItemIDSet = new Set(visibleSelectableItemIDs);
        setSelectedItemIDs((current) =>
            current.filter((id) => visibleItemIDSet.has(id)),
        );
    }, [isCollectionsView, isTrashView, visibleSelectableItemIDs]);

    return (
        <Stack
            sx={{ flex: 1, minHeight: 0, overflow: "hidden", height: "100%" }}
        >
            <Box
                sx={{
                    flex: 1,
                    minHeight: 0,
                    overflowY: "auto",
                    overscrollBehavior: "contain",
                    WebkitOverflowScrolling: "touch",
                }}
            >
                <Box
                    sx={{
                        background:
                            "linear-gradient(135deg, #1071FF 0%, #0056CC 100%)",
                        px: { xs: 2, sm: 3 },
                        pb: 1.75,
                        pt: 0.25,
                    }}
                >
                    <Box sx={{ maxWidth: contentMaxWidth, mx: "auto" }}>
                        <TextField
                            size="small"
                            placeholder={t("searchHint")}
                            value={searchTerm}
                            onChange={(event) =>
                                setSearchTerm(event.target.value)
                            }
                            variant="outlined"
                            fullWidth
                            slotProps={{
                                input: {
                                    startAdornment: (
                                        <InputAdornment position="start">
                                            <SearchIcon
                                                sx={{
                                                    fontSize: 20,
                                                    color: "text.faint",
                                                }}
                                            />
                                        </InputAdornment>
                                    ),
                                },
                            }}
                            sx={{
                                "& .MuiOutlinedInput-root": {
                                    borderRadius: "24px",
                                    backgroundColor: "background.paper",
                                    "& fieldset": {
                                        borderColor: "transparent",
                                    },
                                    "&:hover fieldset": {
                                        borderColor: "transparent",
                                    },
                                    "&.Mui-focused fieldset": {
                                        borderColor: "primary.main",
                                    },
                                },
                            }}
                        />
                    </Box>
                </Box>

                <Box
                    sx={{
                        px: { xs: 2, sm: 3 },
                        pb: isTrashView
                            ? 3
                            : "calc(env(safe-area-inset-bottom) + 120px)",
                    }}
                >
                    {isHomeView && (
                        <>
                            <SectionHeader
                                title={t("recents")}
                                countLabel={t("lockerItemsCount", {
                                    count: homeFilteredItems.length,
                                })}
                            />

                            {displayCollections.length > 0 && (
                                <Stack
                                    direction="row"
                                    sx={{
                                        width: "100%",
                                        maxWidth: contentMaxWidth,
                                        mx: "auto",
                                        alignItems: "center",
                                        gap: 1,
                                        mt: -0.25,
                                        mb: 1.75,
                                    }}
                                >
                                    <CollectionChipFilters
                                        collections={displayCollections}
                                        selectedCollectionIDs={
                                            homeSelectedCollectionIDs
                                        }
                                        onToggleCollection={
                                            toggleHomeCollection
                                        }
                                    />
                                    {homeSelectedCollectionIDs.length > 0 && (
                                        <Tooltip title={t("clearSelection")}>
                                            <IconButton
                                                size="small"
                                                onClick={
                                                    clearHomeCollectionSelection
                                                }
                                                sx={{
                                                    width: 32,
                                                    height: 32,
                                                    color: "text.muted",
                                                    border: "1px solid rgba(255, 255, 255, 0.08)",
                                                    backgroundColor:
                                                        "rgba(255, 255, 255, 0.035)",
                                                    "&:hover": {
                                                        backgroundColor:
                                                            "rgba(255, 255, 255, 0.065)",
                                                    },
                                                }}
                                            >
                                                <ClearRoundedIcon
                                                    sx={{ fontSize: 18 }}
                                                />
                                            </IconButton>
                                        </Tooltip>
                                    )}
                                </Stack>
                            )}

                            <ItemsSection
                                items={homeFilteredItems}
                                masterKey={masterKey}
                                isTrashView={false}
                                onEditItem={onEditItem}
                                onDeleteItem={onDeleteItem}
                                onPermanentlyDelete={onPermanentlyDelete}
                                onRequestRestore={(item) => {
                                    setRestoreItem(item);
                                    setRestoreCollectionID(null);
                                }}
                                getSecondaryText={getItemSecondaryText}
                                onSelectItem={setSelectedItem}
                                currentUserID={currentUserID}
                                onShareLink={openFileLinkDialog}
                                fileShareLinksByFileID={knownFileShareLinksByID}
                                selectionMode={selectionMode}
                                selectedItemIDSet={selectedItemIDSet}
                                onToggleItemSelection={toggleItemSelection}
                                onStartSelection={
                                    canBulkSelectVisibleItems
                                        ? startSelectionModeForItem
                                        : undefined
                                }
                                emptyState={
                                    <EmptyState
                                        title={
                                            homeSelectedCollectionIDs.length > 0
                                                ? t("noResults")
                                                : t("homeLockerEmptyTitle")
                                        }
                                        subtitle={
                                            homeSelectedCollectionIDs.length > 0
                                                ? t(
                                                      "noItemsMatchSelectedFilters",
                                                  )
                                                : t("homeLockerEmptySubtitle")
                                        }
                                    />
                                }
                            />
                        </>
                    )}

                    {!isHomeView && isCollectionsView && !searchActive && (
                        <>
                            <SectionHeader
                                title={t("collections")}
                                countLabel={t("lockerCollectionsCount", {
                                    count: displayCollections.length,
                                })}
                                action={
                                    onCreateCollection ? (
                                        <Tooltip
                                            title={t("createCollectionButton")}
                                        >
                                            <IconButton
                                                aria-label={t(
                                                    "createCollectionButton",
                                                )}
                                                onClick={() => {
                                                    setCreateCollectionError(
                                                        null,
                                                    );
                                                    setCreateCollectionName("");
                                                    setCreateCollectionOpen(
                                                        true,
                                                    );
                                                }}
                                                sx={{
                                                    width: 40,
                                                    height: 40,
                                                    color: "#FFFFFF",
                                                    background: "#0E6BFF",
                                                    border: "1px solid rgba(160, 199, 255, 0.18)",
                                                    boxShadow:
                                                        "0 10px 24px rgba(0, 66, 173, 0.20)",
                                                    "&:hover": {
                                                        background: "#1A7AFF",
                                                        boxShadow:
                                                            "0 12px 28px rgba(0, 66, 173, 0.24)",
                                                    },
                                                }}
                                            >
                                                <AddOutlinedIcon
                                                    sx={{ fontSize: 24 }}
                                                />
                                            </IconButton>
                                        </Tooltip>
                                    ) : undefined
                                }
                            />

                            {displayCollections.length > 0 ? (
                                <CollectionGrid
                                    collections={displayCollections}
                                    onSelectCollection={onSelectCollection}
                                    onShareCollection={onShareCollection}
                                    onRequestRenameCollection={(collection) => {
                                        setRenameCollectionID(collection.id);
                                        setRenameValue(collection.name);
                                    }}
                                    onDeleteCollection={onDeleteCollection}
                                />
                            ) : (
                                <EmptyState
                                    title={t("noCollections")}
                                    subtitle={t("createCollection")}
                                />
                            )}
                        </>
                    )}

                    {!isHomeView && searchActive && (
                        <>
                            {filteredCollections.length > 0 && (
                                <>
                                    <SectionHeader
                                        title={t("collections")}
                                        countLabel={t(
                                            "lockerCollectionsCount",
                                            {
                                                count: filteredCollections.length,
                                            },
                                        )}
                                    />
                                    <CollectionGrid
                                        collections={filteredCollections}
                                        onSelectCollection={onSelectCollection}
                                        onShareCollection={onShareCollection}
                                        onRequestRenameCollection={(
                                            collection,
                                        ) => {
                                            setRenameCollectionID(
                                                collection.id,
                                            );
                                            setRenameValue(collection.name);
                                        }}
                                        onDeleteCollection={onDeleteCollection}
                                    />
                                </>
                            )}

                            <SectionHeader
                                title={t("allItems")}
                                countLabel={t("lockerItemsCount", {
                                    count: sortedItems.length,
                                })}
                            />

                            <ItemsSection
                                items={sortedItems}
                                masterKey={masterKey}
                                isTrashView={isTrashView}
                                onEditItem={onEditItem}
                                onDeleteItem={onDeleteItem}
                                onPermanentlyDelete={onPermanentlyDelete}
                                onRequestRestore={(item) => {
                                    setRestoreItem(item);
                                    setRestoreCollectionID(null);
                                }}
                                getSecondaryText={getItemSecondaryText}
                                onSelectItem={setSelectedItem}
                                currentUserID={currentUserID}
                                onShareLink={openFileLinkDialog}
                                fileShareLinksByFileID={knownFileShareLinksByID}
                                selectionMode={selectionMode}
                                selectedItemIDSet={selectedItemIDSet}
                                onToggleItemSelection={toggleItemSelection}
                                onStartSelection={
                                    canBulkSelectVisibleItems
                                        ? startSelectionModeForItem
                                        : undefined
                                }
                                emptyState={
                                    <EmptyState
                                        title={t("searchEmptyTitle")}
                                        subtitle={t("searchEverywhereEmpty")}
                                    />
                                }
                            />
                        </>
                    )}

                    {!isHomeView && !isCollectionsView && !searchActive && (
                        <>
                            <SectionHeader
                                title={
                                    isTrashView
                                        ? t("trash")
                                        : (selectedCollection?.name ??
                                          t("allItems"))
                                }
                                countLabel={t("lockerItemsCount", {
                                    count: sortedItems.length,
                                })}
                                action={
                                    <Stack
                                        direction="row"
                                        sx={{ alignItems: "center", gap: 1 }}
                                    >
                                        {isTrashView &&
                                            sortedItems.length > 0 &&
                                            onEmptyTrash && (
                                                <Button
                                                    color="critical"
                                                    startIcon={
                                                        <DeleteSweepOutlinedIcon />
                                                    }
                                                    onClick={onEmptyTrash}
                                                >
                                                    {t("empty_trash")}
                                                </Button>
                                            )}
                                        {selectedCollection &&
                                            canShareSelectedCollection &&
                                            onShareCollection && (
                                                <Tooltip
                                                    title={t("sharedWith")}
                                                >
                                                    <IconButton
                                                        color="secondary"
                                                        onClick={() =>
                                                            onShareCollection(
                                                                selectedCollection,
                                                            )
                                                        }
                                                        sx={{
                                                            color: "text.muted",
                                                        }}
                                                    >
                                                        <ShareOutlinedIcon />
                                                    </IconButton>
                                                </Tooltip>
                                            )}
                                        {canEditSelectedCollection && (
                                            <CollectionHeaderMenu
                                                onShare={
                                                    canShareSelectedCollection &&
                                                    onShareCollection
                                                        ? handleShareSelectedCollection
                                                        : undefined
                                                }
                                                onRename={
                                                    onRenameCollection
                                                        ? () => {
                                                              setRenameCollectionID(
                                                                  selectedCollection.id,
                                                              );
                                                              setRenameValue(
                                                                  selectedCollection.name,
                                                              );
                                                          }
                                                        : undefined
                                                }
                                                onDelete={
                                                    onDeleteCollection
                                                        ? () =>
                                                              onDeleteCollection(
                                                                  selectedCollection.id,
                                                              )
                                                        : undefined
                                                }
                                            />
                                        )}
                                    </Stack>
                                }
                            />

                            <ItemsSection
                                items={sortedItems}
                                masterKey={masterKey}
                                isTrashView={isTrashView}
                                onEditItem={onEditItem}
                                onDeleteItem={onDeleteItem}
                                onPermanentlyDelete={onPermanentlyDelete}
                                onRequestRestore={(item) => {
                                    setRestoreItem(item);
                                    setRestoreCollectionID(null);
                                }}
                                getSecondaryText={getItemSecondaryText}
                                onSelectItem={setSelectedItem}
                                currentUserID={currentUserID}
                                onShareLink={
                                    isTrashView ? undefined : openFileLinkDialog
                                }
                                fileShareLinksByFileID={knownFileShareLinksByID}
                                selectionMode={selectionMode}
                                selectedItemIDSet={selectedItemIDSet}
                                onToggleItemSelection={toggleItemSelection}
                                onStartSelection={
                                    canBulkSelectVisibleItems
                                        ? startSelectionModeForItem
                                        : undefined
                                }
                                emptyState={
                                    isTrashView ? (
                                        <EmptyState
                                            title={t("trashIsEmpty")}
                                            subtitle={t("yourTrashIsEmpty")}
                                        />
                                    ) : (
                                        <EmptyState
                                            title={t(
                                                "collectionEmptyStateTitle",
                                            )}
                                            subtitle={t(
                                                "collectionEmptyStateSubtitle",
                                            )}
                                        />
                                    )
                                }
                            />
                        </>
                    )}
                </Box>
            </Box>

            {selectionMode && canBulkSelectVisibleItems && (
                <SelectionActionBar
                    selectedCount={selectedVisibleItems.length}
                    allSelected={allVisibleItemsSelected}
                    bulkDownloading={bulkDownloading}
                    bulkDownloadProgress={bulkDownloadProgress}
                    canDownload={
                        !!masterKey && selectedDownloadableItems.length > 0
                    }
                    canDelete={
                        !!onDeleteItems && selectedVisibleItems.length > 0
                    }
                    onToggleSelectAll={toggleSelectAllVisibleItems}
                    onDownload={downloadSelectedFiles}
                    onDelete={deleteSelectedFiles}
                    onDone={stopSelectionMode}
                />
            )}

            <ItemDetailView
                item={selectedItem}
                masterKey={masterKey}
                onClose={() => setSelectedItem(null)}
                onEdit={
                    onEditItem &&
                    !isTrashView &&
                    selectedItem &&
                    (selectedItem.ownerID ?? currentUserID) === currentUserID
                        ? (item) => {
                              setSelectedItem(null);
                              onEditItem(item);
                          }
                        : undefined
                }
                onDelete={
                    onDeleteItem &&
                    !isTrashView &&
                    selectedItem &&
                    (selectedItem.ownerID ?? currentUserID) === currentUserID
                        ? (item) => {
                              setSelectedItem(null);
                              onDeleteItem(item);
                          }
                        : undefined
                }
                onDeleteDisabledHint={
                    !isTrashView &&
                    selectedItem &&
                    (selectedItem.ownerID ?? currentUserID) !== currentUserID
                        ? t("actionNotSupportedForSharedFiles", { count: 1 })
                        : undefined
                }
                isTrashView={isTrashView}
                onShareLink={
                    !isTrashView &&
                    selectedItem &&
                    canShareLockerFileLink(selectedItem, currentUserID)
                        ? openFileLinkDialog
                        : undefined
                }
            />

            <LockerFileLinkDialog
                open={activeFileLinkItem !== null}
                itemTitle={
                    activeFileLinkItem ? getItemTitle(activeFileLinkItem) : ""
                }
                url={activeFileLink?.url}
                loading={isCreatingFileLink}
                deleting={isDeletingFileLink}
                showShareAction={canNativeShare}
                onClose={closeFileLinkDialog}
                onCopy={() => void copyActiveFileLink()}
                onShare={() => void shareActiveFileLink()}
                onDelete={() => void deleteActiveFileLink()}
            />

            <Dialog
                open={restoreItem !== null}
                onClose={() => setRestoreItem(null)}
                fullWidth
                maxWidth="xs"
            >
                <DialogTitle>{t("restoreToCollection")}</DialogTitle>
                <DialogContent>
                    <Stack sx={{ gap: 1, py: 1 }}>
                        {displayCollections.length > 0 ? (
                            displayCollections.map((collection) => (
                                <Chip
                                    key={collection.id}
                                    label={collection.name}
                                    variant={
                                        restoreCollectionID === collection.id
                                            ? "filled"
                                            : "outlined"
                                    }
                                    color={
                                        restoreCollectionID === collection.id
                                            ? "primary"
                                            : "default"
                                    }
                                    onClick={() =>
                                        setRestoreCollectionID(collection.id)
                                    }
                                />
                            ))
                        ) : (
                            <Typography
                                variant="body"
                                sx={{ color: "text.muted" }}
                            >
                                {t("noCollectionsAvailableForSelection")}
                            </Typography>
                        )}
                        <Button
                            variant="contained"
                            disabled={restoreCollectionID === null}
                            onClick={handleRestoreConfirm}
                            sx={{ mt: 1 }}
                        >
                            {t("restore")}
                        </Button>
                    </Stack>
                </DialogContent>
            </Dialog>

            <Dialog
                open={renameCollectionID !== null}
                onClose={() => setRenameCollectionID(null)}
                fullWidth
                maxWidth="xs"
            >
                <DialogTitle>{t("renameCollection")}</DialogTitle>
                <DialogContent>
                    <Stack sx={{ gap: 2, py: 1 }}>
                        <TextField
                            value={renameValue}
                            onChange={(event) =>
                                setRenameValue(event.target.value)
                            }
                            label={t("enterCollectionName")}
                            fullWidth
                            autoFocus
                            onKeyDown={(event) => {
                                if (event.key === "Enter") {
                                    handleRenameConfirm();
                                }
                            }}
                        />
                        <Button
                            variant="contained"
                            disabled={!renameValue.trim()}
                            onClick={handleRenameConfirm}
                        >
                            {t("save")}
                        </Button>
                    </Stack>
                </DialogContent>
            </Dialog>

            <Dialog
                open={createCollectionOpen}
                onClose={() => {
                    if (!creatingCollection) {
                        setCreateCollectionOpen(false);
                    }
                }}
                fullWidth
                maxWidth="xs"
            >
                <DialogTitle>{t("createNewCollection")}</DialogTitle>
                <DialogContent>
                    <Stack sx={{ gap: 2, py: 1 }}>
                        <TextField
                            value={createCollectionName}
                            onChange={(event) => {
                                setCreateCollectionName(event.target.value);
                                setCreateCollectionError(null);
                            }}
                            label={t("enterCollectionName")}
                            fullWidth
                            autoFocus
                            onKeyDown={(event) => {
                                if (event.key === "Enter") {
                                    void handleCreateCollectionConfirm();
                                }
                            }}
                        />
                        {createCollectionError && (
                            <Typography
                                variant="small"
                                sx={{ color: "critical.main" }}
                            >
                                {createCollectionError}
                            </Typography>
                        )}
                        <Stack direction="row" sx={{ gap: 1 }}>
                            <Button
                                fullWidth
                                color="secondary"
                                onClick={() => setCreateCollectionOpen(false)}
                                disabled={creatingCollection}
                            >
                                {t("cancel")}
                            </Button>
                            <Button
                                fullWidth
                                variant="contained"
                                onClick={() =>
                                    void handleCreateCollectionConfirm()
                                }
                                disabled={
                                    creatingCollection ||
                                    !createCollectionName.trim()
                                }
                            >
                                {t("createCollectionButton")}
                            </Button>
                        </Stack>
                    </Stack>
                </DialogContent>
            </Dialog>

            <Snackbar
                open={feedbackMessage !== null}
                message={feedbackMessage}
                autoHideDuration={2500}
                onClose={() => setFeedbackMessage(null)}
            />
        </Stack>
    );
};

const SectionHeader: React.FC<{
    title: string;
    countLabel: string;
    action?: React.ReactNode;
}> = ({ title, countLabel, action }) => (
    <Stack
        direction="row"
        sx={{
            alignItems: "center",
            justifyContent: "space-between",
            gap: 2,
            maxWidth: contentMaxWidth,
            mx: "auto",
            mt: 3,
            mb: 1.5,
        }}
    >
        <Box>
            <Typography variant="h3" sx={{ fontWeight: "bold" }}>
                {title}
            </Typography>
            <Typography variant="small" sx={{ color: "text.muted" }}>
                {countLabel}
            </Typography>
        </Box>
        {action}
    </Stack>
);

const ItemsSection: React.FC<{
    items: LockerItem[];
    masterKey?: string;
    isTrashView: boolean;
    onEditItem?: (item: LockerItem) => void;
    onDeleteItem?: (item: LockerItem) => void;
    onPermanentlyDelete?: (items: LockerItem[]) => void;
    onRequestRestore: (item: LockerItem) => void;
    getSecondaryText: (item: LockerItem) => string;
    onSelectItem: (item: LockerItem) => void;
    currentUserID: number;
    onShareLink?: (item: LockerItem) => void;
    fileShareLinksByFileID: Map<number, LockerFileShareLinkSummary>;
    selectionMode?: boolean;
    selectedItemIDSet?: Set<number>;
    onToggleItemSelection?: (item: LockerItem) => void;
    onStartSelection?: (item: LockerItem) => void;
    emptyState: React.ReactNode;
}> = ({
    items,
    masterKey,
    isTrashView,
    onEditItem,
    onDeleteItem,
    onPermanentlyDelete,
    onRequestRestore,
    getSecondaryText,
    onSelectItem,
    currentUserID,
    onShareLink,
    fileShareLinksByFileID,
    selectionMode,
    selectedItemIDSet,
    onToggleItemSelection,
    onStartSelection,
    emptyState,
}) =>
    items.length > 0 ? (
        <Stack
            sx={{ maxWidth: contentMaxWidth, mx: "auto", gap: 0, mt: 1 }}
        >
            {items.map((item) => {
                const isOwnedByCurrentUser =
                    (item.ownerID ?? currentUserID) === currentUserID;
                return (
                    <ItemCard
                        key={item.id}
                        item={item}
                        masterKey={masterKey}
                        isTrashView={isTrashView}
                        secondaryText={getSecondaryText(item)}
                        onClick={() => onSelectItem(item)}
                        onEdit={
                            onEditItem && isOwnedByCurrentUser
                                ? onEditItem
                                : undefined
                        }
                        onDelete={
                            onDeleteItem && isOwnedByCurrentUser
                                ? onDeleteItem
                                : undefined
                        }
                        deleteDisabledHint={
                            onDeleteItem &&
                            !isTrashView &&
                            !isOwnedByCurrentUser
                                ? t("actionNotSupportedForSharedFiles", {
                                      count: 1,
                                  })
                                : undefined
                        }
                        onPermanentlyDelete={onPermanentlyDelete}
                        onRestore={
                            isTrashView
                                ? (trashItem) => onRequestRestore(trashItem)
                                : undefined
                        }
                        onShareLink={
                            onShareLink &&
                            canShareLockerFileLink(item, currentUserID)
                                ? onShareLink
                                : undefined
                        }
                        fileShareLink={fileShareLinksByFileID.get(item.id)}
                        selectionMode={selectionMode}
                        selectable
                        selected={selectedItemIDSet?.has(item.id)}
                        onToggleSelection={onToggleItemSelection}
                        onLongPressSelect={onStartSelection}
                    />
                );
            })}
        </Stack>
    ) : (
        <Box sx={{ maxWidth: contentMaxWidth, mx: "auto" }}>{emptyState}</Box>
    );

const SelectionActionBar: React.FC<{
    selectedCount: number;
    allSelected: boolean;
    bulkDownloading: boolean;
    bulkDownloadProgress: { completed: number; total: number } | null;
    canDownload: boolean;
    canDelete: boolean;
    onToggleSelectAll: () => void;
    onDownload: () => void;
    onDelete: () => void;
    onDone: () => void;
}> = ({
    selectedCount,
    allSelected,
    bulkDownloading,
    bulkDownloadProgress,
    canDownload,
    canDelete,
    onToggleSelectAll,
    onDownload,
    onDelete,
    onDone,
}) => (
    <Box
        sx={{
            px: { xs: 2, sm: 3 },
            py: { xs: 1.25, sm: 1.5 },
            background:
                "linear-gradient(180deg, rgba(8, 9, 10, 0) 0%, rgba(8, 9, 10, 0.82) 18%, rgba(8, 9, 10, 0.95) 100%)",
        }}
    >
        <Box
            sx={{
                maxWidth: 760,
                mx: "auto",
                borderRadius: "20px",
                border: "1px solid rgba(255, 255, 255, 0.08)",
                background:
                    "linear-gradient(180deg, rgba(24, 26, 30, 0.96) 0%, rgba(14, 16, 19, 0.98) 100%)",
                boxShadow: "0 18px 42px rgba(0, 0, 0, 0.32)",
                backdropFilter: "blur(18px)",
                px: { xs: 1.25, sm: 1.5 },
                py: 1.25,
            }}
        >
            <Stack
                direction={{ xs: "column", sm: "row" }}
                sx={{
                    alignItems: { xs: "stretch", sm: "center" },
                    justifyContent: "space-between",
                    gap: 1,
                }}
            >
                <Stack
                    direction="row"
                    sx={{
                        alignItems: "center",
                        justifyContent: "space-between",
                        gap: 1,
                    }}
                >
                    <Box
                        sx={{
                            display: "flex",
                            alignItems: "center",
                            gap: 1,
                            minWidth: 0,
                            px: 1.25,
                            py: 0.875,
                            borderRadius: "14px",
                            background:
                                "linear-gradient(180deg, rgba(14, 71, 157, 0.26) 0%, rgba(8, 45, 106, 0.18) 100%)",
                            border: "1px solid rgba(74, 144, 255, 0.18)",
                        }}
                    >
                        <CheckCircleRoundedIcon
                            sx={{
                                fontSize: 18,
                                color: "#7FB3FF",
                                flexShrink: 0,
                            }}
                        />
                        <Typography
                            variant="body"
                            sx={{ fontWeight: 600, minWidth: 0 }}
                            noWrap
                        >
                            {t("filesSelected", { count: selectedCount })}
                        </Typography>
                    </Box>
                    <IconButton
                        onClick={onDone}
                        disabled={bulkDownloading}
                        sx={{
                            color: "text.muted",
                            width: 38,
                            height: 38,
                            flexShrink: 0,
                            border: "1px solid rgba(255, 255, 255, 0.08)",
                            backgroundColor: "rgba(255, 255, 255, 0.035)",
                            "&:hover": {
                                backgroundColor: "rgba(255, 255, 255, 0.07)",
                            },
                        }}
                    >
                        <ClearRoundedIcon sx={{ fontSize: 18 }} />
                    </IconButton>
                </Stack>
                <Stack
                    direction={{ xs: "column", sm: "row" }}
                    sx={{ alignItems: { xs: "stretch", sm: "center" }, gap: 1 }}
                >
                    <Button
                        color="secondary"
                        onClick={onToggleSelectAll}
                        disabled={bulkDownloading}
                        sx={{
                            minHeight: 42,
                            px: 1.5,
                            borderRadius: "14px",
                            border: "1px solid rgba(255, 255, 255, 0.08)",
                            backgroundColor: "rgba(255, 255, 255, 0.04)",
                        }}
                    >
                        {allSelected ? t("deselectAll") : t("selectAll")}
                    </Button>
                    <Button
                        variant="contained"
                        startIcon={<FileDownloadOutlinedIcon />}
                        onClick={onDownload}
                        disabled={bulkDownloading || !canDownload}
                        sx={{
                            minHeight: 42,
                            px: 1.75,
                            borderRadius: "14px",
                            boxShadow: "none",
                            background:
                                "linear-gradient(180deg, #1674FF 0%, #0B5FE0 100%)",
                            "&:hover": {
                                boxShadow: "none",
                                background:
                                    "linear-gradient(180deg, #2A82FF 0%, #1269F0 100%)",
                            },
                        }}
                    >
                        {bulkDownloading && bulkDownloadProgress
                            ? `${t("downloading")} ${bulkDownloadProgress.completed}/${bulkDownloadProgress.total}`
                            : t("download")}
                    </Button>
                    <Button
                        color="critical"
                        startIcon={<DeleteOutlineIcon />}
                        onClick={onDelete}
                        disabled={bulkDownloading || !canDelete}
                        sx={{
                            minHeight: 42,
                            px: 1.75,
                            borderRadius: "14px",
                            border: "1px solid rgba(255, 91, 91, 0.22)",
                            backgroundColor: "rgba(255, 91, 91, 0.12)",
                            "&:hover": {
                                backgroundColor: "rgba(255, 91, 91, 0.18)",
                            },
                        }}
                    >
                        {t("delete")}
                    </Button>
                </Stack>
            </Stack>
        </Box>
    </Box>
);

const CollectionGrid: React.FC<{
    collections: LockerCollection[];
    onSelectCollection: (collectionID: number) => void;
    onShareCollection?: (collection: LockerCollection) => void;
    onRequestRenameCollection?: (collection: LockerCollection) => void;
    onDeleteCollection?: (collectionID: number) => void;
}> = ({
    collections,
    onSelectCollection,
    onShareCollection,
    onRequestRenameCollection,
    onDeleteCollection,
}) => {
    const currentUserID = ensureLocalUser().id;

    return (
        <Stack
            sx={{
                width: "100%",
                maxWidth: { xs: "100%", sm: "440px" },
                mx: "auto",
                gap: 1.25,
            }}
        >
            {collections.map((collection) => (
                <CollectionCard
                    key={collection.id}
                    collection={collection}
                    onClick={() => onSelectCollection(collection.id)}
                    onShare={
                        onShareCollection &&
                        canOpenCollectionSharing(collection)
                            ? () => onShareCollection(collection)
                            : undefined
                    }
                    onRename={
                        onRequestRenameCollection &&
                        canEditCollection(collection, currentUserID)
                            ? () => onRequestRenameCollection(collection)
                            : undefined
                    }
                    onDelete={
                        onDeleteCollection &&
                        canEditCollection(collection, currentUserID)
                            ? () => onDeleteCollection(collection.id)
                            : undefined
                    }
                />
            ))}
        </Stack>
    );
};

const CollectionChipFilters: React.FC<{
    collections: LockerCollection[];
    selectedCollectionIDs: number[];
    onToggleCollection: (collectionID: number) => void;
}> = ({ collections, selectedCollectionIDs, onToggleCollection }) => (
    <Box
        sx={{
            position: "relative",
            width: "100%",
            maxWidth: contentMaxWidth,
            mx: "auto",
            mt: 0.5,
        }}
    >
        <Stack
            direction="row"
            sx={{
                flexWrap: "nowrap",
                overflowX: "auto",
                overflowY: "hidden",
                justifyContent: "flex-start",
                gap: 1,
                pb: 0.5,
                scrollbarWidth: "none",
                "&::-webkit-scrollbar": {
                    display: "none",
                },
            }}
        >
            {collections.map((collection) => {
                const isSelected = selectedCollectionIDs.includes(
                    collection.id,
                );

                return (
                    <Chip
                        key={collection.id}
                        clickable
                        label={collection.name}
                        onClick={() => onToggleCollection(collection.id)}
                        sx={(theme) => ({
                            height: 36,
                            flexShrink: 0,
                            borderRadius: "999px",
                            fontWeight: 600,
                            color: isSelected
                                ? theme.vars.palette.text.base
                                : theme.vars.palette.text.base,
                            backgroundColor: theme.vars.palette.fill.faint,
                            border: "1px solid transparent",
                            boxShadow: isSelected
                                ? `inset 0 0 0 1px ${theme.vars.palette.primary.main}`
                                : "none",
                            "& .MuiChip-label": { px: 1.5 },
                            "&:hover": {
                                backgroundColor:
                                    theme.vars.palette.fill.faintHover,
                            },
                        })}
                    />
                );
            })}
        </Stack>
    </Box>
);

const EmptyState: React.FC<{ title: string; subtitle: string }> = ({
    title,
    subtitle,
}) => (
    <Box sx={{ textAlign: "center", py: 8 }}>
        <Typography variant="h4" sx={{ mb: 0.5 }}>
            {title}
        </Typography>
        <Typography variant="body" sx={{ color: "text.muted" }}>
            {subtitle}
        </Typography>
    </Box>
);

const CollectionCard: React.FC<{
    collection: LockerCollection;
    onClick: () => void;
    onShare?: () => void;
    onRename?: () => void;
    onDelete?: () => void;
}> = ({ collection, onClick, onShare, onRename, onDelete }) => {
    return (
        <ButtonBase
            component="div"
            onClick={onClick}
            sx={{
                width: "100%",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                gap: 1.5,
                px: 2,
                py: 1.5,
                minHeight: 84,
                borderRadius: "16px",
                background:
                    collection.items.length > 0
                        ? "linear-gradient(180deg, rgba(255, 255, 255, 0.075) 0%, rgba(255, 255, 255, 0.055) 100%)"
                        : "linear-gradient(180deg, rgba(255, 255, 255, 0.035) 0%, rgba(255, 255, 255, 0.022) 100%)",
                border: 1,
                borderStyle: "solid",
                borderColor:
                    collection.items.length > 0
                        ? "rgba(255, 255, 255, 0.10)"
                        : "rgba(255, 255, 255, 0.08)",
                transition: "background-color 0.15s, border-color 0.15s",
                "&:hover": {
                    background:
                        "linear-gradient(180deg, rgba(255, 255, 255, 0.090) 0%, rgba(255, 255, 255, 0.065) 100%)",
                    borderColor: "rgba(255, 255, 255, 0.13)",
                },
            }}
        >
            <Stack
                direction="row"
                sx={{ flex: 1, minWidth: 0, alignItems: "center", gap: 1.25 }}
            >
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        width: 40,
                        height: 40,
                        borderRadius: "50%",
                        backgroundColor: isImportantCollection(collection)
                            ? "rgba(16, 113, 255, 0.16)"
                            : "rgba(18, 36, 63, 0.96)",
                        border: isImportantCollection(collection)
                            ? "none"
                            : "1px solid rgba(159, 193, 255, 0.12)",
                        flexShrink: 0,
                        position: "relative",
                    }}
                >
                    {isImportantCollection(collection) ? (
                        <StarIcon sx={{ fontSize: 20, color: "#1071FF" }} />
                    ) : (
                        <FolderOutlinedIcon
                            sx={{ fontSize: 18, color: "#D6E5FF" }}
                        />
                    )}
                    {collection.isShared && <SharedCollectionBadge />}
                </Box>
                <Box sx={{ flex: 1, minWidth: 0 }}>
                    <Typography
                        variant="body"
                        sx={{
                            minWidth: 0,
                            fontWeight: "medium",
                            lineHeight: 1.3,
                        }}
                        noWrap
                    >
                        {collection.name}
                    </Typography>
                    <Typography
                        variant="small"
                        sx={{ color: "text.muted", mt: 0.25 }}
                    >
                        {t("lockerItemsCount", {
                            count: collection.items.length,
                        })}
                    </Typography>
                </Box>
            </Stack>
            {(onShare || onRename || onDelete) && (
                <Box
                    sx={{ flexShrink: 0 }}
                    onClick={(event) => event.stopPropagation()}
                >
                    <CollectionContextMenu
                        onShare={onShare}
                        onRename={onRename}
                        onDelete={onDelete}
                    />
                </Box>
            )}
        </ButtonBase>
    );
};

const SharedCollectionBadge: React.FC = () => {
    return (
        <Box
            sx={(theme) => ({
                position: "absolute",
                right: -2,
                bottom: -2,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                width: 16,
                height: 16,
                borderRadius: "999px",
                backgroundColor: "#1071FF",
                border: `1.5px solid ${theme.vars.palette.background.paper}`,
                boxShadow: "0 2px 6px rgba(0, 66, 173, 0.24)",
            })}
        >
            <ShareOutlinedIcon sx={{ fontSize: 10, color: "#FFFFFF" }} />
        </Box>
    );
};

const CollectionContextMenu: React.FC<{
    onShare?: () => void;
    onRename?: () => void;
    onDelete?: () => void;
}> = ({ onShare, onRename, onDelete }) => (
    <OverflowMenu
        ariaID="collection-context-menu"
        triggerButtonSxProps={{
            p: 0.25,
            color: "text.faint",
            opacity: 0,
            ".MuiButtonBase-root:hover &": { opacity: 1 },
        }}
    >
        {onShare && (
            <OverflowMenuOption
                startIcon={<ShareOutlinedIcon />}
                onClick={onShare}
            >
                {t("share")}
            </OverflowMenuOption>
        )}
        {onRename && (
            <OverflowMenuOption
                startIcon={<EditOutlinedIcon />}
                onClick={onRename}
            >
                {t("renameCollection")}
            </OverflowMenuOption>
        )}
        {onDelete && (
            <OverflowMenuOption
                startIcon={<DeleteOutlineIcon />}
                color="critical"
                onClick={onDelete}
            >
                {t("deleteCollection")}
            </OverflowMenuOption>
        )}
    </OverflowMenu>
);

const CollectionHeaderMenu: React.FC<{
    onShare?: () => void;
    onRename?: () => void;
    onDelete?: () => void;
}> = ({ onShare, onRename, onDelete }) => (
    <OverflowMenu
        ariaID="collection-header-menu"
        triggerButtonSxProps={{ color: "text.muted" }}
    >
        {onShare && (
            <OverflowMenuOption
                startIcon={<ShareOutlinedIcon />}
                onClick={onShare}
            >
                {t("share")}
            </OverflowMenuOption>
        )}
        {onRename && (
            <OverflowMenuOption
                startIcon={<EditOutlinedIcon />}
                onClick={onRename}
            >
                {t("renameCollection")}
            </OverflowMenuOption>
        )}
        {onDelete && (
            <OverflowMenuOption
                startIcon={<DeleteOutlineIcon />}
                color="critical"
                onClick={onDelete}
            >
                {t("deleteCollection")}
            </OverflowMenuOption>
        )}
    </OverflowMenu>
);
