import CheckRoundedIcon from "@mui/icons-material/CheckRounded";
import ChevronRightRoundedIcon from "@mui/icons-material/ChevronRightRounded";
import CloudUploadOutlinedIcon from "@mui/icons-material/CloudUploadOutlined";
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
    onCreateCollection?: (name: string) => Promise<number>;
    defaultCollectionID?: number | null;
    initialFile?: File | null;
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
    onCreateCollection,
    defaultCollectionID,
    initialFile,
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
    const [selectedFile, setSelectedFile] = useState<File | null>(null);
    const [uploadProgress, setUploadProgress] =
        useState<LockerUploadProgress | null>(null);

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

        setSelectedOption(editItem?.type ?? (initialFile ? "file" : null));
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
        setSelectedFile(initialFile ?? null);
        setError(null);
        setUploadProgress(null);
    }, [
        defaultCollectionID,
        editCollectionID,
        editItem,
        initialFile,
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

    const handleClose = useCallback(() => {
        if (saving || uploading) {
            return;
        }

        setError(null);
        setShowPassword(false);
        setSelectedFile(null);
        setUploadProgress(null);
        onClose();
    }, [onClose, saving, uploading]);

    const handleSelectOption = useCallback((option: CreateOption) => {
        setSelectedOption(option);
        setFormData({});
        setSelectedFile(null);
        setError(null);
    }, []);

    const handleFieldChange = useCallback((field: string, value: string) => {
        setFormData((previous) => ({ ...previous, [field]: value }));
        setError(null);
    }, []);

    const handleFileSelect = useCallback(
        (event: React.ChangeEvent<HTMLInputElement>) => {
            const file = event.target.files?.[0];
            if (file) {
                setSelectedFile(file);
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
            !selectedFile ||
            selectedCollectionIDs.length === 0 ||
            !onUploadProgress
        ) {
            return;
        }

        setUploading(true);
        setError(null);
        setUploadProgress({ phase: "preparing" });
        try {
            await onUploadProgress(
                selectedFile,
                selectedCollectionIDs,
                setUploadProgress,
            );
            handleClose();
        } catch (error) {
            log.error("Failed to upload Locker file", error);
            setError(await formatLockerMutationError(error, "uploadFile"));
        } finally {
            setUploading(false);
        }
    }, [handleClose, onUploadProgress, selectedCollectionIDs, selectedFile]);

    const canSave =
        selectedType !== null &&
        selectedCollectionIDs.length > 0 &&
        getRequiredFields(selectedType).every((field) =>
            formData[field]?.trim(),
        );

    const canUpload =
        isFileMode && selectedCollectionIDs.length > 0 && selectedFile !== null;

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
                            hidden
                            onChange={handleFileSelect}
                        />

                        {!selectedFile ? (
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
                            <Stack
                                sx={{
                                    borderRadius: "12px",
                                    backgroundColor: (theme) =>
                                        theme.vars.palette.fill.faint,
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
                                            justifyContent: "center",
                                            width: 48,
                                            height: 48,
                                            borderRadius: "12px",
                                            backgroundColor:
                                                lockerItemIconConfig(
                                                    "file",
                                                    selectedFile.name,
                                                ).backgroundColor,
                                            flexShrink: 0,
                                        }}
                                    >
                                        {lockerItemIcon("file", {
                                            fileName: selectedFile.name,
                                            size: 24,
                                            strokeWidth: 1.9,
                                        })}
                                    </Box>
                                    <Box sx={{ flex: 1, minWidth: 0 }}>
                                        <Typography variant="body" noWrap>
                                            {selectedFile.name}
                                        </Typography>
                                        <Typography
                                            variant="small"
                                            sx={{ color: "text.faint" }}
                                        >
                                            {formatFileSize(selectedFile.size)}
                                        </Typography>
                                    </Box>
                                    {!uploading && (
                                        <FocusVisibleButton
                                            size="small"
                                            color="secondary"
                                            onClick={() => {
                                                setSelectedFile(null);
                                                if (fileInputRef.current) {
                                                    fileInputRef.current.value =
                                                        "";
                                                }
                                            }}
                                        >
                                            {t("change")}
                                        </FocusVisibleButton>
                                    )}
                                </Stack>
                                {uploading && (
                                    <LinearProgress
                                        variant={
                                            uploadProgress?.phase ===
                                            "uploading"
                                                ? "determinate"
                                                : "indeterminate"
                                        }
                                        value={
                                            uploadProgress?.phase ===
                                            "uploading"
                                                ? Math.min(
                                                      100,
                                                      (uploadProgress.loaded /
                                                          Math.max(
                                                              uploadProgress.total,
                                                              1,
                                                          )) *
                                                          100,
                                                  )
                                                : undefined
                                        }
                                        sx={{ height: 4, borderRadius: 0 }}
                                    />
                                )}
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
