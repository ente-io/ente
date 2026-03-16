import AddIcon from "@mui/icons-material/Add";
import CloudUploadOutlinedIcon from "@mui/icons-material/CloudUploadOutlined";
import { Box, Button, Fab, Snackbar, Stack, Typography } from "@mui/material";
import { CreateItemDialog } from "components/CreateItemDialog";
import { ItemList } from "components/ItemList";
import { LockerCollectionShareDrawer } from "components/LockerCollectionShareDrawer";
import { LockerNavbar, LockerUnstableToast } from "components/LockerNavbar";
import { LockerSidebar } from "components/LockerSidebar";
import { sessionExpiredDialogAttributes } from "ente-accounts-rs/components/utils/dialog";
import { stashRedirect } from "ente-accounts-rs/services/redirect";
import { masterKeyFromSession } from "ente-accounts-rs/services/session-storage";
import { LoadingIndicator } from "ente-base/components/loaders";
import { useBaseContext } from "ente-base/context";
import {
    authenticatedRequestHeaders,
    ensureOk,
    isHTTP401Error,
} from "ente-base/http";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { useSetupLockerI18n } from "i18n/locker";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useRef, useState } from "react";
import { Trans } from "react-i18next";
import {
    isEnteProductionEndpoint,
    LOCKER_FILE_LIMIT_FREE,
    LOCKER_FILE_LIMIT_PAID,
} from "services/locker-limits";
import {
    createCollection as createCollectionAPI,
    createInfoItem,
    deleteCollection as deleteCollectionAPI,
    emptyTrash as emptyTrashAPI,
    fetchCollectionSharees,
    fetchLockerData,
    fetchLockerTrash,
    permanentlyDeleteFromTrash,
    renameCollection as renameCollectionAPI,
    restoreFromTrash,
    shareCollection as shareCollectionAPI,
    trashFiles,
    unshareCollection as unshareCollectionAPI,
    updateInfoItem,
    uploadLockerFile,
} from "services/remote";
import type { LockerCollection, LockerItem, LockerItemType } from "types";
import { getItemTitle } from "types";

/** Subset of /users/details/v2 we need for the sidebar. */
interface UserDetails {
    email: string;
    usage: number;
    storageLimit: number;
    fileCount: number;
    lockerFileLimit: number;
    isPartOfFamily: boolean;
    lockerFamilyFileCount?: number;
}

interface LockerBonus {
    type?: string;
}

interface LockerUserDetailsResponse {
    email?: string;
    usage?: number;
    fileCount?: number;
    lockerFamilyUsage?: { familyFileCount?: number };
    familyData?: { members?: unknown[] };
    bonusData?: { storageBonuses?: LockerBonus[] };
    subscription?: {
        storage?: number;
        productID?: string;
        expiryTime?: number;
    };
}

type DragDataTransferItem = DataTransferItem & {
    webkitGetAsEntry?: () => FileSystemEntry | null;
};

const hasPaidLockerAccess = (json: {
    subscription?: { productID?: string; expiryTime?: number };
    familyData?: { members?: unknown[] };
    bonusData?: { storageBonuses?: LockerBonus[] };
}) => {
    const hasActivePaidSubscription =
        json.subscription?.productID !== "free" &&
        (json.subscription?.expiryTime ?? 0) > Date.now() * 1000;
    const isPartOfFamily = (json.familyData?.members?.length ?? 0) > 0;
    const hasPaidAddon =
        json.bonusData?.storageBonuses?.some(
            (bonus) =>
                bonus.type !== undefined &&
                bonus.type !== "SIGN_UP" &&
                bonus.type !== "REFERRAL",
        ) ?? false;

    return hasActivePaidSubscription || isPartOfFamily || hasPaidAddon;
};

const Page: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();
    const router = useRouter();
    const isLockerI18nReady = useSetupLockerI18n();

    const [collections, setCollections] = useState<LockerCollection[]>([]);
    const [masterKey, setMasterKey] = useState<string | undefined>();
    const [hasFetched, setHasFetched] = useState(false);
    const [initialLoadError, setInitialLoadError] = useState<string | null>(
        null,
    );
    const [isProductionEndpoint, setIsProductionEndpoint] = useState(true);
    const [userDetails, setUserDetails] = useState<UserDetails | undefined>();

    // Sidebar state
    const [sidebarOpen, setSidebarOpen] = useState(false);

    // View mode state
    const [trashItems, setTrashItems] = useState<LockerItem[]>([]);
    const [trashLastUpdatedAt, setTrashLastUpdatedAt] = useState(0);
    const [isTrashView, setIsTrashView] = useState(false);
    const [isCollectionsView, setIsCollectionsView] = useState(false);

    // Collection filter state
    const [selectedCollectionID, setSelectedCollectionID] = useState<
        number | null
    >(null);
    const [searchTerm, setSearchTerm] = useState("");

    // Create/Edit dialog state
    const [createDialogOpen, setCreateDialogOpen] = useState(false);
    const [prefilledUploadFile, setPrefilledUploadFile] = useState<File | null>(
        null,
    );
    const [editItem, setEditItem] = useState<{
        id: number;
        type: LockerItemType;
        data: Record<string, unknown>;
        collectionID: number;
    } | null>(null);

    // Toast state
    const [toast, setToast] = useState<string | null>(null);
    const [shareCollectionID, setShareCollectionID] = useState<number | null>(
        null,
    );
    const [isDragActive, setIsDragActive] = useState(false);
    const dragDepthRef = useRef(0);

    const loadUserDetails = useCallback(async () => {
        try {
            const [res, isProduction] = await Promise.all([
                fetch(
                    await apiURL("/users/details/v2", { memoryCount: true }),
                    { headers: await authenticatedRequestHeaders() },
                ),
                isEnteProductionEndpoint(),
            ]);
            ensureOk(res);
            setIsProductionEndpoint(isProduction);
            const json = (await res.json()) as LockerUserDetailsResponse;
            setUserDetails({
                email: json.email ?? "",
                usage: json.usage ?? 0,
                storageLimit: json.subscription?.storage ?? 0,
                fileCount: json.fileCount ?? 0,
                lockerFileLimit: hasPaidLockerAccess(json)
                    ? LOCKER_FILE_LIMIT_PAID
                    : LOCKER_FILE_LIMIT_FREE,
                isPartOfFamily: (json.familyData?.members?.length ?? 0) > 0,
                lockerFamilyFileCount: json.lockerFamilyUsage?.familyFileCount,
            });
        } catch (e) {
            log.error("Failed to fetch user details", e);
        }
    }, []);

    // Refresh data from remote
    const refreshData = useCallback(
        async (mk?: string) => {
            const key = mk ?? masterKey;
            if (!key) return;
            try {
                void loadUserDetails();
                // fetchLockerTrash depends on the encrypted caches populated by
                // fetchLockerData; running both in parallel can race and drop
                // trash key metadata needed for restore.
                const data = await fetchLockerData(key);
                const trash = await fetchLockerTrash(key);
                setCollections(data);
                setTrashItems(trash.items);
                setTrashLastUpdatedAt(trash.lastUpdatedAt);
                setInitialLoadError(null);
            } catch (e) {
                log.error("Failed to refresh locker data", e);
                if (isHTTP401Error(e))
                    showMiniDialog(sessionExpiredDialogAttributes(logout));
            }
        },
        [loadUserDetails, masterKey, logout, showMiniDialog],
    );

    useEffect(() => {
        const load = async () => {
            const mk = await masterKeyFromSession();
            if (!mk) {
                stashRedirect("/locker");
                void router.push("/login");
                return;
            }
            setMasterKey(mk);

            void loadUserDetails();

            try {
                // See note in refreshData: fetchLockerTrash must run after
                // fetchLockerData has populated encrypted caches.
                const data = await fetchLockerData(mk);
                const trash = await fetchLockerTrash(mk);
                setCollections(data);
                setTrashItems(trash.items);
                setTrashLastUpdatedAt(trash.lastUpdatedAt);
                setInitialLoadError(null);
            } catch (e) {
                log.error("Failed to fetch locker data", e);
                if (isHTTP401Error(e))
                    showMiniDialog(sessionExpiredDialogAttributes(logout));
                setInitialLoadError(
                    e instanceof Error
                        ? t("failedToLoadCollections", { error: e.message })
                        : t("generic_error_retry"),
                );
            }
            setHasFetched(true);
        };
        void load();
    }, [loadUserDetails, router, logout, showMiniDialog]);

    const handleSelectCollection = useCallback((id: number | null) => {
        setSelectedCollectionID(id);
        setIsTrashView(false);
        setIsCollectionsView(false);
        setSidebarOpen(false);
    }, []);

    const handleSelectCollections = useCallback(() => {
        setIsCollectionsView(true);
        setIsTrashView(false);
        setSelectedCollectionID(null);
        setSidebarOpen(false);
    }, []);

    const handleSelectTrash = useCallback(() => {
        setIsTrashView(true);
        setIsCollectionsView(false);
        setSelectedCollectionID(null);
        setSidebarOpen(false);
    }, []);

    const isHomeView =
        !isTrashView && !isCollectionsView && selectedCollectionID === null;

    // CRUD handlers

    const handleCreateItem = useCallback(
        async (
            type: LockerItemType,
            data: Record<string, unknown>,
            collectionID: number,
        ) => {
            if (!masterKey) throw new Error("No master key");
            await createInfoItem(collectionID, type, data, masterKey);
            await refreshData();
            setToast(t("recordSavedSuccessfully"));
        },
        [masterKey, refreshData],
    );

    const handleUploadFile = useCallback(
        async (file: File, collectionID: number) => {
            if (!masterKey) throw new Error("No master key");
            await uploadLockerFile(file, collectionID, masterKey);
            await refreshData();
            setToast(t("uploadComplete"));
        },
        [masterKey, refreshData],
    );

    const handleUpdateItem = useCallback(
        async (type: LockerItemType, data: Record<string, unknown>) => {
            if (!masterKey || !editItem)
                throw new Error("No master key or item");
            await updateInfoItem(editItem.id, type, data, masterKey);
            await refreshData();
            setToast(t("fileUpdatedSuccessfully"));
        },
        [masterKey, editItem, refreshData],
    );

    const handleDeleteItem = useCallback(
        (item: LockerItem) => {
            showMiniDialog({
                title: t("delete"),
                message: (
                    <Trans
                        i18nKey="deleteFileConfirmation"
                        values={{ fileName: getItemTitle(item) }}
                        components={{
                            strong: (
                                <Box
                                    component="span"
                                    sx={{ fontWeight: 700, color: "text.base" }}
                                />
                            ),
                        }}
                    />
                ),
                continue: {
                    text: t("delete"),
                    color: "critical",
                    action: async () => {
                        await trashFiles([item.id], item.collectionID);
                        await refreshData();
                        setToast(t("fileDeletedSuccessfully"));
                    },
                },
            });
        },
        [showMiniDialog, refreshData],
    );
    const handleDeleteItems = useCallback(
        (items: LockerItem[]) => {
            if (items.length === 0) {
                return;
            }

            showMiniDialog({
                title: t("delete"),
                message: t("deleteMultipleFilesDialogBody", {
                    count: items.length,
                }),
                continue: {
                    text: t("yesDeleteFiles", { count: items.length }),
                    color: "critical",
                    action: async () => {
                        const fileIDsByCollection = new Map<number, number[]>();
                        for (const item of items) {
                            const existing =
                                fileIDsByCollection.get(item.collectionID) ??
                                [];
                            existing.push(item.id);
                            fileIDsByCollection.set(
                                item.collectionID,
                                existing,
                            );
                        }

                        for (const [
                            collectionID,
                            fileIDs,
                        ] of fileIDsByCollection.entries()) {
                            await trashFiles(fileIDs, collectionID);
                        }

                        await refreshData();
                        setToast(
                            t("filesDeletedSuccessfully", {
                                count: items.length,
                            }),
                        );
                    },
                },
            });
        },
        [showMiniDialog, refreshData],
    );

    const handleEditItem = useCallback((item: LockerItem) => {
        setEditItem({
            id: item.id,
            type: item.type,
            data: item.data as unknown as Record<string, unknown>,
            collectionID: item.collectionID,
        });
    }, []);

    // Trash operations

    const handlePermanentlyDelete = useCallback(
        (items: LockerItem[]) => {
            showMiniDialog({
                title: t("permanentlyDelete"),
                message: t("permanentlyDeleteFilesBody", {
                    count: items.length,
                }),
                continue: {
                    text: t("permanentlyDelete"),
                    color: "critical",
                    action: async () => {
                        await permanentlyDeleteFromTrash(
                            items.map((i) => i.id),
                        );
                        await refreshData();
                        setToast(
                            t("filesDeletedPermanently", {
                                count: items.length,
                            }),
                        );
                    },
                },
            });
        },
        [showMiniDialog, refreshData],
    );

    const handleRestoreItem = useCallback(
        async (item: LockerItem, collectionID: number) => {
            if (!masterKey) return;
            await restoreFromTrash(
                [{ id: item.id, collectionID: item.collectionID }],
                collectionID,
                masterKey,
            );
            await refreshData();
            setToast(t("filesRestoredSuccessfully", { count: 1 }));
        },
        [masterKey, refreshData],
    );

    const handleEmptyTrash = useCallback(() => {
        showMiniDialog({
            title: t("empty_trash"),
            message: t("confirm_empty_trash"),
            continue: {
                text: t("empty_trash"),
                color: "critical",
                action: async () => {
                    await emptyTrashAPI(trashLastUpdatedAt);
                    await refreshData();
                    setToast(t("trashClearedSuccessfully"));
                },
            },
        });
    }, [showMiniDialog, refreshData, trashLastUpdatedAt]);

    // Collection management

    const handleCreateCollection = useCallback(
        async (name: string): Promise<number> => {
            if (!masterKey) throw new Error("No master key");
            const id = await createCollectionAPI(name, masterKey);
            await refreshData();
            setToast(t("createCollectionSuccess"));
            return id;
        },
        [masterKey, refreshData],
    );

    const handleCreateDialogClose = useCallback(() => {
        setCreateDialogOpen(false);
        setPrefilledUploadFile(null);
    }, []);

    const openUploadDialogForFile = useCallback((file: File) => {
        setPrefilledUploadFile(file);
        setCreateDialogOpen(true);
    }, []);

    const openCreateDialog = useCallback(() => {
        setPrefilledUploadFile(null);
        setCreateDialogOpen(true);
    }, []);

    const handleDragEnter = useCallback(
        (event: React.DragEvent<HTMLElement>) => {
            if (!event.dataTransfer.types.includes("Files")) {
                return;
            }
            event.preventDefault();
            event.stopPropagation();
            dragDepthRef.current += 1;
            setIsDragActive(true);
        },
        [],
    );

    const handleDragOver = useCallback(
        (event: React.DragEvent<HTMLElement>) => {
            if (!event.dataTransfer.types.includes("Files")) {
                return;
            }
            event.preventDefault();
            event.stopPropagation();
            event.dataTransfer.dropEffect = "copy";
        },
        [],
    );

    const handleDragLeave = useCallback(
        (event: React.DragEvent<HTMLElement>) => {
            if (!event.dataTransfer.types.includes("Files")) {
                return;
            }
            event.preventDefault();
            event.stopPropagation();
            dragDepthRef.current = Math.max(0, dragDepthRef.current - 1);
            if (dragDepthRef.current === 0) {
                setIsDragActive(false);
            }
        },
        [],
    );

    const handleDrop = useCallback(
        (event: React.DragEvent<HTMLElement>) => {
            event.preventDefault();
            event.stopPropagation();
            dragDepthRef.current = 0;
            setIsDragActive(false);

            const droppedFiles = Array.from(event.dataTransfer.files);
            const droppedItems = Array.from(
                event.dataTransfer.items,
            ) as DragDataTransferItem[];
            const [droppedItem] = droppedItems;

            if (droppedFiles.length !== 1) {
                return;
            }

            if (
                droppedItems.length > 0 &&
                (droppedItems.length !== 1 ||
                    droppedItem === undefined ||
                    droppedItem.kind !== "file" ||
                    droppedItem.webkitGetAsEntry()?.isDirectory)
            ) {
                return;
            }

            const [file] = droppedFiles;
            if (!file) {
                return;
            }

            openUploadDialogForFile(file);
        },
        [openUploadDialogForFile],
    );

    const handleRenameCollection = useCallback(
        async (collectionID: number, newName: string) => {
            if (!masterKey) return;
            await renameCollectionAPI(collectionID, newName, masterKey);
            await refreshData();
            setToast(t("collectionRenamedSuccessfully"));
        },
        [masterKey, refreshData],
    );

    const handleDeleteCollection = useCallback(
        (collectionID: number) => {
            const collectionName =
                collections.find((collection) => collection.id === collectionID)
                    ?.name ?? "";
            showMiniDialog({
                title: t("deleteCollection"),
                message: t("deleteCollectionConfirmation", { collectionName }),
                continue: {
                    text: t("delete"),
                    color: "critical",
                    action: async () => {
                        await deleteCollectionAPI(collectionID);
                        setSelectedCollectionID(null);
                        await refreshData();
                        setToast(t("collectionDeletedSuccessfully"));
                    },
                },
            });
        },
        [collections, showMiniDialog, refreshData],
    );

    const handleOpenShareCollection = useCallback(
        (collection: LockerCollection) => {
            setShareCollectionID(collection.id);
        },
        [],
    );

    const handleShareCollection = useCallback(
        async (collectionID: number, email: string) => {
            if (!masterKey) throw new Error("No master key");
            await shareCollectionAPI(collectionID, email, masterKey);
            await refreshData();
            setToast(t("collectionSharedSuccessfully"));
        },
        [masterKey, refreshData],
    );

    const handleUnshareCollection = useCallback(
        async (collectionID: number, email: string) => {
            await unshareCollectionAPI(collectionID, email);
            await refreshData();
            setToast(t("viewerRemovedSuccessfully"));
        },
        [refreshData],
    );

    const sharedCollection =
        shareCollectionID === null
            ? null
            : (collections.find(
                  (collection) => collection.id === shareCollectionID,
              ) ?? null);

    if (!hasFetched || !isLockerI18nReady) {
        return <LoadingIndicator />;
    }
    if (initialLoadError && collections.length === 0) {
        return (
            <Stack sx={{ height: "100dvh", overflow: "hidden" }}>
                <LockerNavbar
                    onOpenSidebar={() => setSidebarOpen(true)}
                    showMenuButton
                    searchTerm={searchTerm}
                    onSearchTermChange={setSearchTerm}
                />
                <LockerUnstableToast />
                <Box
                    sx={{
                        flex: 1,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        px: 3,
                    }}
                >
                    <Stack
                        sx={{
                            width: "100%",
                            maxWidth: 480,
                            gap: 1.5,
                            alignItems: "center",
                            textAlign: "center",
                        }}
                    >
                        <Typography variant="h3">{t("error")}</Typography>
                        <Typography variant="body" sx={{ color: "text.muted" }}>
                            {initialLoadError}
                        </Typography>
                        <Button
                            variant="contained"
                            onClick={() => router.reload()}
                        >
                            {t("retry")}
                        </Button>
                    </Stack>
                </Box>
            </Stack>
        );
    }

    return (
        <Stack
            sx={{ height: "100dvh", overflow: "hidden", position: "relative" }}
            onDragEnter={handleDragEnter}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
        >
            <LockerNavbar
                onOpenSidebar={() => setSidebarOpen(true)}
                showMenuButton
                searchTerm={searchTerm}
                onSearchTermChange={setSearchTerm}
            />
            <LockerUnstableToast />
            <Box
                sx={{
                    flex: 1,
                    minWidth: 0,
                    minHeight: 0,
                    display: "flex",
                    overflow: "hidden",
                }}
            >
                <ItemList
                    collections={collections}
                    masterKey={masterKey}
                    trashItems={isTrashView ? trashItems : undefined}
                    isTrashView={isTrashView}
                    isCollectionsView={isCollectionsView}
                    selectedCollectionID={selectedCollectionID}
                    onSelectCollection={handleSelectCollection}
                    onEditItem={handleEditItem}
                    onDeleteItem={handleDeleteItem}
                    onDeleteItems={handleDeleteItems}
                    onPermanentlyDelete={handlePermanentlyDelete}
                    onRestoreItem={handleRestoreItem}
                    onEmptyTrash={handleEmptyTrash}
                    onRenameCollection={handleRenameCollection}
                    onDeleteCollection={handleDeleteCollection}
                    onCreateCollection={handleCreateCollection}
                    onShareCollection={handleOpenShareCollection}
                    searchTerm={searchTerm}
                />
            </Box>
            <LockerSidebar
                open={sidebarOpen}
                onClose={() => setSidebarOpen(false)}
                collections={collections}
                trashItemCount={trashItems.length}
                onSelectHome={() => handleSelectCollection(null)}
                onSelectCollections={handleSelectCollections}
                onSelectTrash={handleSelectTrash}
                isHomeView={isHomeView}
                isTrashView={isTrashView}
                isCollectionsView={isCollectionsView}
                isProductionEndpoint={isProductionEndpoint}
                userDetails={userDetails}
            />
            <LockerCollectionShareDrawer
                open={shareCollectionID !== null}
                collection={sharedCollection}
                onClose={() => setShareCollectionID(null)}
                onShareCollection={handleShareCollection}
                onUnshareCollection={handleUnshareCollection}
                onRefreshSharees={fetchCollectionSharees}
            />

            {!isTrashView && (
                <Fab
                    color="primary"
                    aria-label={t("saveToLocker")}
                    onClick={openCreateDialog}
                    sx={{
                        position: "fixed",
                        right: "max(24px, env(safe-area-inset-right))",
                        bottom: "max(24px, env(safe-area-inset-bottom))",
                        width: 72,
                        height: 72,
                        minHeight: 72,
                        color: "#FFFFFF",
                        background:
                            "linear-gradient(135deg, #1071FF 0%, #0056CC 100%)",
                        boxShadow: "0 16px 40px rgba(0, 66, 173, 0.32)",
                        zIndex: 1200,
                        "&:hover": {
                            background:
                                "linear-gradient(135deg, #1A7AFF 0%, #004DB8 100%)",
                            boxShadow: "0 18px 44px rgba(0, 66, 173, 0.36)",
                        },
                    }}
                >
                    <AddIcon sx={{ fontSize: 36 }} />
                </Fab>
            )}

            {/* Create dialog */}
            <CreateItemDialog
                open={createDialogOpen}
                onClose={handleCreateDialogClose}
                collections={collections}
                onSave={handleCreateItem}
                onUploadFile={handleUploadFile}
                onCreateCollection={handleCreateCollection}
                defaultCollectionID={selectedCollectionID}
                initialFile={prefilledUploadFile}
            />

            {/* Edit dialog */}
            {editItem && (
                <CreateItemDialog
                    open={!!editItem}
                    onClose={() => setEditItem(null)}
                    collections={collections}
                    onSave={handleUpdateItem}
                    editItem={editItem}
                />
            )}

            {/* Toast notifications */}
            <Snackbar
                open={toast !== null}
                message={toast}
                autoHideDuration={3000}
                onClose={() => setToast(null)}
            />
            {isDragActive && (
                <Box
                    sx={(theme) => ({
                        position: "fixed",
                        inset: 0,
                        zIndex: 1600,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        pointerEvents: "none",
                        backgroundColor: "rgba(8, 9, 10, 0.58)",
                        backdropFilter: "blur(8px)",
                        ...theme.applyStyles("light", {
                            backgroundColor: "rgba(241, 245, 249, 0.78)",
                        }),
                    })}
                >
                    <Box
                        sx={(theme) => ({
                            width: "min(520px, calc(100vw - 48px))",
                            px: 4,
                            py: 5,
                            borderRadius: "24px",
                            border: "2px dashed rgba(127, 179, 255, 0.48)",
                            background:
                                "linear-gradient(180deg, rgba(16, 113, 255, 0.16) 0%, rgba(16, 113, 255, 0.08) 100%)",
                            boxShadow: "0 20px 48px rgba(0, 0, 0, 0.26)",
                            textAlign: "center",
                            ...theme.applyStyles("light", {
                                background:
                                    "linear-gradient(180deg, rgba(16, 113, 255, 0.10) 0%, rgba(16, 113, 255, 0.06) 100%)",
                                boxShadow: "0 18px 40px rgba(15, 23, 42, 0.12)",
                            }),
                        })}
                    >
                        <CloudUploadOutlinedIcon
                            sx={{
                                fontSize: 44,
                                color: "primary.main",
                                mb: 1.5,
                            }}
                        />
                        <Typography variant="h4" sx={{ mb: 0.75 }}>
                            {t("saveDocumentTitle")}
                        </Typography>
                        <Typography variant="body" sx={{ color: "text.muted" }}>
                            {t("clickHereToUpload")}
                        </Typography>
                    </Box>
                </Box>
            )}
        </Stack>
    );
};

export default Page;
