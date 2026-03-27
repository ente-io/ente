import CheckRoundedIcon from "@mui/icons-material/CheckRounded";
import ChevronRightRoundedIcon from "@mui/icons-material/ChevronRightRounded";
import VisibilityIcon from "@mui/icons-material/Visibility";
import VisibilityOffIcon from "@mui/icons-material/VisibilityOff";
import {
    Box,
    ButtonBase,
    Dialog,
    DialogContent,
    DialogTitle,
    IconButton,
    InputAdornment,
    Link,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import { CollectionChipRow } from "components/createItemDialog/CollectionChipRow";
import {
    addCollectionName,
    collectionNamesByUploadItem,
    dedupeCollectionNames,
    normalizeCollectionName,
    toggleCollectionName,
    uploadQueueItemKey,
} from "components/createItemDialog/fileUploadHelpers";
import { FileUploadSection } from "components/createItemDialog/FileUploadSection";
import { lockerDialogPaperSx } from "components/lockerDialogStyles";
import {
    createDocumentIcon,
    createDocumentIconConfig,
    lockerItemIcon,
    lockerItemIconConfig,
} from "components/lockerItemIcons";
import { ensureLocalUser } from "ente-accounts-rs/services/user";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import log from "ente-base/log";
import { t } from "i18next";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import { Trans } from "react-i18next";
import {
    formatLockerMutationError,
    lockerUpgradeCTAType,
    type LockerUpgradeCTAType,
} from "services/locker-errors";
import type { LockerUploadProgress } from "services/remote";
import type {
    LockerCollection,
    LockerItemType,
    LockerUploadCandidate,
} from "types";
import { isCollectionOwner, visibleLockerCollections } from "types";

type CreateOption = LockerItemType | "file";
const MAX_PARALLEL_UPLOADS = 4;

interface LocalUser {
    id: number;
}

const CREATABLE_TYPES: {
    type: CreateOption;
    labelKey: string;
    descriptionKey: string;
    icon: React.ReactNode;
    bgColor: string;
}[] = [
    {
        type: "file",
        labelKey: "saveDocumentTitle",
        descriptionKey: "saveDocumentDescription",
        icon: createDocumentIcon(28, 1.9),
        bgColor: createDocumentIconConfig.backgroundColor,
    },
    {
        type: "note",
        labelKey: "personalNote",
        descriptionKey: "personalNoteDescription",
        icon: lockerItemIcon("note", { size: 28, strokeWidth: 1.9 }),
        bgColor: lockerItemIconConfig("note").backgroundColor,
    },
    {
        type: "physicalRecord",
        labelKey: "thing",
        descriptionKey: "physicalRecordsDescription",
        icon: lockerItemIcon("physicalRecord", { size: 28, strokeWidth: 1.9 }),
        bgColor: lockerItemIconConfig("physicalRecord").backgroundColor,
    },
    {
        type: "accountCredential",
        labelKey: "secret",
        descriptionKey: "accountCredentialsDescription",
        icon: lockerItemIcon("accountCredential", {
            size: 28,
            strokeWidth: 1.9,
        }),
        bgColor: lockerItemIconConfig("accountCredential").backgroundColor,
    },
];

interface CreateItemDialogProps {
    open: boolean;
    onClose: () => void;
    collections: LockerCollection[];
    onSave: (
        type: LockerItemType,
        data: Record<string, unknown>,
        collectionIDs: number[],
    ) => Promise<void>;
    onUploadProgress?: (
        file: File,
        collectionIDs: number[],
        onProgress: (progress: LockerUploadProgress) => void,
    ) => Promise<void>;
    onUploadItemComplete?: () => void;
    onUploadsFinished?: (uploadedCount: number) => Promise<void>;
    onCreateCollection?: (name: string) => Promise<number>;
    onEnsureCollections?: (
        names: string[],
    ) => Promise<Map<string, number> | Record<string, number>>;
    defaultCollectionID?: number | null;
    initialItems?: LockerUploadCandidate[];
    editItem?: {
        id: number;
        type: LockerItemType;
        data: Record<string, unknown>;
        collectionID: number;
        collectionIDs: number[];
    } | null;
}

interface UploadState {
    completedFileKeys: Set<string>;
    failedFileKeys: Set<string>;
    uploadingFileKeys: Set<string>;
    uploadProgressByFileKey: Record<string, LockerUploadProgress | null>;
    uploadCapByFileKey: Record<string, number>;
}

const emptyUploadState = (): UploadState => ({
    completedFileKeys: new Set(),
    failedFileKeys: new Set(),
    uploadingFileKeys: new Set(),
    uploadProgressByFileKey: {},
    uploadCapByFileKey: {},
});

export const CreateItemDialog: React.FC<CreateItemDialogProps> = ({
    open,
    onClose,
    collections,
    onSave,
    onUploadProgress,
    onUploadItemComplete,
    onUploadsFinished,
    onCreateCollection,
    onEnsureCollections,
    defaultCollectionID,
    initialItems,
    editItem,
}) => {
    const isEditMode = !!editItem;
    const currentUserID = (ensureLocalUser as unknown as () => LocalUser)().id;
    const displayCollections = useMemo(
        () =>
            visibleLockerCollections(collections).filter(
                (collection) =>
                    isEditMode || isCollectionOwner(collection, currentUserID),
            ),
        [collections, currentUserID, isEditMode],
    );
    const [selectedOption, setSelectedOption] = useState<CreateOption | null>(
        editItem?.type ?? null,
    );
    const [selectedCollectionIDs, setSelectedCollectionIDs] = useState<
        number[]
    >(editItem?.collectionID ? [editItem.collectionID] : []);
    const [saving, setSaving] = useState(false);
    const [uploading, setUploading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [upgradeCTAType, setUpgradeCTAType] =
        useState<LockerUpgradeCTAType | null>(null);
    const [formData, setFormData] = useState<Record<string, string>>(
        editItem ? (editItem.data as Record<string, string>) : {},
    );
    const [showPassword, setShowPassword] = useState(false);
    const [selectedUploadItems, setSelectedUploadItems] = useState<
        LockerUploadCandidate[]
    >([]);
    const [
        selectedCollectionNamesByFileKey,
        setSelectedCollectionNamesByFileKey,
    ] = useState<Record<string, string[]>>({});
    const [customCollectionNames, setCustomCollectionNames] = useState<
        string[]
    >([]);
    const [completedFileKeys, setCompletedFileKeys] = useState<Set<string>>(
        () => new Set(),
    );
    const [failedFileKeys, setFailedFileKeys] = useState<Set<string>>(
        () => new Set(),
    );
    const [uploadingFileKeys, setUploadingFileKeys] = useState<Set<string>>(
        () => new Set(),
    );
    const [uploadProgressByFileKey, setUploadProgressByFileKey] = useState<
        Record<string, LockerUploadProgress | null>
    >({});
    const [uploadCapByFileKey, setUploadCapByFileKey] = useState<
        Record<string, number>
    >({});

    const fileInputRef = useRef<HTMLInputElement>(null);
    const isFileMode = selectedOption === "file";
    const editCollectionID = editItem?.collectionID ?? null;
    const editCollectionIDs = useMemo(
        () => editItem?.collectionIDs ?? [],
        [editItem],
    );
    const selectedType =
        selectedOption && selectedOption !== "file"
            ? (selectedOption as LockerItemType)
            : null;
    const displayCollectionsRef = useRef(displayCollections);

    displayCollectionsRef.current = displayCollections;

    // Keep this stable so collection refreshes do not look like dialog resets.
    const normalizeSelectedCollectionIDs = useCallback(
        (collectionIDs: number[]) =>
            collectionIDs.filter((collectionID) =>
                displayCollectionsRef.current.some(
                    (collection) => collection.id === collectionID,
                ),
            ),
        [],
    );

    const resetUploadState = useCallback(() => {
        const nextState = emptyUploadState();
        setCompletedFileKeys(nextState.completedFileKeys);
        setFailedFileKeys(nextState.failedFileKeys);
        setUploadingFileKeys(nextState.uploadingFileKeys);
        setUploadProgressByFileKey(nextState.uploadProgressByFileKey);
        setUploadCapByFileKey(nextState.uploadCapByFileKey);
    }, []);

    useEffect(() => {
        if (!open) {
            return;
        }

        setSelectedOption(
            editItem?.type ?? (initialItems?.length ? "file" : null),
        );
        const defaultCollectionName =
            defaultCollectionID !== null && defaultCollectionID !== undefined
                ? displayCollectionsRef.current.find(
                      (collection) => collection.id === defaultCollectionID,
                  )?.name
                : undefined;
        setSelectedCollectionIDs(
            isEditMode
                ? normalizeSelectedCollectionIDs(
                      editCollectionIDs.length > 0
                          ? editCollectionIDs
                          : editCollectionID
                            ? [editCollectionID]
                            : [],
                  )
                : normalizeSelectedCollectionIDs(
                      defaultCollectionID !== null &&
                          defaultCollectionID !== undefined
                          ? [defaultCollectionID]
                          : [],
                  ),
        );
        setFormData(editItem ? (editItem.data as Record<string, string>) : {});
        setShowPassword(false);
        setSelectedUploadItems(initialItems ?? []);
        setCustomCollectionNames([]);
        setSelectedCollectionNamesByFileKey(
            collectionNamesByUploadItem(
                initialItems ?? [],
                defaultCollectionName,
            ),
        );
        resetUploadState();
        setError(null);
        setUpgradeCTAType(null);
    }, [
        defaultCollectionID,
        editCollectionIDs,
        editCollectionID,
        editItem,
        initialItems,
        isEditMode,
        normalizeSelectedCollectionIDs,
        open,
        resetUploadState,
    ]);

    useEffect(() => {
        if (
            !open ||
            isEditMode ||
            selectedCollectionIDs.every((selectedCollectionID) =>
                displayCollections.some(
                    (collection) => collection.id === selectedCollectionID,
                ),
            )
        ) {
            return;
        }

        setSelectedCollectionIDs((current) =>
            current.filter((selectedCollectionID) =>
                displayCollections.some(
                    (collection) => collection.id === selectedCollectionID,
                ),
            ),
        );
    }, [displayCollections, isEditMode, open, selectedCollectionIDs]);

    useEffect(() => {
        if (
            !open ||
            isEditMode ||
            selectedCollectionIDs.length > 0 ||
            defaultCollectionID === null ||
            defaultCollectionID === undefined ||
            !displayCollections.some(
                (collection) => collection.id === defaultCollectionID,
            )
        ) {
            return;
        }

        setSelectedCollectionIDs([defaultCollectionID]);
    }, [
        defaultCollectionID,
        displayCollections,
        isEditMode,
        open,
        selectedCollectionIDs.length,
    ]);

    const handleClose = useCallback(() => {
        if (saving || uploading) {
            return;
        }

        onClose();
    }, [onClose, saving, uploading]);

    const handleStepBackToOptions = useCallback(() => {
        if (isEditMode || saving || uploading) {
            return;
        }

        setSelectedOption(null);
        setFormData({});
        setShowPassword(false);
        setError(null);
        setUpgradeCTAType(null);
    }, [isEditMode, saving, uploading]);

    const handleDialogClose = useCallback(
        (_event: object, reason?: "backdropClick" | "escapeKeyDown") => {
            if (
                reason === "escapeKeyDown" &&
                selectedType !== null &&
                !isEditMode
            ) {
                handleStepBackToOptions();
                return;
            }

            handleClose();
        },
        [handleClose, handleStepBackToOptions, isEditMode, selectedType],
    );

    const handleSelectOption = useCallback(
        (option: CreateOption) => {
            setSelectedOption(option);
            setFormData({});
            setSelectedUploadItems([]);
            setCustomCollectionNames([]);
            setSelectedCollectionNamesByFileKey({});
            resetUploadState();
            setError(null);
            setUpgradeCTAType(null);
        },
        [resetUploadState],
    );

    const handleFieldChange = useCallback((field: string, value: string) => {
        setFormData((previous) => ({ ...previous, [field]: value }));
        setError(null);
        setUpgradeCTAType(null);
    }, []);

    const handleFileSelect = useCallback(
        (event: React.ChangeEvent<HTMLInputElement>) => {
            const files = Array.from(event.target.files ?? []);
            if (files.length > 0) {
                const defaultCollectionName =
                    selectedCollectionIDs.length > 0
                        ? displayCollectionsRef.current.find((collection) =>
                              selectedCollectionIDs.includes(collection.id),
                          )?.name
                        : undefined;
                const items = files.map((file) => ({
                    file,
                    relativePath: file.webkitRelativePath || file.name,
                    suggestedCollectionNames: [],
                }));
                setSelectedUploadItems(items);
                setCustomCollectionNames([]);
                setSelectedCollectionNamesByFileKey(
                    collectionNamesByUploadItem(items, defaultCollectionName),
                );
                resetUploadState();
                setError(null);
                setUpgradeCTAType(null);
            }
        },
        [resetUploadState, selectedCollectionIDs],
    );

    const handleSave = useCallback(async () => {
        if (!selectedType || selectedCollectionIDs.length === 0) {
            return;
        }

        for (const field of getRequiredFields(selectedType)) {
            const value = formData[field];
            if (typeof value !== "string" || !value.trim()) {
                setError(t("required_field"));
                return;
            }
        }

        setSaving(true);
        setError(null);
        setUpgradeCTAType(null);
        try {
            const cleanData = Object.fromEntries(
                Object.entries(formData)
                    .filter(
                        ([, value]) =>
                            typeof value === "string" && value.trim(),
                    )
                    .map(([key, value]) => [key, value.trim()]),
            );
            await onSave(selectedType, cleanData, selectedCollectionIDs);
            handleClose();
        } catch (error) {
            log.error("Failed to save Locker item", error);
            setError(await formatLockerMutationError(error, "createItem"));
            setUpgradeCTAType(await lockerUpgradeCTAType(error));
        } finally {
            setSaving(false);
        }
    }, [formData, handleClose, onSave, selectedCollectionIDs, selectedType]);

    const handleUpload = useCallback(async () => {
        if (selectedUploadItems.length === 0 || !onUploadProgress) {
            return;
        }

        const pendingUploadItems = selectedUploadItems.filter(
            (item) => !completedFileKeys.has(uploadQueueItemKey(item)),
        );
        if (pendingUploadItems.length === 0) {
            return;
        }

        setUploading(true);
        setError(null);
        setUpgradeCTAType(null);
        const pendingUploadFileKeys = new Set(
            pendingUploadItems.map((item) => uploadQueueItemKey(item)),
        );
        setFailedFileKeys((current) => {
            const next = new Set(current);
            pendingUploadFileKeys.forEach((fileKey) => next.delete(fileKey));
            return next;
        });
        setUploadingFileKeys((current) => {
            const next = new Set(current);
            pendingUploadFileKeys.forEach((fileKey) => next.delete(fileKey));
            return next;
        });
        setUploadProgressByFileKey((current) =>
            Object.fromEntries(
                Object.entries(current).filter(
                    ([fileKey]) => !pendingUploadFileKeys.has(fileKey),
                ),
            ),
        );
        setUploadCapByFileKey((current) =>
            Object.fromEntries(
                Object.entries(current).filter(
                    ([fileKey]) => !pendingUploadFileKeys.has(fileKey),
                ),
            ),
        );
        let uploadedCount = 0;
        try {
            const existingNormalizedNameToID = new Map(
                displayCollections.map((collection) => [
                    normalizeCollectionName(collection.name),
                    collection.id,
                ]),
            );
            const normalizedNameToIDResult = await onEnsureCollections?.(
                dedupeCollectionNames(
                    Object.values(selectedCollectionNamesByFileKey).flat(),
                ),
            );
            const normalizedNameToID = new Map(existingNormalizedNameToID);
            if (normalizedNameToIDResult instanceof Map) {
                for (const [name, id] of normalizedNameToIDResult.entries()) {
                    normalizedNameToID.set(normalizeCollectionName(name), id);
                }
            } else {
                for (const [name, id] of Object.entries(
                    normalizedNameToIDResult ?? {},
                )) {
                    normalizedNameToID.set(normalizeCollectionName(name), id);
                }
            }
            const uploadTargets = pendingUploadItems.map((item) => {
                const fileKey = uploadQueueItemKey(item);
                const collectionIDs = dedupeCollectionNames(
                    selectedCollectionNamesByFileKey[fileKey] ?? [],
                )
                    .map((name) =>
                        normalizedNameToID.get(normalizeCollectionName(name)),
                    )
                    .filter((id): id is number => typeof id === "number");
                return { item, fileKey, collectionIDs };
            });

            if (
                uploadTargets.some(
                    ({ collectionIDs }) => collectionIDs.length === 0,
                )
            ) {
                setError(t("required_field"));
                setUpgradeCTAType(null);
                return;
            }

            let nextIndex = 0;
            const worker = async () => {
                while (true) {
                    const target = uploadTargets[nextIndex];
                    nextIndex += 1;
                    if (!target) {
                        return;
                    }

                    const { item, fileKey, collectionIDs } = target;
                    setUploadingFileKeys((current) =>
                        new Set(current).add(fileKey),
                    );
                    setUploadCapByFileKey((current) => ({
                        ...current,
                        [fileKey]: 90 + Math.floor(Math.random() * 10),
                    }));
                    setUploadProgressByFileKey((current) => ({
                        ...current,
                        [fileKey]: { phase: "preparing" },
                    }));

                    try {
                        await onUploadProgress(
                            item.file,
                            collectionIDs,
                            (progress) => {
                                setUploadProgressByFileKey((current) => ({
                                    ...current,
                                    [fileKey]: progress,
                                }));
                            },
                        );
                        uploadedCount += 1;
                        setCompletedFileKeys((current) =>
                            new Set(current).add(fileKey),
                        );
                        setFailedFileKeys((current) => {
                            const next = new Set(current);
                            next.delete(fileKey);
                            return next;
                        });
                        onUploadItemComplete?.();
                    } catch (error) {
                        log.error("Failed to upload Locker file", error);
                        const formattedError = await formatLockerMutationError(
                            error,
                            "uploadFile",
                        );
                        setError((current) => current ?? formattedError);
                        if (!upgradeCTAType) {
                            setUpgradeCTAType(
                                await lockerUpgradeCTAType(error),
                            );
                        }
                        setFailedFileKeys((current) =>
                            new Set(current).add(fileKey),
                        );
                    } finally {
                        setUploadingFileKeys((current) => {
                            const next = new Set(current);
                            next.delete(fileKey);
                            return next;
                        });
                    }
                }
            };

            await Promise.all(
                Array.from({
                    length: Math.min(
                        MAX_PARALLEL_UPLOADS,
                        selectedUploadItems.length,
                    ),
                }).map(() => worker()),
            );

            if (uploadedCount > 0) {
                await onUploadsFinished?.(uploadedCount);
            }
            if (
                completedFileKeys.size + uploadedCount ===
                selectedUploadItems.length
            ) {
                handleClose();
            }
        } catch (error) {
            log.error("Failed to upload Locker files", error);
            setError(await formatLockerMutationError(error, "uploadFile"));
            setUpgradeCTAType(await lockerUpgradeCTAType(error));
        } finally {
            setUploading(false);
        }
    }, [
        handleClose,
        displayCollections,
        onEnsureCollections,
        onUploadProgress,
        onUploadItemComplete,
        onUploadsFinished,
        completedFileKeys,
        upgradeCTAType,
        selectedCollectionNamesByFileKey,
        selectedUploadItems,
    ]);

    const canSave =
        selectedType !== null &&
        selectedCollectionIDs.length > 0 &&
        getRequiredFields(selectedType).every(
            (field) =>
                typeof formData[field] === "string" && formData[field].trim(),
        );

    const canUpload =
        isFileMode &&
        selectedUploadItems.length > 0 &&
        selectedUploadItems.every(
            (item) =>
                (selectedCollectionNamesByFileKey[uploadQueueItemKey(item)]
                    ?.length ?? 0) > 0,
        ) &&
        selectedUploadItems.some(
            (item) => !completedFileKeys.has(uploadQueueItemKey(item)),
        );
    const savedUploadCount = completedFileKeys.size;
    const totalUploadCount = selectedUploadItems.length;
    const showUploadCounter = isFileMode && totalUploadCount > 0;
    const shouldShowDialogErrorCard =
        !!error && (isFileMode || upgradeCTAType === "fileCountLimit");

    return (
        <Dialog
            open={open}
            onClose={handleDialogClose}
            fullWidth
            maxWidth="sm"
            slotProps={{
                paper: {
                    sx: {
                        ...lockerDialogPaperSx,
                        display: "flex",
                        flexDirection: "column",
                        maxHeight: "min(720px, 90vh)",
                        width: "min(100%, 520px)",
                    },
                },
            }}
        >
            <DialogTitle
                sx={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    gap: 2,
                    fontWeight: "bold",
                    px: { xs: 4, sm: 5 },
                    pt: { xs: 4, sm: 4.5 },
                    pb: { xs: 2, sm: 2.5 },
                }}
            >
                <Box sx={{ minWidth: 0 }}>
                    {isEditMode
                        ? t("editItem")
                        : isFileMode
                          ? selectedUploadItems.length > 1
                              ? t("saveDocumentsTitle")
                              : t("saveDocumentTitle")
                          : selectedType
                            ? typeDisplayName(selectedType)
                            : t("saveToLocker")}
                </Box>
                {showUploadCounter && (
                    <Typography
                        variant="small"
                        sx={{
                            flexShrink: 0,
                            color: "text.muted",
                            opacity: 0.8,
                            fontWeight: 500,
                            alignSelf: "center",
                        }}
                    >
                        {savedUploadCount} / {totalUploadCount} {t("saved")}
                    </Typography>
                )}
            </DialogTitle>

            <DialogContent
                sx={{
                    px: { xs: 4, sm: 5 },
                    py: { xs: 2.5, sm: 3 },
                    ...(isFileMode
                        ? {
                              display: "flex",
                              flexDirection: "column",
                              flex: 1,
                              minHeight: 0,
                              overflow: "hidden",
                          }
                        : {}),
                }}
            >
                {shouldShowDialogErrorCard && (
                    <Box
                        sx={(theme) => ({
                            mb: 2.5,
                            px: 2,
                            py: 1.5,
                            borderRadius: "16px",
                            border: `1px solid ${theme.vars.palette.critical.main}22`,
                            backgroundColor: `${theme.vars.palette.critical.main}12`,
                        })}
                    >
                        <Typography
                            variant="small"
                            sx={{ color: "critical.main", fontWeight: 600 }}
                        >
                            {upgradeCTAType === "fileCountLimit" ? (
                                <Trans
                                    i18nKey="uploadFileCountLimitErrorBodyWithUpgrade"
                                    components={{
                                        cta: (
                                            <Link
                                                href="https://web.ente.io"
                                                target="_blank"
                                                rel="noreferrer"
                                                underline="always"
                                                sx={{
                                                    color: "critical.main",
                                                    fontWeight: 700,
                                                }}
                                            />
                                        ),
                                    }}
                                />
                            ) : (
                                error
                            )}
                        </Typography>
                    </Box>
                )}

                {!isEditMode && !selectedOption && (
                    <Stack sx={{ gap: 2, pt: 0.5 }}>
                        <Typography variant="body" sx={{ color: "text.muted" }}>
                            {t("informationDescription")}
                        </Typography>
                        <Stack sx={{ gap: 1 }}>
                            {CREATABLE_TYPES.map((option) => (
                                <TypeCard
                                    key={option.type}
                                    label={t(option.labelKey)}
                                    description={t(option.descriptionKey)}
                                    icon={option.icon}
                                    bgColor={option.bgColor}
                                    onClick={() =>
                                        handleSelectOption(option.type)
                                    }
                                />
                            ))}
                        </Stack>
                    </Stack>
                )}

                {isFileMode && !isEditMode && (
                    <FileUploadSection
                        fileInputRef={fileInputRef}
                        selectedUploadItems={selectedUploadItems}
                        collections={displayCollections}
                        availableCollectionNames={customCollectionNames}
                        selectedCollectionNamesByFileKey={
                            selectedCollectionNamesByFileKey
                        }
                        completedFileKeys={completedFileKeys}
                        failedFileKeys={failedFileKeys}
                        uploadingFileKeys={uploadingFileKeys}
                        uploadProgressByFileKey={uploadProgressByFileKey}
                        uploadCapByFileKey={uploadCapByFileKey}
                        uploading={uploading}
                        canUpload={canUpload}
                        onFileSelect={handleFileSelect}
                        onToggleCollectionName={(fileKey, name) =>
                            setSelectedCollectionNamesByFileKey((current) => ({
                                ...current,
                                [fileKey]: toggleCollectionName(
                                    current[fileKey] ?? [],
                                    name,
                                ),
                            }))
                        }
                        onAddCollectionName={(fileKey, name) => {
                            setCustomCollectionNames((current) =>
                                addCollectionName(current, name),
                            );
                            setSelectedCollectionNamesByFileKey((current) => ({
                                ...current,
                                [fileKey]: addCollectionName(
                                    current[fileKey] ?? [],
                                    name,
                                ),
                            }));
                        }}
                        onAddAvailableCollectionName={(name) =>
                            setCustomCollectionNames((current) =>
                                addCollectionName(current, name),
                            )
                        }
                        onSetCollectionNamesForAllItems={(names) =>
                            setSelectedCollectionNamesByFileKey(
                                Object.fromEntries(
                                    selectedUploadItems.map((item) => [
                                        uploadQueueItemKey(item),
                                        names,
                                    ]),
                                ),
                            )
                        }
                        onRemoveItem={(fileKey) => {
                            setSelectedUploadItems((current) =>
                                current.filter(
                                    (item) =>
                                        uploadQueueItemKey(item) !== fileKey,
                                ),
                            );
                            setSelectedCollectionNamesByFileKey((current) =>
                                Object.fromEntries(
                                    Object.entries(current).filter(
                                        ([key]) => key !== fileKey,
                                    ),
                                ),
                            );
                        }}
                        onClose={handleClose}
                        onUpload={handleUpload}
                    />
                )}

                {selectedType && !isFileMode && (
                    <Stack sx={{ gap: 2.5, pt: 0.5 }}>
                        <ItemForm
                            type={selectedType}
                            data={formData}
                            onChange={handleFieldChange}
                            showPassword={showPassword}
                            onTogglePassword={() =>
                                setShowPassword((value) => !value)
                            }
                        />

                        <CollectionSelector
                            collections={displayCollections}
                            selectedIDs={selectedCollectionIDs}
                            initialSelectedIDs={
                                isEditMode ? editCollectionIDs : undefined
                            }
                            onToggle={(collectionID) =>
                                setSelectedCollectionIDs((current) =>
                                    current.includes(collectionID)
                                        ? current.filter(
                                              (id) => id !== collectionID,
                                          )
                                        : [...current, collectionID],
                                )
                            }
                            onCreateCollection={onCreateCollection}
                        />

                        {error && upgradeCTAType !== "fileCountLimit" && (
                            <Typography
                                variant="small"
                                sx={{ color: "critical.main" }}
                            >
                                {error}
                            </Typography>
                        )}

                        <Stack direction="row" sx={{ gap: 1, pt: 1 }}>
                            <FocusVisibleButton
                                fullWidth
                                color="secondary"
                                onClick={handleClose}
                                disabled={saving}
                            >
                                {t("cancel")}
                            </FocusVisibleButton>
                            <LoadingButton
                                fullWidth
                                color="accent"
                                loading={saving}
                                disabled={!canSave}
                                onClick={() => void handleSave()}
                            >
                                {t("saveRecord")}
                            </LoadingButton>
                        </Stack>
                    </Stack>
                )}
            </DialogContent>
        </Dialog>
    );
};

const TypeCard: React.FC<{
    label: string;
    description: string;
    icon: React.ReactNode;
    bgColor: string;
    onClick: () => void;
}> = ({ label, description, icon, bgColor, onClick }) => (
    <ButtonBase
        onClick={onClick}
        sx={(theme) => ({
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            width: "100%",
            gap: 2,
            px: 1,
            py: 1.25,
            borderRadius: "12px",
            transition: "background-color 0.15s",
            textAlign: "left",
            "&:hover": { backgroundColor: theme.vars.palette.fill.faintHover },
        })}
    >
        <Box
            sx={{
                display: "flex",
                alignItems: "center",
                gap: 2,
                minWidth: 0,
                flex: 1,
            }}
        >
            <Box
                sx={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    width: 48,
                    height: 48,
                    borderRadius: "50%",
                    backgroundColor: bgColor,
                    flexShrink: 0,
                }}
            >
                {icon}
            </Box>
            <Box sx={{ minWidth: 0, flex: 1 }}>
                <Typography variant="body" sx={{ fontWeight: "medium" }}>
                    {label}
                </Typography>
                <Typography
                    variant="small"
                    sx={{ color: "text.muted", textWrap: "balance" }}
                >
                    {description}
                </Typography>
            </Box>
        </Box>
        <ChevronRightRoundedIcon sx={{ color: "text.faint", flexShrink: 0 }} />
    </ButtonBase>
);

const ItemForm: React.FC<{
    type: LockerItemType;
    data: Record<string, string>;
    onChange: (field: string, value: string) => void;
    showPassword: boolean;
    onTogglePassword: () => void;
}> = ({ type, data, onChange, showPassword, onTogglePassword }) => {
    switch (type) {
        case "note":
            return (
                <Stack sx={{ gap: 2 }}>
                    <TextField
                        label={t("noteName")}
                        value={data.title ?? ""}
                        onChange={(event) =>
                            onChange("title", event.target.value)
                        }
                        fullWidth
                        required
                        autoFocus
                    />
                    <TextField
                        label={t("noteContent")}
                        value={data.content ?? ""}
                        onChange={(event) =>
                            onChange("content", event.target.value)
                        }
                        fullWidth
                        required
                        multiline
                        minRows={4}
                        maxRows={10}
                    />
                </Stack>
            );
        case "accountCredential":
            return (
                <Stack sx={{ gap: 2 }}>
                    <TextField
                        label={t("credentialName")}
                        value={data.name ?? ""}
                        onChange={(event) =>
                            onChange("name", event.target.value)
                        }
                        fullWidth
                        required
                        autoFocus
                    />
                    <TextField
                        label={t("username")}
                        value={data.username ?? ""}
                        onChange={(event) =>
                            onChange("username", event.target.value)
                        }
                        fullWidth
                        required
                    />
                    <TextField
                        label={t("password")}
                        value={data.password ?? ""}
                        onChange={(event) =>
                            onChange("password", event.target.value)
                        }
                        fullWidth
                        required
                        type={showPassword ? "text" : "password"}
                        slotProps={{
                            input: {
                                endAdornment: (
                                    <InputAdornment position="end">
                                        <IconButton
                                            onClick={onTogglePassword}
                                            edge="end"
                                            size="small"
                                        >
                                            {showPassword ? (
                                                <VisibilityOffIcon />
                                            ) : (
                                                <VisibilityIcon />
                                            )}
                                        </IconButton>
                                    </InputAdornment>
                                ),
                            },
                        }}
                    />
                    <TextField
                        label={t("credentialNotes")}
                        value={data.notes ?? ""}
                        onChange={(event) =>
                            onChange("notes", event.target.value)
                        }
                        fullWidth
                        multiline
                        minRows={2}
                        maxRows={5}
                    />
                </Stack>
            );
        case "physicalRecord":
            return (
                <Stack sx={{ gap: 2 }}>
                    <TextField
                        label={t("recordName")}
                        value={data.name ?? ""}
                        onChange={(event) =>
                            onChange("name", event.target.value)
                        }
                        fullWidth
                        required
                        autoFocus
                    />
                    <TextField
                        label={t("recordLocation")}
                        value={data.location ?? ""}
                        onChange={(event) =>
                            onChange("location", event.target.value)
                        }
                        fullWidth
                        required
                    />
                    <TextField
                        label={t("recordNotes")}
                        value={data.notes ?? ""}
                        onChange={(event) =>
                            onChange("notes", event.target.value)
                        }
                        fullWidth
                        multiline
                        minRows={2}
                        maxRows={5}
                    />
                </Stack>
            );
        case "emergencyContact":
            return (
                <Stack sx={{ gap: 2 }}>
                    <TextField
                        label={t("contactName")}
                        value={data.name ?? ""}
                        onChange={(event) =>
                            onChange("name", event.target.value)
                        }
                        fullWidth
                        required
                        autoFocus
                    />
                    <TextField
                        label={t("contactDetails")}
                        value={data.contactDetails ?? ""}
                        onChange={(event) =>
                            onChange("contactDetails", event.target.value)
                        }
                        fullWidth
                        required
                    />
                    <TextField
                        label={t("contactNotes")}
                        value={data.notes ?? ""}
                        onChange={(event) =>
                            onChange("notes", event.target.value)
                        }
                        fullWidth
                        multiline
                        minRows={2}
                        maxRows={5}
                    />
                </Stack>
            );
        case "file":
            return (
                <Stack sx={{ gap: 2 }}>
                    <TextField
                        label={t("fileTitle")}
                        value={data.name ?? ""}
                        onChange={(event) =>
                            onChange("name", event.target.value)
                        }
                        fullWidth
                        required
                        autoFocus
                    />
                </Stack>
            );
        default:
            return null;
    }
};

const getRequiredFields = (type: LockerItemType): string[] => {
    switch (type) {
        case "note":
            return ["title", "content"];
        case "accountCredential":
            return ["name", "username", "password"];
        case "physicalRecord":
            return ["name", "location"];
        case "emergencyContact":
            return ["name", "contactDetails"];
        case "file":
            return ["name"];
        default:
            return [];
    }
};

const typeDisplayName = (type: LockerItemType): string => {
    switch (type) {
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
};

const CollectionSelector: React.FC<{
    collections: LockerCollection[];
    selectedIDs: number[];
    initialSelectedIDs?: number[];
    onToggle: (id: number) => void;
    onCreateCollection?: (name: string) => Promise<number>;
}> = ({
    collections,
    selectedIDs,
    initialSelectedIDs,
    onToggle,
    onCreateCollection,
}) => {
    const [createOpen, setCreateOpen] = useState(false);
    const [createName, setCreateName] = useState("");
    const [creating, setCreating] = useState(false);
    const [createError, setCreateError] = useState<string | null>(null);
    const orderedCollections = useMemo(() => {
        const sortedCollections = [...collections].sort((a, b) =>
            a.name.localeCompare(b.name, undefined, { sensitivity: "base" }),
        );
        const initialSelectedIDSet = new Set(initialSelectedIDs ?? []);
        if (initialSelectedIDSet.size === 0) {
            return sortedCollections;
        }

        const initialSelectedCollections = sortedCollections.filter(
            (collection) => initialSelectedIDSet.has(collection.id),
        );
        const remainingCollections = sortedCollections.filter(
            (collection) => !initialSelectedIDSet.has(collection.id),
        );
        return [...initialSelectedCollections, ...remainingCollections];
    }, [collections, initialSelectedIDs]);

    const handleCreateCollection = useCallback(async () => {
        const name = createName.trim();
        if (!onCreateCollection || !name) {
            return;
        }

        setCreating(true);
        setCreateError(null);
        try {
            const newCollectionID = await onCreateCollection(name);
            onToggle(newCollectionID);
            setCreateName("");
            setCreateOpen(false);
        } catch (error) {
            setCreateError(
                error instanceof Error
                    ? error.message
                    : t("failedToCreateCollection"),
            );
        } finally {
            setCreating(false);
        }
    }, [createName, onCreateCollection, onToggle]);

    return (
        <Box>
            <CollectionChipRow
                items={orderedCollections.map((collection) => ({
                    key: String(collection.id),
                    label: collection.name,
                    selected: selectedIDs.includes(collection.id),
                    onClick: () => onToggle(collection.id),
                }))}
                createOpen={createOpen}
                onCreateClick={
                    onCreateCollection
                        ? () => {
                              setCreateOpen((open) => !open);
                              setCreateError(null);
                          }
                        : undefined
                }
            />

            {createOpen && onCreateCollection && (
                <Stack sx={{ gap: 1, mt: 1.5 }}>
                    <Stack
                        direction="row"
                        sx={{ gap: 1, alignItems: "center" }}
                    >
                        <TextField
                            size="small"
                            fullWidth
                            autoFocus
                            placeholder={t("enterCollectionName")}
                            sx={{
                                "& .MuiInputBase-root": {
                                    height: 48,
                                    borderRadius: "14px",
                                },
                                "& .MuiInputBase-input": { pt: 1, pb: 0.5 },
                            }}
                            value={createName}
                            onChange={(event) => {
                                setCreateName(event.target.value);
                                setCreateError(null);
                            }}
                            onKeyDown={(event) => {
                                if (event.key === "Escape") {
                                    event.preventDefault();
                                    event.stopPropagation();
                                    setCreateOpen(false);
                                    setCreateError(null);
                                    return;
                                }
                                if (event.key === "Enter") {
                                    event.preventDefault();
                                    void handleCreateCollection();
                                }
                            }}
                        />
                        <LoadingButton
                            color="accent"
                            loading={creating}
                            disabled={!createName.trim()}
                            aria-label={t("create")}
                            onClick={() => void handleCreateCollection()}
                            sx={{
                                minWidth: 0,
                                width: 48,
                                height: 48,
                                p: 0,
                                borderRadius: "14px",
                                flexShrink: 0,
                            }}
                        >
                            <CheckRoundedIcon />
                        </LoadingButton>
                    </Stack>
                    {createError && (
                        <Typography
                            variant="small"
                            sx={{ color: "critical.main" }}
                        >
                            {createError}
                        </Typography>
                    )}
                </Stack>
            )}
        </Box>
    );
};
