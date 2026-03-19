import CheckRoundedIcon from "@mui/icons-material/CheckRounded";
import ChevronRightRoundedIcon from "@mui/icons-material/ChevronRightRounded";
import CloudUploadOutlinedIcon from "@mui/icons-material/CloudUploadOutlined";
import DeleteOutlineRoundedIcon from "@mui/icons-material/DeleteOutlineRounded";
import ErrorOutlineRoundedIcon from "@mui/icons-material/ErrorOutlineRounded";
import ScheduleRoundedIcon from "@mui/icons-material/ScheduleRounded";
import {
    Box,
    ButtonBase,
    IconButton,
    LinearProgress,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import {
    lockerItemIcon,
    lockerItemIconConfig,
} from "components/lockerItemIcons";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { t } from "i18next";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import type { LockerUploadProgress } from "services/remote";
import type { LockerCollection, LockerUploadCandidate } from "types";

import {
    addCollectionName,
    dedupeCollectionNames,
    formatFileSize,
    normalizeCollectionName,
    toggleCollectionName,
    uploadItemParentPath,
    uploadProgressValue,
    uploadQueueItemKey,
} from "./fileUploadHelpers";

interface FileUploadSectionProps {
    fileInputRef: React.RefObject<HTMLInputElement | null>;
    selectedUploadItems: LockerUploadCandidate[];
    collections: LockerCollection[];
    availableCollectionNames: string[];
    selectedCollectionNamesByFileKey: Record<string, string[]>;
    completedFileKeys: Set<string>;
    failedFileKeys: Set<string>;
    uploadingFileKeys: Set<string>;
    uploadProgressByFileKey: Record<string, LockerUploadProgress | null>;
    uploadCapByFileKey: Record<string, number>;
    finalizingStartedAtByFileKey: Record<string, number>;
    progressTick: number;
    uploading: boolean;
    error: string | null;
    canUpload: boolean;
    onFileSelect: (event: React.ChangeEvent<HTMLInputElement>) => void;
    onToggleCollectionName: (fileKey: string, name: string) => void;
    onAddCollectionName: (fileKey: string, name: string) => void;
    onAddAvailableCollectionName: (name: string) => void;
    onSetCollectionNamesForAllItems: (names: string[]) => void;
    onRemoveItem: (fileKey: string) => void;
    onClose: () => void;
    onUpload: () => Promise<void>;
}

export function FileUploadSection({
    fileInputRef,
    selectedUploadItems,
    collections,
    availableCollectionNames,
    selectedCollectionNamesByFileKey,
    completedFileKeys,
    failedFileKeys,
    uploadingFileKeys,
    uploadProgressByFileKey,
    uploadCapByFileKey,
    finalizingStartedAtByFileKey,
    progressTick,
    uploading,
    error,
    canUpload,
    onFileSelect,
    onToggleCollectionName,
    onAddCollectionName,
    onAddAvailableCollectionName,
    onSetCollectionNamesForAllItems,
    onRemoveItem,
    onClose,
    onUpload,
}: FileUploadSectionProps) {
    const shouldShowPerItemCollectionSelector = useMemo(() => {
        const uniqueParentPaths = new Set(
            selectedUploadItems.map(uploadItemParentPath),
        );
        return uniqueParentPaths.size > 1;
    }, [selectedUploadItems]);
    const sharedSelectedCollectionNames =
        selectedUploadItems.length > 0
            ? (selectedCollectionNamesByFileKey[
                  uploadQueueItemKey(selectedUploadItems[0]!)
              ] ?? [])
            : [];
    const sharedSuggestedCollectionNames = useMemo(
        () =>
            dedupeCollectionNames(
                selectedUploadItems.flatMap(
                    (item) => item.suggestedCollectionNames,
                ),
            ),
        [selectedUploadItems],
    );

    return (
        <Stack sx={{ gap: 2.5, pt: 0.5 }}>
            <input
                ref={fileInputRef}
                type="file"
                multiple
                hidden
                onChange={onFileSelect}
            />

            {selectedUploadItems.length === 0 ? (
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
                        backgroundColor: theme.vars.palette.fill.faint,
                        transition: "background-color 0.15s",
                        "&:hover": {
                            backgroundColor: theme.vars.palette.fill.faintHover,
                        },
                    })}
                >
                    <CloudUploadOutlinedIcon
                        sx={{ fontSize: 40, color: "text.faint" }}
                    />
                    <Typography variant="body" sx={{ color: "text.muted" }}>
                        {t("clickHereToUpload")}
                    </Typography>
                </ButtonBase>
            ) : (
                <Stack sx={{ gap: 1.25 }}>
                    {selectedUploadItems.map((item) => {
                        const fileKey = uploadQueueItemKey(item);
                        return (
                            <UploadItemCard
                                key={fileKey}
                                item={item}
                                collections={collections}
                                availableCollectionNames={
                                    availableCollectionNames
                                }
                                selectedCollectionNames={
                                    selectedCollectionNamesByFileKey[fileKey] ??
                                    []
                                }
                                suggestedCollectionNames={
                                    item.suggestedCollectionNames
                                }
                                showCollectionSelector={
                                    shouldShowPerItemCollectionSelector
                                }
                                isDone={completedFileKeys.has(fileKey)}
                                isFailed={failedFileKeys.has(fileKey)}
                                isUploading={uploadingFileKeys.has(fileKey)}
                                isQueued={
                                    !completedFileKeys.has(fileKey) &&
                                    !failedFileKeys.has(fileKey) &&
                                    !uploadingFileKeys.has(fileKey) &&
                                    uploading
                                }
                                uploadProgress={
                                    uploadProgressByFileKey[fileKey]
                                }
                                uploadCap={uploadCapByFileKey[fileKey] ?? 95}
                                finalizingStartedAt={
                                    finalizingStartedAtByFileKey[fileKey]
                                }
                                progressTick={progressTick}
                                uploadInFlight={uploading}
                                onToggleCollectionName={(name) =>
                                    onToggleCollectionName(fileKey, name)
                                }
                                onAddCollectionName={(name) =>
                                    onAddCollectionName(fileKey, name)
                                }
                                canRemove={!uploading}
                                onRemove={() => onRemoveItem(fileKey)}
                            />
                        );
                    })}
                </Stack>
            )}

            {!shouldShowPerItemCollectionSelector &&
                selectedUploadItems.length > 0 && (
                    <CollectionNameSelector
                        collections={collections}
                        availableNames={availableCollectionNames}
                        selectedNames={sharedSelectedCollectionNames}
                        suggestedNames={sharedSuggestedCollectionNames}
                        onToggleName={(name) =>
                            onSetCollectionNamesForAllItems(
                                toggleCollectionName(
                                    sharedSelectedCollectionNames,
                                    name,
                                ),
                            )
                        }
                        onAddCollectionName={(name) => {
                            onAddAvailableCollectionName(name);
                            onSetCollectionNamesForAllItems(
                                addCollectionName(
                                    sharedSelectedCollectionNames,
                                    name,
                                ),
                            );
                        }}
                        disabled={uploading}
                    />
                )}

            {error && (
                <Typography variant="small" sx={{ color: "critical.main" }}>
                    {error}
                </Typography>
            )}

            <Stack direction="row" sx={{ gap: 1, pt: 1 }}>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    onClick={onClose}
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
                    onClick={() => void onUpload()}
                >
                    {t("upload")}
                </LoadingButton>
            </Stack>
        </Stack>
    );
}

const UploadItemCard: React.FC<{
    item: LockerUploadCandidate;
    collections: LockerCollection[];
    availableCollectionNames: string[];
    selectedCollectionNames: string[];
    suggestedCollectionNames: string[];
    showCollectionSelector: boolean;
    isDone: boolean;
    isFailed: boolean;
    isUploading: boolean;
    isQueued: boolean;
    uploadProgress: LockerUploadProgress | null | undefined;
    uploadCap: number;
    finalizingStartedAt?: number;
    progressTick: number;
    uploadInFlight: boolean;
    onToggleCollectionName: (name: string) => void;
    onAddCollectionName: (name: string) => void;
    canRemove: boolean;
    onRemove: () => void;
}> = ({
    item,
    collections,
    availableCollectionNames,
    selectedCollectionNames,
    suggestedCollectionNames,
    showCollectionSelector,
    isDone,
    isFailed,
    isUploading,
    isQueued,
    uploadProgress,
    uploadCap,
    finalizingStartedAt,
    progressTick,
    uploadInFlight,
    onToggleCollectionName,
    onAddCollectionName,
    canRemove,
    onRemove,
}) => (
    <Stack
        sx={{
            borderRadius: "12px",
            backgroundColor: (theme) => theme.vars.palette.fill.faint,
            overflow: "hidden",
        }}
    >
        <Stack
            direction="row"
            sx={{ alignItems: "center", gap: 1.5, p: 2, position: "relative" }}
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
                        item.file.name,
                    ).backgroundColor,
                    flexShrink: 0,
                }}
            >
                {lockerItemIcon("file", {
                    fileName: item.file.name,
                    size: 24,
                    strokeWidth: 1.9,
                })}
            </Box>
            <Box sx={{ flex: 1, minWidth: 0, pr: canRemove ? 5 : 0 }}>
                <Typography variant="body" noWrap>
                    {item.file.name}
                </Typography>
                <Typography variant="small" sx={{ color: "text.faint" }}>
                    {formatFileSize(item.file.size)}
                </Typography>
            </Box>
            {isDone && (
                <Box
                    sx={(theme) => ({
                        width: 24,
                        height: 24,
                        borderRadius: "50%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        backgroundColor: theme.vars.palette.primary.main,
                        color: theme.vars.palette.primary.contrastText,
                        flexShrink: 0,
                    })}
                >
                    <CheckRoundedIcon sx={{ fontSize: 16 }} />
                </Box>
            )}
            {isFailed && (
                <ErrorOutlineRoundedIcon
                    sx={{ color: "critical.main", fontSize: 20, flexShrink: 0 }}
                />
            )}
            {isQueued && (
                <ScheduleRoundedIcon
                    sx={{ color: "text.muted", fontSize: 20, flexShrink: 0 }}
                />
            )}
            {canRemove && (
                <IconButton
                    aria-label={t("delete")}
                    onClick={onRemove}
                    size="small"
                    sx={(theme) => ({
                        position: "absolute",
                        top: 12,
                        right: 12,
                        width: 30,
                        height: 30,
                        borderRadius: "10px",
                        backgroundColor: "transparent",
                        color: theme.vars.palette.text.muted,
                        flexShrink: 0,
                        "&:hover": {
                            backgroundColor: theme.vars.palette.fill.faintHover,
                            color: theme.vars.palette.text.base,
                        },
                    })}
                >
                    <DeleteOutlineRoundedIcon sx={{ fontSize: 16 }} />
                </IconButton>
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
                    opacity: isUploading || isDone ? 1 : 0,
                }}
            />
        </Box>
        {showCollectionSelector && (
            <Box sx={{ px: 2, pt: 1.5, pb: 2 }}>
                <CollectionNameSelector
                    collections={collections}
                    availableNames={availableCollectionNames}
                    selectedNames={selectedCollectionNames}
                    suggestedNames={suggestedCollectionNames}
                    onToggleName={onToggleCollectionName}
                    onAddCollectionName={onAddCollectionName}
                    disabled={uploadInFlight}
                />
            </Box>
        )}
    </Stack>
);

const CollectionNameSelector: React.FC<{
    collections: LockerCollection[];
    availableNames: string[];
    selectedNames: string[];
    suggestedNames: string[];
    onToggleName: (name: string) => void;
    onAddCollectionName: (name: string) => void;
    disabled?: boolean;
}> = ({
    collections,
    availableNames,
    selectedNames,
    suggestedNames,
    onToggleName,
    onAddCollectionName,
    disabled,
}) => {
    const [createOpen, setCreateOpen] = useState(false);
    const [createName, setCreateName] = useState("");
    const scrollContainerRef = useRef<HTMLDivElement | null>(null);
    const [showScrollHint, setShowScrollHint] = useState(false);
    const selectedNameMap = useMemo(
        () =>
            new Map(
                selectedNames.map((name) => [
                    normalizeCollectionName(name),
                    name,
                ]),
            ),
        [selectedNames],
    );
    const displayNames = useMemo(() => {
        const sortedSuggestedNames = [
            ...dedupeCollectionNames(suggestedNames),
        ].sort((a, b) =>
            a.localeCompare(b, undefined, { sensitivity: "base" }),
        );
        const sortedRemainingNames = dedupeCollectionNames([
            ...collections.map((collection) => collection.name),
            ...availableNames,
            ...selectedNames,
        ])
            .filter(
                (name) =>
                    !sortedSuggestedNames.some(
                        (suggestedName) =>
                            normalizeCollectionName(suggestedName) ===
                            normalizeCollectionName(name),
                    ),
            )
            .sort((a, b) =>
                a.localeCompare(b, undefined, { sensitivity: "base" }),
            );
        return [...sortedSuggestedNames, ...sortedRemainingNames];
    }, [availableNames, collections, selectedNames, suggestedNames]);

    useEffect(() => {
        const container = scrollContainerRef.current;
        if (!container) {
            return;
        }

        const updateScrollHint = () => {
            const remainingScroll =
                container.scrollWidth -
                container.clientWidth -
                container.scrollLeft;
            setShowScrollHint(remainingScroll > 8);
        };

        updateScrollHint();
        container.addEventListener("scroll", updateScrollHint, {
            passive: true,
        });
        window.addEventListener("resize", updateScrollHint);

        return () => {
            container.removeEventListener("scroll", updateScrollHint);
            window.removeEventListener("resize", updateScrollHint);
        };
    }, [displayNames.length, createOpen]);

    const handleAddCollectionName = useCallback(() => {
        const trimmedName = createName.trim();
        if (!trimmedName) {
            return;
        }

        onAddCollectionName(trimmedName);
        setCreateName("");
        setCreateOpen(false);
    }, [createName, onAddCollectionName]);

    return (
        <Box>
            <Stack
                direction="row"
                sx={{
                    alignItems: "center",
                    justifyContent: "space-between",
                    gap: 1,
                    mb: 1.25,
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
            <Box sx={{ position: "relative" }}>
                <Stack
                    ref={scrollContainerRef}
                    direction="row"
                    sx={{
                        gap: 1,
                        flexWrap: "nowrap",
                        overflowX: "auto",
                        overflowY: "hidden",
                        pr: 6,
                        pb: 0.5,
                        scrollbarWidth: "none",
                        "&::-webkit-scrollbar": { display: "none" },
                    }}
                >
                    <ButtonBase
                        onClick={() => setCreateOpen((open) => !open)}
                        disabled={disabled}
                        sx={(theme) => ({
                            borderRadius: "999px",
                            px: 1.5,
                            py: 0.875,
                            whiteSpace: "nowrap",
                            flexShrink: 0,
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
                    {displayNames.map((name) => {
                        const isSelected = selectedNameMap.has(
                            normalizeCollectionName(name),
                        );
                        return (
                            <ButtonBase
                                key={name}
                                onClick={() => onToggleName(name)}
                                disabled={disabled}
                                sx={(theme) => ({
                                    borderRadius: "999px",
                                    px: 1.5,
                                    py: 0.875,
                                    whiteSpace: "nowrap",
                                    flexShrink: 0,
                                    backgroundColor: isSelected
                                        ? "#1071FF"
                                        : theme.vars.palette.fill.faint,
                                    color: isSelected
                                        ? "#FFFFFF"
                                        : theme.vars.palette.text.base,
                                })}
                            >
                                <Typography variant="small">{name}</Typography>
                            </ButtonBase>
                        );
                    })}
                </Stack>
                {showScrollHint && (
                    <Box
                        sx={(theme) => ({
                            position: "absolute",
                            top: 0,
                            right: 0,
                            bottom: 0,
                            width: 72,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "flex-end",
                            pr: 0.5,
                            pointerEvents: "none",
                            background: `linear-gradient(90deg, ${theme.vars.palette.background.default}00 0%, ${theme.vars.palette.background.default}E6 52%, ${theme.vars.palette.background.default} 74%)`,
                        })}
                    >
                        <Box
                            sx={(theme) => ({
                                width: 22,
                                height: 22,
                                borderRadius: "999px",
                                backgroundColor:
                                    theme.vars.palette.background.default,
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                            })}
                        >
                            <ChevronRightRoundedIcon
                                sx={{ color: "text.faint", fontSize: 20 }}
                            />
                        </Box>
                    </Box>
                )}
            </Box>

            {createOpen && (
                <Stack sx={{ gap: 1, mt: 1.25 }}>
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
                                    height: 44,
                                    borderRadius: "14px",
                                },
                                "& .MuiInputBase-input": { pt: 1, pb: 0.5 },
                            }}
                            value={createName}
                            onChange={(event) =>
                                setCreateName(event.target.value)
                            }
                            onKeyDown={(event) => {
                                if (event.key === "Escape") {
                                    event.preventDefault();
                                    event.stopPropagation();
                                    setCreateOpen(false);
                                    return;
                                }
                                if (event.key === "Enter") {
                                    event.preventDefault();
                                    handleAddCollectionName();
                                }
                            }}
                            disabled={disabled}
                        />
                        <LoadingButton
                            color="accent"
                            disabled={!createName.trim() || disabled}
                            aria-label={t("create")}
                            onClick={handleAddCollectionName}
                            sx={{
                                minWidth: 0,
                                width: 44,
                                height: 44,
                                p: 0,
                                borderRadius: "14px",
                                flexShrink: 0,
                            }}
                        >
                            <CheckRoundedIcon />
                        </LoadingButton>
                    </Stack>
                </Stack>
            )}
        </Box>
    );
};
