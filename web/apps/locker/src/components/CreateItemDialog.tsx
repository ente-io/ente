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
import {
    createDocumentIcon,
    createDocumentIconConfig,
    lockerItemIcon,
    lockerItemIconConfig,
} from "components/lockerItemIcons";
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
import type { LockerCollection, LockerItemType } from "types";
import { visibleLockerCollections } from "types";

type CreateOption = LockerItemType | "file";

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
        icon: lockerItemIcon("physicalRecord", {
            size: 28,
            strokeWidth: 1.9,
        }),
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
        collectionID: number,
    ) => Promise<void>;
    onUploadFile?: (file: File, collectionID: number) => Promise<void>;
    onCreateCollection?: (name: string) => Promise<number>;
    defaultCollectionID?: number | null;
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
    onUploadFile,
    onCreateCollection,
    defaultCollectionID,
    editItem,
}) => {
    const isEditMode = !!editItem;
    const displayCollections = useMemo(
        () => visibleLockerCollections(collections),
        [collections],
    );
    const [selectedOption, setSelectedOption] = useState<CreateOption | null>(
        editItem?.type ?? null,
    );
    const [selectedCollectionID, setSelectedCollectionID] = useState<
        number | null
    >(editItem?.collectionID ?? defaultCollectionID ?? null);
    const [saving, setSaving] = useState(false);
    const [uploading, setUploading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [formData, setFormData] = useState<Record<string, string>>(
        editItem ? (editItem.data as Record<string, string>) : {},
    );
    const [showPassword, setShowPassword] = useState(false);
    const [selectedFile, setSelectedFile] = useState<File | null>(null);

    const fileInputRef = useRef<HTMLInputElement>(null);
    const isFileMode = selectedOption === "file";
    const selectedType =
        selectedOption && selectedOption !== "file"
            ? (selectedOption as LockerItemType)
            : null;

    useEffect(() => {
        if (!open) {
            return;
        }

        setSelectedOption(editItem?.type ?? null);
        setSelectedCollectionID(
            editItem?.collectionID ?? defaultCollectionID ?? null,
        );
        setFormData(editItem ? (editItem.data as Record<string, string>) : {});
        setShowPassword(false);
        setSelectedFile(null);
        setError(null);
    }, [defaultCollectionID, editItem, open]);

    const handleClose = useCallback(() => {
        if (saving || uploading) {
            return;
        }

        setError(null);
        setShowPassword(false);
        setSelectedFile(null);
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
        if (!selectedType || selectedCollectionID === null) {
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
            await onSave(selectedType, cleanData, selectedCollectionID);
            handleClose();
        } catch (error) {
            log.error("Failed to save Locker item", error);
            setError(await formatLockerMutationError(error, "createItem"));
        } finally {
            setSaving(false);
        }
    }, [formData, handleClose, onSave, selectedCollectionID, selectedType]);

    const handleUpload = useCallback(async () => {
        if (!selectedFile || selectedCollectionID === null || !onUploadFile) {
            return;
        }

        setUploading(true);
        setError(null);
        try {
            await onUploadFile(selectedFile, selectedCollectionID);
            handleClose();
        } catch (error) {
            log.error("Failed to upload Locker file", error);
            setError(await formatLockerMutationError(error, "uploadFile"));
        } finally {
            setUploading(false);
        }
    }, [handleClose, onUploadFile, selectedCollectionID, selectedFile]);

    const canSave =
        selectedType !== null &&
        selectedCollectionID !== null &&
        getRequiredFields(selectedType).every((field) =>
            formData[field]?.trim(),
        );

    const canUpload =
        isFileMode && selectedCollectionID !== null && selectedFile !== null;

    return (
        <Dialog
            open={open}
            onClose={handleClose}
            fullWidth
            maxWidth="sm"
            slotProps={{
                paper: {
                    sx: {
                        maxHeight: "min(720px, 90vh)",
                        borderRadius: "16px",
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
                sx={{
                    px: { xs: 4, sm: 5 },
                    py: { xs: 2.5, sm: 3 },
                }}
            >
                {!isEditMode && !selectedOption && (
                    <Stack sx={{ gap: 2, pt: 1 }}>
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
                    <Stack sx={{ gap: 2.5, pt: 1 }}>
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
                                direction="row"
                                sx={{
                                    alignItems: "center",
                                    gap: 1.5,
                                    p: 2,
                                    borderRadius: "12px",
                                    backgroundColor: (theme) =>
                                        theme.vars.palette.fill.faint,
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
                                        backgroundColor: lockerItemIconConfig(
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
                                <FocusVisibleButton
                                    size="small"
                                    color="secondary"
                                    onClick={() => {
                                        setSelectedFile(null);
                                        if (fileInputRef.current) {
                                            fileInputRef.current.value = "";
                                        }
                                    }}
                                >
                                    {t("change")}
                                </FocusVisibleButton>
                            </Stack>
                        )}

                        {uploading && (
                            <Box sx={{ width: "100%" }}>
                                <Typography
                                    variant="small"
                                    sx={{ color: "text.muted", mb: 0.5 }}
                                >
                                    {t("uploading")}
                                </Typography>
                                <LinearProgress />
                            </Box>
                        )}

                        {!isEditMode && (
                            <CollectionSelector
                                collections={displayCollections}
                                selectedID={selectedCollectionID}
                                onSelect={setSelectedCollectionID}
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
                    <Stack sx={{ gap: 2.5, pt: 1 }}>
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
                            selectedID={selectedCollectionID}
                            onSelect={setSelectedCollectionID}
                            onCreateCollection={onCreateCollection}
                        />

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
    selectedID: number | null;
    onSelect: (id: number) => void;
    onCreateCollection?: (name: string) => Promise<number>;
}> = ({ collections, selectedID, onSelect, onCreateCollection }) => {
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
            onSelect(newCollectionID);
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
    }, [createName, onCreateCollection, onSelect]);

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
                            onClick={() => onSelect(collection.id)}
                            sx={(theme) => ({
                                borderRadius: "999px",
                                px: 1.5,
                                py: 0.875,
                                backgroundColor:
                                    selectedID === collection.id
                                        ? theme.vars.palette.primary.main
                                        : theme.vars.palette.fill.faint,
                                color:
                                    selectedID === collection.id
                                        ? theme.vars.palette.primary
                                              .contrastText
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
                            onClick={() => void handleCreateCollection()}
                        >
                            {t("create")}
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
