import AddIcon from "@mui/icons-material/Add";
import CloudUploadOutlinedIcon from "@mui/icons-material/CloudUploadOutlined";
import {
    Box,
    Button,
    Checkbox,
    Dialog,
    DialogContent,
    DialogTitle,
    Fab,
    FormControlLabel,
    Snackbar,
    Stack,
    Typography,
} from "@mui/material";
import { CreateItemDialog } from "components/CreateItemDialog";
import { ItemList } from "components/ItemList";
import { LockerCollectionShareDrawer } from "components/LockerCollectionShareDrawer";
import { lockerDialogPaperSx } from "components/lockerDialogStyles";
import { LockerNavbar, LockerUnstableToast } from "components/LockerNavbar";
import { LockerSidebar } from "components/LockerSidebar";
import { sessionExpiredDialogAttributes } from "ente-accounts-rs/components/utils/dialog";
import { savedLocalUser } from "ente-accounts-rs/services/accounts-db";
import { stashRedirect } from "ente-accounts-rs/services/redirect";
import { masterKeyFromSession } from "ente-accounts-rs/services/session-storage";
import { LoadingIndicator } from "ente-base/components/loaders";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
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
    deleteCollectionKeepingFiles,
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
    updateFileItem,
    updateInfoItem,
    updateItemCollections,
    uploadLockerFile,
    type LockerUploadProgress,
} from "services/remote";
import type {
    LockerCollection,
    LockerItem,
    LockerItemType,
    LockerUploadCandidate,
} from "types";
import { getItemTitle, isCollectionOwner } from "types";

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

type FileSystemFileEntry = FileSystemEntry & {
    file: (
        successCallback: (file: File) => void,
        errorCallback?: (error: DOMException) => void,
    ) => void;
};

interface FileSystemDirectoryReader {
    readEntries: (
        successCallback: (entries: FileSystemEntry[]) => void,
        errorCallback?: (error: DOMException) => void,
    ) => void;
}

type FileSystemDirectoryEntry = FileSystemEntry & {
    createReader: () => FileSystemDirectoryReader;
};

const fileFromEntry = (entry: FileSystemFileEntry) =>
    new Promise<File>((resolve, reject) => {
        entry.file(resolve, reject);
    });

const readDirectoryEntries = (entry: FileSystemDirectoryEntry) =>
    new Promise<FileSystemEntry[]>((resolve, reject) => {
        const reader = entry.createReader();
        const entries: FileSystemEntry[] = [];
        const readBatch = () => {
            reader.readEntries((batch) => {
                if (batch.length === 0) {
                    resolve(entries);
                    return;
                }
                entries.push(...batch);
                readBatch();
            }, reject);
        };
        readBatch();
    });

const collectionNamesFromRelativePath = (relativePath?: string) => [
    ...new Set((relativePath?.split("/").slice(0, -1) ?? []).filter(Boolean)),
];

const uploadCandidateFromFile = (
    file: File,
    relativePath?: string,
): LockerUploadCandidate => ({
    file,
    relativePath,
    suggestedCollectionNames: collectionNamesFromRelativePath(relativePath),
});

const uploadCandidatesFromEntry = async (
    entry: FileSystemEntry,
    parentPath = "",
): Promise<LockerUploadCandidate[]> => {
    if (entry.isFile) {
        const file = await fileFromEntry(entry as FileSystemFileEntry);
        const relativePath = parentPath
            ? `${parentPath}/${file.name}`
            : file.name;
        return [uploadCandidateFromFile(file, relativePath)];
    }

    if (entry.isDirectory) {
        const directoryPath = parentPath
            ? `${parentPath}/${entry.name}`
            : entry.name;
        const entries = await readDirectoryEntries(
            entry as FileSystemDirectoryEntry,
        );
        const items = await Promise.all(
            entries.map((childEntry) =>
                uploadCandidatesFromEntry(childEntry, directoryPath),
            ),
        );
        return items.flat();
    }

    return [];
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

const isLockerAppPath = (path: string) => {
    const pathname = path.split("?")[0] ?? path;
    return (
        pathname === "/" ||
        pathname === "/collections" ||
        pathname === "/trash" ||
        pathname === "/collection"
    );
};

const getCollectionIDFromPath = (path: string) => {
    const searchParams = new URLSearchParams(path.split("?")[1] ?? "");
    const id = searchParams.get("id");
    if (id === null) {
        return null;
    }

    const parsedID = Number.parseInt(id, 10);
    return Number.isFinite(parsedID) ? parsedID : null;
};

export const LockerPage: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();
    const currentUserID = savedLocalUser()?.id;
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
    const [searchTerm, setSearchTerm] = useState("");

    // Create/Edit dialog state
    const [createDialogOpen, setCreateDialogOpen] = useState(false);
    const [prefilledUploadItems, setPrefilledUploadItems] = useState<
        LockerUploadCandidate[]
    >([]);
    const [editItem, setEditItem] = useState<{
        id: number;
        type: LockerItemType;
        data: Record<string, unknown>;
        collectionID: number;
        collectionIDs: number[];
    } | null>(null);
    const [deleteCollectionDialog, setDeleteCollectionDialog] = useState<{
        collectionID: number;
        collectionName: string;
        hasItems: boolean;
        deleteFromEverywhere: boolean;
        loading: boolean;
        error: string | null;
    } | null>(null);
    const deleteCollectionDialogRef = useRef<{
        collectionID: number;
        collectionName: string;
        hasItems: boolean;
        deleteFromEverywhere: boolean;
        loading: boolean;
        error: string | null;
    } | null>(null);

    // Toast state
    const [toast, setToast] = useState<string | null>(null);
    const [shareCollectionID, setShareCollectionID] = useState<number | null>(
        null,
    );
    const [isDragActive, setIsDragActive] = useState(false);
    const dragDepthRef = useRef(0);
    const lockerRouteStackRef = useRef<string[]>([]);
    const lockerRouteIndexRef = useRef(-1);
    const isNavigatingBackRef = useRef(false);
    const isProgrammaticLockerNavigationRef = useRef(false);
    const routeCollectionID =
        router.pathname === "/collection"
            ? getCollectionIDFromPath(router.asPath)
            : null;
    const selectedCollectionID =
        routeCollectionID !== null && Number.isFinite(routeCollectionID)
            ? routeCollectionID
            : null;

    useEffect(() => {
        if (deleteCollectionDialog) {
            deleteCollectionDialogRef.current = deleteCollectionDialog;
        }
    }, [deleteCollectionDialog]);

    const visibleDeleteCollectionDialog =
        deleteCollectionDialog ?? deleteCollectionDialogRef.current;
    const isTrashView = router.pathname === "/trash";
    const isCollectionsView = router.pathname === "/collections";

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
        if (router.pathname !== "/locker") {
            return;
        }

        void router.replace("/", undefined, { shallow: true });
    }, [router]);

    useEffect(() => {
        const load = async () => {
            const mk = await masterKeyFromSession();
            if (!mk) {
                stashRedirect(router.asPath || "/");
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

    useEffect(() => {
        if (!router.isReady || !isLockerAppPath(router.asPath)) {
            return;
        }

        const routeStack = lockerRouteStackRef.current;
        const currentIndex = lockerRouteIndexRef.current;
        const currentPath = router.asPath;

        if (isNavigatingBackRef.current) {
            isNavigatingBackRef.current = false;
            const previousIndex = routeStack.lastIndexOf(currentPath);
            if (previousIndex >= 0) {
                lockerRouteIndexRef.current = previousIndex;
            } else {
                routeStack.push(currentPath);
                lockerRouteIndexRef.current = routeStack.length - 1;
            }
            return;
        }

        if (routeStack.length === 0) {
            routeStack.push(currentPath);
            lockerRouteIndexRef.current = 0;
            isProgrammaticLockerNavigationRef.current = false;
            return;
        }

        if (currentIndex >= 0 && routeStack[currentIndex] === currentPath) {
            isProgrammaticLockerNavigationRef.current = false;
            return;
        }

        if (isProgrammaticLockerNavigationRef.current) {
            isProgrammaticLockerNavigationRef.current = false;
            routeStack.splice(currentIndex + 1);
            routeStack.push(currentPath);
            lockerRouteIndexRef.current = routeStack.length - 1;
            return;
        }

        const existingIndex = routeStack.lastIndexOf(currentPath);
        if (existingIndex >= 0) {
            lockerRouteIndexRef.current = existingIndex;
            return;
        }

        routeStack.splice(currentIndex + 1);
        routeStack.push(currentPath);
        lockerRouteIndexRef.current = routeStack.length - 1;
    }, [router.asPath, router.isReady]);

    useEffect(() => {
        if (
            router.pathname === "/collection" &&
            router.isReady &&
            routeCollectionID === null
        ) {
            void router.replace("/", undefined, { shallow: true });
        }
    }, [routeCollectionID, router]);

    const navigateHome = useCallback(() => {
        isProgrammaticLockerNavigationRef.current = true;
        void router.push("/", undefined, { shallow: true });
    }, [router]);

    const removeCollectionFromState = useCallback((collectionID: number) => {
        setCollections((current) =>
            current.filter((collection) => collection.id !== collectionID),
        );
    }, []);

    const handleNavigateBack = useCallback(() => {
        setSidebarOpen(false);

        const currentIndex = lockerRouteIndexRef.current;
        if (currentIndex > 0) {
            lockerRouteIndexRef.current = currentIndex - 1;
            isNavigatingBackRef.current = true;
            router.back();
            return;
        }

        if (router.asPath !== "/") {
            lockerRouteStackRef.current = [router.asPath, "/"];
            lockerRouteIndexRef.current = 1;
            isNavigatingBackRef.current = true;
            isProgrammaticLockerNavigationRef.current = true;
            void router.push("/", undefined, { shallow: true });
            return;
        }
    }, [router]);

    const handleSelectCollection = useCallback(
        (id: number | null) => {
            if (id === null) {
                navigateHome();
            } else {
                isProgrammaticLockerNavigationRef.current = true;
                void router.push(
                    { pathname: "/collection", query: { id: String(id) } },
                    undefined,
                    { shallow: true },
                );
            }
            setSidebarOpen(false);
        },
        [navigateHome, router],
    );

    const handleSelectCollections = useCallback(() => {
        isProgrammaticLockerNavigationRef.current = true;
        void router.push("/collections", undefined, { shallow: true });
        setSidebarOpen(false);
    }, [router]);

    const handleSelectTrash = useCallback(() => {
        isProgrammaticLockerNavigationRef.current = true;
        void router.push("/trash", undefined, { shallow: true });
        setSidebarOpen(false);
    }, [router]);

    const isHomeView =
        !isTrashView && !isCollectionsView && selectedCollectionID === null;

    // CRUD handlers

    const handleCreateItem = useCallback(
        async (
            type: LockerItemType,
            data: Record<string, unknown>,
            collectionIDs: number[],
        ) => {
            if (!masterKey) throw new Error("No master key");
            await createInfoItem(collectionIDs, type, data, masterKey);
            await refreshData();
            setToast(t("recordSavedSuccessfully"));
        },
        [masterKey, refreshData],
    );

    const handleUploadFileWithProgress = useCallback(
        async (
            file: File,
            collectionIDs: number[],
            onProgress: (progress: LockerUploadProgress) => void,
        ) => {
            if (!masterKey) throw new Error("No master key");
            await uploadLockerFile(file, collectionIDs, masterKey, onProgress);
        },
        [masterKey],
    );

    const handleUploadsFinished = useCallback(
        async (uploadedCount: number) => {
            await refreshData();
            setToast(
                uploadedCount === 1
                    ? t("uploadComplete")
                    : t("uploadMultipleComplete", { count: uploadedCount }),
            );
        },
        [refreshData],
    );

    const handleUploadItemComplete = useCallback(() => {
        void refreshData();
    }, [refreshData]);

    const handleUpdateItem = useCallback(
        async (
            type: LockerItemType,
            data: Record<string, unknown>,
            collectionIDs: number[],
        ) => {
            if (!masterKey || !editItem)
                throw new Error("No master key or item");
            if (type === "file") {
                const editedName =
                    typeof data.name === "string" ? data.name : "";
                await updateFileItem(editItem.id, editedName, masterKey);
            } else {
                await updateInfoItem(editItem.id, type, data, masterKey);
            }
            await updateItemCollections(editItem.id, collectionIDs, masterKey);
            await refreshData();
            setToast(t("fileUpdatedSuccessfully"));
        },
        [masterKey, editItem, refreshData],
    );

    const handleDeleteItem = useCallback(
        (item: LockerItem) => {
            const collectionIDs =
                selectedCollectionID === null
                    ? item.collectionIDs.length > 0
                        ? item.collectionIDs
                        : [item.collectionID]
                    : [item.collectionID];
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
                        for (const collectionID of collectionIDs) {
                            await trashFiles([item.id], collectionID);
                        }
                        await refreshData();
                        setToast(t("fileDeletedSuccessfully"));
                    },
                },
            });
        },
        [refreshData, selectedCollectionID, showMiniDialog],
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
                            const collectionIDs =
                                selectedCollectionID === null
                                    ? item.collectionIDs.length > 0
                                        ? item.collectionIDs
                                        : [item.collectionID]
                                    : [item.collectionID];
                            for (const collectionID of collectionIDs) {
                                const existing =
                                    fileIDsByCollection.get(collectionID) ?? [];
                                existing.push(item.id);
                                fileIDsByCollection.set(collectionID, existing);
                            }
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
        [refreshData, selectedCollectionID, showMiniDialog],
    );

    const handleEditItem = useCallback((item: LockerItem) => {
        setEditItem({
            id: item.id,
            type: item.type,
            data:
                item.type === "file"
                    ? { name: getItemTitle(item) }
                    : (item.data as unknown as Record<string, unknown>),
            collectionID: item.collectionID,
            collectionIDs:
                item.collectionIDs.length > 0
                    ? item.collectionIDs
                    : [item.collectionID],
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
            title: t("empty_trash_title"),
            message: t("empty_trash_message"),
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

    const ensureCollectionsExist = useCallback(
        async (names: string[]) => {
            if (!masterKey) throw new Error("No master key");

            const normalizedNameToID = new Map(
                collections
                    .filter(
                        (collection) =>
                            currentUserID !== undefined &&
                            isCollectionOwner(collection, currentUserID),
                    )
                    .map((collection) => [
                        collection.name.trim().toLocaleLowerCase(),
                        collection.id,
                    ]),
            );
            let createdCollection = false;

            for (const name of names) {
                const normalizedName = name.trim().toLocaleLowerCase();
                if (!normalizedName || normalizedNameToID.has(normalizedName)) {
                    continue;
                }

                const id = await createCollectionAPI(name, masterKey);
                normalizedNameToID.set(normalizedName, id);
                createdCollection = true;
            }

            if (createdCollection) {
                await refreshData();
            }

            return normalizedNameToID;
        },
        [collections, currentUserID, masterKey, refreshData],
    );

    const handleCreateDialogClose = useCallback(() => {
        setCreateDialogOpen(false);
        setPrefilledUploadItems([]);
    }, []);

    const openUploadDialogForItems = useCallback(
        (items: LockerUploadCandidate[]) => {
            setPrefilledUploadItems(items);
            setCreateDialogOpen(true);
        },
        [],
    );

    const openCreateDialog = useCallback(() => {
        setPrefilledUploadItems([]);
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
        async (event: React.DragEvent<HTMLElement>) => {
            event.preventDefault();
            event.stopPropagation();
            dragDepthRef.current = 0;
            setIsDragActive(false);

            const droppedItems = Array.from(
                event.dataTransfer.items,
            ) as DragDataTransferItem[];
            const entryItems = (
                await Promise.all(
                    droppedItems
                        .filter((item) => item.kind === "file")
                        .map(async (item) => {
                            const entry = item.webkitGetAsEntry();
                            if (!entry) {
                                const file = item.getAsFile();
                                return file
                                    ? [
                                          uploadCandidateFromFile(
                                              file,
                                              file.webkitRelativePath ||
                                                  file.name,
                                          ),
                                      ]
                                    : [];
                            }
                            return uploadCandidatesFromEntry(entry);
                        }),
                )
            ).flat();

            const droppedItemsList =
                entryItems.length > 0
                    ? entryItems
                    : Array.from(event.dataTransfer.files).map((file) =>
                          uploadCandidateFromFile(
                              file,
                              file.webkitRelativePath || file.name,
                          ),
                      );
            const uniqueItems = droppedItemsList.filter(
                (item, index, items) =>
                    items.findIndex(
                        (candidate) =>
                            (candidate.relativePath ?? candidate.file.name) ===
                                (item.relativePath ?? item.file.name) &&
                            candidate.file.size === item.file.size &&
                            candidate.file.lastModified ===
                                item.file.lastModified,
                    ) === index,
            );

            if (uniqueItems.length === 0) {
                return;
            }

            openUploadDialogForItems(uniqueItems);
        },
        [openUploadDialogForItems],
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
            const collection = collections.find(
                (candidate) => candidate.id === collectionID,
            );
            if (!collection) {
                throw new Error("Collection not found");
            }

            setDeleteCollectionDialog({
                collectionID,
                collectionName: collection.name,
                hasItems: collection.items.length > 0,
                deleteFromEverywhere: false,
                loading: false,
                error: null,
            });
        },
        [collections],
    );

    const handleConfirmDeleteCollection = useCallback(async () => {
        const dialogState = deleteCollectionDialog;
        if (!dialogState) {
            return;
        }

        const collection = collections.find(
            (candidate) => candidate.id === dialogState.collectionID,
        );
        if (!collection) {
            setDeleteCollectionDialog((current) =>
                current
                    ? { ...current, error: t("collectionNotFoundError") }
                    : current,
            );
            return;
        }

        const shouldNavigateHome =
            router.pathname === "/collection" &&
            selectedCollectionID === collection.id;

        setDeleteCollectionDialog((current) =>
            current ? { ...current, loading: true, error: null } : current,
        );

        try {
            if (dialogState.deleteFromEverywhere) {
                await deleteCollectionAPI(collection.id);
            } else if (collection.items.length > 0) {
                if (!masterKey) {
                    throw new Error("Missing master key");
                }

                await deleteCollectionKeepingFiles(collection, masterKey);
            } else {
                await deleteCollectionAPI(collection.id, { keepFiles: true });
            }

            if (shouldNavigateHome) {
                navigateHome();
            }
            removeCollectionFromState(collection.id);
            await refreshData();
            setToast(t("collectionDeletedSuccessfully"));
            setDeleteCollectionDialog(null);
        } catch (error) {
            log.error("Failed to delete collection", error);
            setDeleteCollectionDialog((current) =>
                current
                    ? {
                          ...current,
                          loading: false,
                          error:
                              error instanceof Error
                                  ? error.message
                                  : t("failedToDeleteCollection"),
                      }
                    : current,
            );
        }
    }, [
        collections,
        deleteCollectionDialog,
        masterKey,
        navigateHome,
        removeCollectionFromState,
        refreshData,
        router.pathname,
        selectedCollectionID,
    ]);

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
    const isCollectionRoutePending =
        router.pathname === "/collection" &&
        (router.asPath.split("?")[0] ?? router.asPath) === "/collection" &&
        !router.isReady;
    const isViewLoading =
        !hasFetched || !isLockerI18nReady || isCollectionRoutePending;

    if (isViewLoading) {
        return <LoadingIndicator />;
    }
    if (initialLoadError && collections.length === 0) {
        return (
            <Stack sx={{ height: "100dvh", overflow: "hidden" }}>
                <LockerUnstableToast />
                <LockerNavbar
                    onOpenSidebar={() => setSidebarOpen(true)}
                    showMenuButton
                    stickyTop={44}
                    searchTerm={searchTerm}
                    onSearchTermChange={setSearchTerm}
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
        <Stack
            sx={{ height: "100dvh", overflow: "hidden", position: "relative" }}
            onDragEnter={handleDragEnter}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
        >
            <LockerUnstableToast />
            <LockerNavbar
                onOpenSidebar={() => setSidebarOpen(true)}
                showMenuButton
                stickyTop={44}
                searchTerm={searchTerm}
                onSearchTermChange={setSearchTerm}
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
                    onNavigateBack={handleNavigateBack}
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
            <Dialog
                open={deleteCollectionDialog !== null}
                onClose={() => {
                    if (!deleteCollectionDialog?.loading) {
                        setDeleteCollectionDialog(null);
                    }
                }}
                fullWidth
                maxWidth="xs"
                slotProps={{
                    paper: {
                        sx: {
                            ...lockerDialogPaperSx,
                            width: "min(100%, 420px)",
                        },
                    },
                }}
            >
                <DialogTitle sx={{ pb: 1 }}>
                    {t("deleteCollectionTitle")}
                </DialogTitle>
                <DialogContent>
                    <Stack sx={{ gap: 2.25 }}>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("deleteCollectionDialogBody", {
                                collectionName:
                                    visibleDeleteCollectionDialog?.collectionName ??
                                    "",
                            })}
                        </Typography>
                        {visibleDeleteCollectionDialog?.hasItems && (
                            <FormControlLabel
                                control={
                                    <Checkbox
                                        checked={
                                            visibleDeleteCollectionDialog.deleteFromEverywhere
                                        }
                                        disabled={
                                            visibleDeleteCollectionDialog.loading
                                        }
                                        onChange={(event) =>
                                            setDeleteCollectionDialog(
                                                (current) =>
                                                    current
                                                        ? {
                                                              ...current,
                                                              deleteFromEverywhere:
                                                                  event.target
                                                                      .checked,
                                                          }
                                                        : current,
                                            )
                                        }
                                    />
                                }
                                label={t("deleteCollectionFromEverywhere")}
                                sx={{ alignItems: "center", m: 0 }}
                            />
                        )}
                        {visibleDeleteCollectionDialog?.error && (
                            <Typography
                                variant="small"
                                sx={{ color: "critical.main" }}
                            >
                                {visibleDeleteCollectionDialog.error}
                            </Typography>
                        )}
                        <Stack direction="row" sx={{ gap: 1 }}>
                            <FocusVisibleButton
                                fullWidth
                                color="secondary"
                                disabled={
                                    visibleDeleteCollectionDialog?.loading
                                }
                                onClick={() => setDeleteCollectionDialog(null)}
                            >
                                {t("cancel")}
                            </FocusVisibleButton>
                            <LoadingButton
                                fullWidth
                                color="critical"
                                loading={visibleDeleteCollectionDialog?.loading}
                                onClick={() =>
                                    void handleConfirmDeleteCollection()
                                }
                            >
                                {t("delete")}
                            </LoadingButton>
                        </Stack>
                    </Stack>
                </DialogContent>
            </Dialog>

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
                onUploadProgress={handleUploadFileWithProgress}
                onUploadItemComplete={handleUploadItemComplete}
                onUploadsFinished={handleUploadsFinished}
                onCreateCollection={handleCreateCollection}
                onEnsureCollections={ensureCollectionsExist}
                defaultCollectionID={selectedCollectionID}
                initialItems={prefilledUploadItems}
            />

            {/* Edit dialog */}
            {editItem && (
                <CreateItemDialog
                    open={!!editItem}
                    onClose={() => setEditItem(null)}
                    collections={collections}
                    onSave={handleUpdateItem}
                    onCreateCollection={handleCreateCollection}
                    editItem={editItem}
                />
            )}

            {/* Toast notifications */}
            <Snackbar
                open={toast !== null}
                message={toast}
                autoHideDuration={3000}
                onClose={(_event, reason) => {
                    if (reason === "clickaway") {
                        return;
                    }
                    setToast(null);
                }}
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

export default LockerPage;
