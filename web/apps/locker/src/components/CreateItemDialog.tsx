import CheckRoundedIcon from "@mui/icons-material/CheckRounded";
import ChevronRightRoundedIcon from "@mui/icons-material/ChevronRightRounded";
import CloudUploadOutlinedIcon from "@mui/icons-material/CloudUploadOutlined";
import ErrorOutlineRoundedIcon from "@mui/icons-material/ErrorOutlineRounded";
import ScheduleRoundedIcon from "@mui/icons-material/ScheduleRounded";
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
    LinearProgress,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
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
import { formatLockerMutationError } from "services/locker-errors";
import type { LockerUploadProgress } from "services/remote";
import type { LockerCollection, LockerItemType } from "types";
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
    defaultCollectionID?: number | null;
    initialFiles?: File[];
    editItem?: {
        id: number;
        type: LockerItemType;
        data: Record<string, unknown>;
        collectionID: number;
    } | null;
}

export const CreateItemDialog: React.FC<CreateItemDialogProps> = ({
    open,
    onClose,
    collections,
    onSave,
    onUploadProgress,
    onUploadItemComplete,
    onUploadsFinished,
    onCreateCollection,
    defaultCollectionID,
    initialFiles,
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
    const [formData, setFormData] = useState<Record<string, string>>(
        editItem ? (editItem.data as Record<string, string>) : {},
    );
    const [showPassword, setShowPassword] = useState(false);
    const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
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
    const [finalizingStartedAtByFileKey, setFinalizingStartedAtByFileKey] =
        useState<Record<string, number>>({});
    const [progressTick, setProgressTick] = useState(() => Date.now());

    const fileInputRef = useRef<HTMLInputElement>(null);
    const isFileMode = selectedOption === "file";
    const editCollectionID = editItem?.collectionID ?? null;
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

    useEffect(() => {
        if (!open) {
            return;
        }

        setSelectedOption(
            editItem?.type ?? (initialFiles?.length ? "file" : null),
        );
        setSelectedCollectionIDs(
            isEditMode
                ? editCollectionID
                    ? [editCollectionID]
                    : []
                : normalizeSelectedCollectionIDs(
                      defaultCollectionID !== null &&
                          defaultCollectionID !== undefined
                          ? [defaultCollectionID]
                          : [],
                  ),
        );
        setFormData(editItem ? (editItem.data as Record<string, string>) : {});
        setShowPassword(false);
        setSelectedFiles(initialFiles ?? []);
        setCompletedFileKeys(new Set());
        setFailedFileKeys(new Set());
        setUploadingFileKeys(new Set());
        setError(null);
        setUploadProgressByFileKey({});
        setUploadCapByFileKey({});
        setFinalizingStartedAtByFileKey({});
    }, [
        defaultCollectionID,
        editCollectionID,
        editItem,
        initialFiles,
        isEditMode,
        normalizeSelectedCollectionIDs,
        open,
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
        if (!uploading) {
            return;
        }

        const interval = window.setInterval(() => {
            setProgressTick(Date.now());
        }, 200);

        return () => window.clearInterval(interval);
    }, [uploading]);

    const handleClose = useCallback(() => {
        if (saving || uploading) {
            return;
        }

        setError(null);
        setShowPassword(false);
        setSelectedFiles([]);
        setCompletedFileKeys(new Set());
        setFailedFileKeys(new Set());
        setUploadingFileKeys(new Set());
        setUploadProgressByFileKey({});
        setUploadCapByFileKey({});
        setFinalizingStartedAtByFileKey({});
        onClose();
    }, [onClose, saving, uploading]);

    const handleSelectOption = useCallback((option: CreateOption) => {
        setSelectedOption(option);
        setFormData({});
        setSelectedFiles([]);
        setCompletedFileKeys(new Set());
        setFailedFileKeys(new Set());
        setUploadingFileKeys(new Set());
        setUploadProgressByFileKey({});
        setUploadCapByFileKey({});
        setFinalizingStartedAtByFileKey({});
        setError(null);
    }, []);

    const handleFieldChange = useCallback((field: string, value: string) => {
        setFormData((previous) => ({ ...previous, [field]: value }));
        setError(null);
    }, []);

    const handleFileSelect = useCallback(
        (event: React.ChangeEvent<HTMLInputElement>) => {
            const files = Array.from(event.target.files ?? []);
            if (files.length > 0) {
                setSelectedFiles(files);
                setCompletedFileKeys(new Set());
                setFailedFileKeys(new Set());
                setUploadingFileKeys(new Set());
                setUploadProgressByFileKey({});
                setUploadCapByFileKey({});
                setFinalizingStartedAtByFileKey({});
                setError(null);
            }
        },
        [],
    );

    const handleSave = useCallback(async () => {
        if (!selectedType || selectedCollectionIDs.length === 0) {
            return;
        }

        for (const field of getRequiredFields(selectedType)) {
            if (!formData[field]?.trim()) {
                setError(t("required_field"));
                return;
            }
        }

        setSaving(true);
        setError(null);
        try {
            const cleanData = Object.fromEntries(
                Object.entries(formData)
                    .filter(([, value]) => value.trim())
                    .map(([key, value]) => [key, value.trim()]),
            );
            await onSave(selectedType, cleanData, selectedCollectionIDs);
            handleClose();
        } catch (error) {
            log.error("Failed to save Locker item", error);
            setError(await formatLockerMutationError(error, "createItem"));
        } finally {
            setSaving(false);
        }
    }, [formData, handleClose, onSave, selectedCollectionIDs, selectedType]);

    const handleUpload = useCallback(async () => {
        if (
            selectedFiles.length === 0 ||
            selectedCollectionIDs.length === 0 ||
            !onUploadProgress
        ) {
            return;
        }

        setUploading(true);
        setError(null);
        setCompletedFileKeys(new Set());
        setFailedFileKeys(new Set());
        setUploadingFileKeys(new Set());
        setUploadProgressByFileKey({});
        setUploadCapByFileKey({});
        setFinalizingStartedAtByFileKey({});
        let uploadedCount = 0;
        try {
            let nextIndex = 0;
            const worker = async () => {
                while (true) {
                    const file = selectedFiles[nextIndex];
                    nextIndex += 1;
                    if (!file) {
                        return;
                    }

                    const fileKey = uploadQueueItemKey(file);
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
                            file,
                            selectedCollectionIDs,
                            (progress) => {
                                if (progress.phase === "finalizing") {
                                    setFinalizingStartedAtByFileKey(
                                        (current) =>
                                            current[fileKey]
                                                ? current
                                                : {
                                                      ...current,
                                                      [fileKey]: Date.now(),
                                                  },
                                    );
                                }
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
                        selectedFiles.length,
                    ),
                }).map(() => worker()),
            );

            if (uploadedCount > 0) {
                await onUploadsFinished?.(uploadedCount);
            }
            if (uploadedCount === selectedFiles.length) {
                handleClose();
            }
        } catch (error) {
            log.error("Failed to upload Locker files", error);
            setError(await formatLockerMutationError(error, "uploadFile"));
        } finally {
            setUploading(false);
        }
    }, [
        handleClose,
        onUploadProgress,
        onUploadItemComplete,
        onUploadsFinished,
        selectedCollectionIDs,
        selectedFiles,
    ]);

    const canSave =
        selectedType !== null &&
        selectedCollectionIDs.length > 0 &&
        getRequiredFields(selectedType).every((field) =>
            formData[field]?.trim(),
        );

    const canUpload =
        isFileMode &&
        selectedCollectionIDs.length > 0 &&
        selectedFiles.length > 0 &&
        completedFileKeys.size + failedFileKeys.size !== selectedFiles.length;

    return (
        <Dialog
            open={open}
            onClose={handleClose}
            fullWidth
            maxWidth="sm"
            slotProps={{
                paper: {
                    sx: {
                        ...lockerDialogPaperSx,
                        maxHeight: "min(720px, 90vh)",
                        width: "min(100%, 520px)",
                    },
                },
            }}
        >
            <DialogTitle
                sx={{
                    fontWeight: "bold",
                    px: { xs: 4, sm: 5 },
                    pt: { xs: 4, sm: 4.5 },
                    pb: { xs: 2, sm: 2.5 },
                }}
            >
                {isEditMode
                    ? t("editItem")
                    : isFileMode
                      ? t("saveDocumentTitle")
                      : selectedType
                        ? typeDisplayName(selectedType)
                        : t("saveToLocker")}
            </DialogTitle>

            <DialogContent
                sx={{ px: { xs: 4, sm: 5 }, py: { xs: 2.5, sm: 3 } }}
            >
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

                {isFileMode && (
                    <Stack sx={{ gap: 2.5, pt: 0.5 }}>
                        <input
                            ref={fileInputRef}
                            type="file"
                            multiple
                            hidden
                            onChange={handleFileSelect}
                        />

                        {selectedFiles.length === 0 ? (
                            <ButtonBase
                                onClick={() => fileInputRef.current?.click()}
                                sx={(theme) => ({
                                    display: "flex",
                                    flexDirection: "column",
                                    alignItems: "center",
                                    gap: 1.5,
                                    p: 4,
                                    borderRadius: "16px",
                                    border: `2px dashed ${theme.vars.palette.divider}`,
                                    backgroundColor:
                                        theme.vars.palette.fill.faint,
                                    transition: "background-color 0.15s",
                                    "&:hover": {
                                        backgroundColor:
                                            theme.vars.palette.fill.faintHover,
                                    },
                                })}
                            >
                                <CloudUploadOutlinedIcon
                                    sx={{ fontSize: 40, color: "text.faint" }}
                                />
                                <Typography
                                    variant="body"
                                    sx={{ color: "text.muted" }}
                                >
                                    {t("clickHereToUpload")}
                                </Typography>
                            </ButtonBase>
                        ) : (
                            <Stack sx={{ gap: 1.25 }}>
                                {selectedFiles.map((file) => {
                                    const fileKey = uploadQueueItemKey(file);
                                    const isDone =
                                        completedFileKeys.has(fileKey);
                                    const isFailed =
                                        failedFileKeys.has(fileKey);
                                    const isUploading =
                                        uploadingFileKeys.has(fileKey);
                                    const isQueued =
                                        !isDone &&
                                        !isFailed &&
                                        !isUploading &&
                                        uploading;
                                    const uploadProgress =
                                        uploadProgressByFileKey[fileKey];
                                    const uploadCap =
                                        uploadCapByFileKey[fileKey] ?? 95;
                                    const finalizingStartedAt =
                                        finalizingStartedAtByFileKey[fileKey];
                                    return (
                                        <Stack
                                            key={fileKey}
                                            sx={{
                                                borderRadius: "12px",
                                                backgroundColor: (theme) =>
                                                    theme.vars.palette.fill
                                                        .faint,
                                                overflow: "hidden",
                                            }}
                                        >
                                            <Stack
                                                direction="row"
                                                sx={{
                                                    alignItems: "center",
                                                    gap: 1.5,
                                                    p: 2,
                                                }}
                                            >
                                                <Box
                                                    sx={{
                                                        display: "flex",
                                                        alignItems: "center",
                                                        justifyContent:
                                                            "center",
                                                        width: 48,
                                                        height: 48,
                                                        borderRadius: "12px",
                                                        backgroundColor:
                                                            lockerItemIconConfig(
                                                                "file",
                                                                file.name,
                                                            ).backgroundColor,
                                                        flexShrink: 0,
                                                    }}
                                                >
                                                    {lockerItemIcon("file", {
                                                        fileName: file.name,
                                                        size: 24,
                                                        strokeWidth: 1.9,
                                                    })}
                                                </Box>
                                                <Box
                                                    sx={{
                                                        flex: 1,
                                                        minWidth: 0,
                                                    }}
                                                >
                                                    <Typography
                                                        variant="body"
                                                        noWrap
                                                    >
                                                        {file.name}
                                                    </Typography>
                                                    <Typography
                                                        variant="small"
                                                        sx={{
                                                            color: "text.faint",
                                                        }}
                                                    >
                                                        {formatFileSize(
                                                            file.size,
                                                        )}
                                                    </Typography>
                                                </Box>
                                                {isDone && (
                                                    <Box
                                                        sx={(theme) => ({
                                                            width: 24,
                                                            height: 24,
                                                            borderRadius: "50%",
                                                            display: "flex",
                                                            alignItems:
                                                                "center",
                                                            justifyContent:
                                                                "center",
                                                            backgroundColor:
                                                                theme.vars
                                                                    .palette
                                                                    .primary
                                                                    .main,
                                                            color: theme.vars
                                                                .palette.primary
                                                                .contrastText,
                                                            flexShrink: 0,
                                                        })}
                                                    >
                                                        <CheckRoundedIcon
                                                            sx={{
                                                                fontSize: 16,
                                                            }}
                                                        />
                                                    </Box>
                                                )}
                                                {isFailed && (
                                                    <ErrorOutlineRoundedIcon
                                                        sx={{
                                                            color: "critical.main",
                                                            fontSize: 20,
                                                            flexShrink: 0,
                                                        }}
                                                    />
                                                )}
                                                {isQueued && (
                                                    <ScheduleRoundedIcon
                                                        sx={{
                                                            color: "text.muted",
                                                            fontSize: 20,
                                                            flexShrink: 0,
                                                        }}
                                                    />
                                                )}
                                            </Stack>
                                            <Box sx={{ height: 4 }}>
                                                <LinearProgress
                                                    variant="determinate"
                                                    value={
                                                        isUploading
                                                            ? uploadProgressValue(
                                                                  uploadProgress,
                                                                  uploadCap,
                                                                  finalizingStartedAt,
                                                                  progressTick,
                                                              )
                                                            : isDone
                                                              ? 100
                                                              : 0
                                                    }
                                                    sx={{
                                                        height: 4,
                                                        borderRadius: 0,
                                                        opacity:
                                                            isUploading ||
                                                            isDone
                                                                ? 1
                                                                : 0,
                                                    }}
                                                />
                                            </Box>
                                        </Stack>
                                    );
                                })}
                            </Stack>
                        )}

                        {!isEditMode && (
                            <CollectionSelector
                                collections={displayCollections}
                                selectedIDs={selectedCollectionIDs}
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
                        )}

                        {error && (
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
                                disabled={uploading}
                                sx={{ borderRadius: "16px", py: 1.25 }}
                            >
                                {t("cancel")}
                            </FocusVisibleButton>
                            <LoadingButton
                                fullWidth
                                color="accent"
                                loading={uploading}
                                disabled={!canUpload}
                                sx={{ borderRadius: "16px", py: 1.25 }}
                                onClick={() => void handleUpload()}
                            >
                                {t("upload")}
                            </LoadingButton>
                        </Stack>
                    </Stack>
                )}

                {selectedType && (
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

                        {!isEditMode && (
                            <CollectionSelector
                                collections={displayCollections}
                                selectedIDs={selectedCollectionIDs}
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
                        )}

                        {error && (
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
                                {isEditMode ? t("saveRecord") : t("create")}
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

const uploadQueueItemKey = (file: File) =>
    `${file.name}:${file.size}:${file.lastModified}`;

const uploadProgressValue = (
    progress: LockerUploadProgress | null | undefined,
    uploadCap: number,
    finalizingStartedAt?: number,
    now = Date.now(),
) => {
    if (!progress) {
        return 0;
    }

    if (progress.phase === "uploading") {
        return Math.min(
            uploadCap,
            (progress.loaded / Math.max(progress.total, 1)) * uploadCap,
        );
    }

    if (progress.phase === "finalizing") {
        const start = finalizingStartedAt ?? now;
        const elapsed = Math.max(0, now - start);
        const finalTarget = 99;
        const easedFraction = 1 - Math.exp(-elapsed / 2200);
        return Math.min(
            finalTarget,
            uploadCap + (finalTarget - uploadCap) * easedFraction,
        );
    }

    return 0;
};

const CollectionSelector: React.FC<{
    collections: LockerCollection[];
    selectedIDs: number[];
    onToggle: (id: number) => void;
    onCreateCollection?: (name: string) => Promise<number>;
}> = ({ collections, selectedIDs, onToggle, onCreateCollection }) => {
    const [createOpen, setCreateOpen] = useState(false);
    const [createName, setCreateName] = useState("");
    const [creating, setCreating] = useState(false);
    const [createError, setCreateError] = useState<string | null>(null);

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
            <Stack
                direction="row"
                sx={{
                    alignItems: "center",
                    justifyContent: "space-between",
                    gap: 1,
                    mb: 1.5,
                }}
            >
                <Typography
                    variant="small"
                    sx={{
                        color: "text.faint",
                        fontWeight: "bold",
                        textTransform: "uppercase",
                        letterSpacing: "0.08em",
                        display: "block",
                    }}
                >
                    {t("collections")}
                </Typography>
            </Stack>

            {collections.length > 0 || onCreateCollection ? (
                <Stack direction="row" sx={{ gap: 1.5, flexWrap: "wrap" }}>
                    {onCreateCollection && (
                        <ButtonBase
                            onClick={() => {
                                setCreateOpen((open) => !open);
                                setCreateError(null);
                            }}
                            sx={(theme) => ({
                                borderRadius: "999px",
                                px: 1.5,
                                py: 0.875,
                                border: `1px dotted ${theme.vars.palette.stroke.muted}`,
                                color: theme.vars.palette.text.muted,
                                backgroundColor: createOpen
                                    ? theme.vars.palette.fill.faint
                                    : "transparent",
                            })}
                        >
                            <Typography variant="small">
                                + {t("collection")}
                            </Typography>
                        </ButtonBase>
                    )}
                    {collections.map((collection) => (
                        <ButtonBase
                            key={collection.id}
                            onClick={() => onToggle(collection.id)}
                            sx={(theme) => ({
                                borderRadius: "999px",
                                px: 1.5,
                                py: 0.875,
                                backgroundColor: selectedIDs.includes(
                                    collection.id,
                                )
                                    ? theme.vars.palette.primary.main
                                    : theme.vars.palette.fill.faint,
                                color: selectedIDs.includes(collection.id)
                                    ? theme.vars.palette.primary.contrastText
                                    : theme.vars.palette.text.base,
                            })}
                        >
                            <Typography variant="small">
                                {collection.name}
                            </Typography>
                        </ButtonBase>
                    ))}
                </Stack>
            ) : (
                <Typography variant="body" sx={{ color: "text.muted" }}>
                    {t("noCollectionsAvailableForSelection")}
                </Typography>
            )}

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

const formatFileSize = (bytes: number) => {
    if (bytes < 1024) {
        return `${bytes} B`;
    }
    if (bytes < 1024 * 1024) {
        return `${(bytes / 1024).toFixed(1)} KB`;
    }
    if (bytes < 1024 * 1024 * 1024) {
        return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
};
