import AddIcon from "@mui/icons-material/Add";
import { Box, Button, Fab, Snackbar, Stack, Typography } from "@mui/material";
import { CreateItemDialog } from "components/CreateItemDialog";
import { ItemList } from "components/ItemList";
import { LockerCollectionShareDrawer } from "components/LockerCollectionShareDrawer";
import { LockerNavbar } from "components/LockerNavbar";
import { LockerSidebar } from "components/LockerSidebar";
import { sessionExpiredDialogAttributes } from "ente-accounts-rs/components/utils/dialog";
import { stashRedirect } from "ente-accounts-rs/services/redirect";
import { LoadingIndicator } from "ente-base/components/loaders";
import { useBaseContext } from "ente-base/context";
import {
    authenticatedRequestHeaders,
    ensureOk,
    isHTTP401Error,
} from "ente-base/http";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { masterKeyFromSession } from "ente-base/session";
import { useSetupLockerI18n } from "i18n/locker";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";
import type { LockerFileShareLinkSummary } from "services/remote";
import {
    createCollection as createCollectionAPI,
    createInfoItem,
    deleteCollection as deleteCollectionAPI,
    emptyTrash as emptyTrashAPI,
    fetchCollectionSharees,
    fetchLockerData,
    fetchLockerFileShareLinks,
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
    lockerFamilyFileCount?: number;
}

const LOCKER_FILE_LIMIT_FREE = 100;
const LOCKER_FILE_LIMIT_PAID = 1000;

const hasPaidLockerAccess = (json: {
    subscription?: { productID?: string; expiryTime?: number };
    familyData?: { members?: unknown[] };
    bonusData?: { storageBonuses?: unknown[] };
}) => {
    const hasActivePaidSubscription =
        json.subscription?.productID !== "free" &&
        (json.subscription?.expiryTime ?? 0) > Date.now() * 1000;
    const isPartOfFamily = (json.familyData?.members?.length ?? 0) > 0;
    const hasPaidAddon = (json.bonusData?.storageBonuses?.length ?? 0) > 0;

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
    const [userDetails, setUserDetails] = useState<UserDetails | undefined>();

    // Sidebar state
    const [sidebarOpen, setSidebarOpen] = useState(false);

    // View mode state
    const [trashItems, setTrashItems] = useState<LockerItem[]>([]);
    const [isTrashView, setIsTrashView] = useState(false);
    const [isCollectionsView, setIsCollectionsView] = useState(false);

    // Collection filter state
    const [selectedCollectionID, setSelectedCollectionID] = useState<
        number | null
    >(null);

    // Create/Edit dialog state
    const [createDialogOpen, setCreateDialogOpen] = useState(false);
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
    const [fileShareLinksByFileID, setFileShareLinksByFileID] = useState(
        new Map<number, LockerFileShareLinkSummary>(),
    );

    // Refresh data from remote
    const refreshData = useCallback(
        async (mk?: string) => {
            const key = mk ?? masterKey;
            if (!key) return;
            try {
                const [data, trash, fileLinks] = await Promise.all([
                    fetchLockerData(key),
                    fetchLockerTrash(key),
                    fetchLockerFileShareLinks(),
                ]);
                setCollections(data);
                setTrashItems(trash);
                setFileShareLinksByFileID(fileLinks);
                setInitialLoadError(null);
            } catch (e) {
                log.error("Failed to refresh locker data", e);
                if (isHTTP401Error(e))
                    showMiniDialog(sessionExpiredDialogAttributes(logout));
            }
        },
        [masterKey, logout, showMiniDialog],
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

            // Fetch user details for sidebar (non-blocking on failure).
            try {
                const res = await fetch(
                    await apiURL("/users/details/v2", { memoryCount: true }),
                    { headers: await authenticatedRequestHeaders() },
                );
                ensureOk(res);
                const json = (await res.json()) as {
                    email?: string;
                    usage?: number;
                    fileCount?: number;
                    lockerFamilyUsage?: { familyFileCount?: number };
                    familyData?: { members?: unknown[] };
                    bonusData?: { storageBonuses?: unknown[] };
                    subscription?: {
                        storage?: number;
                        productID?: string;
                        expiryTime?: number;
                    };
                };
                setUserDetails({
                    email: json.email ?? "",
                    usage: json.usage ?? 0,
                    storageLimit: json.subscription?.storage ?? 0,
                    fileCount: json.fileCount ?? 0,
                    lockerFileLimit: hasPaidLockerAccess(json)
                        ? LOCKER_FILE_LIMIT_PAID
                        : LOCKER_FILE_LIMIT_FREE,
                    lockerFamilyFileCount:
                        json.lockerFamilyUsage?.familyFileCount,
                });
            } catch (e) {
                log.error("Failed to fetch user details", e);
            }

            try {
                const [data, trash, fileLinks] = await Promise.all([
                    fetchLockerData(mk),
                    fetchLockerTrash(mk),
                    fetchLockerFileShareLinks(),
                ]);
                setCollections(data);
                setTrashItems(trash);
                setFileShareLinksByFileID(fileLinks);
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
    }, [router, logout, showMiniDialog]);

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
                message: t("deleteFileConfirmation", {
                    fileName: getItemTitle(item),
                }),
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
            await restoreFromTrash([item.id], collectionID, masterKey);
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
                    await emptyTrashAPI();
                    await refreshData();
                    setToast(t("trashClearedSuccessfully"));
                },
            },
        });
    }, [showMiniDialog, refreshData]);

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
                />
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
        <Stack sx={{ height: "100dvh", overflow: "hidden" }}>
            <LockerNavbar
                onOpenSidebar={() => setSidebarOpen(true)}
                showMenuButton
            />
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
                    fileShareLinksByFileID={fileShareLinksByFileID}
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
                    onClick={() => setCreateDialogOpen(true)}
                    sx={{
                        position: "fixed",
                        right: "max(24px, env(safe-area-inset-right))",
                        bottom: "max(24px, env(safe-area-inset-bottom))",
                        width: 72,
                        height: 72,
                        minHeight: 72,
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
                onClose={() => setCreateDialogOpen(false)}
                collections={collections}
                onSave={handleCreateItem}
                onUploadFile={handleUploadFile}
                onCreateCollection={handleCreateCollection}
                defaultCollectionID={selectedCollectionID}
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
        </Stack>
    );
};

export default Page;
