import CheckRoundedIcon from "@mui/icons-material/CheckRounded";
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
import { CollectionChipRow } from "components/createItemDialog/CollectionChipRow";
import {
    lockerItemIcon,
    lockerItemIconConfig,
} from "components/lockerItemIcons";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { t } from "i18next";
import React, { useCallback, useMemo, useState } from "react";
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
                    <Typography variant="body" sx={{ fontWeight: 600 }}>
                        {t("saveDocumentsTitle")}
                    </Typography>
                    <Typography variant="small" sx={{ color: "text.muted" }}>
                        {t("dropToSaveToLocker")}
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
                    {t("saveRecord")}
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
            display: "flex",
            flexDirection: "column",
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
                    sx={() => ({
                        width: 24,
                        height: 24,
                        borderRadius: "50%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        backgroundColor: "#1071FF",
                        color: "#FFFFFF",
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
        {showCollectionSelector && (
            <Box sx={{ px: 2, pt: 1.5, pb: 2, flexShrink: 0 }}>
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
        <Box sx={{ mt: "auto", height: 4, flexShrink: 0 }}>
            <LinearProgress
                variant={isQueued ? "indeterminate" : "determinate"}
                value={
                    isQueued
                        ? undefined
                        : isUploading
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
                    opacity: isQueued || isUploading || isDone ? 1 : 0,
                }}
            />
        </Box>
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
        const allNames = dedupeCollectionNames([
            ...collections.map((collection) => collection.name),
            ...availableNames,
            ...selectedNames,
        ]);
        const suggestedNameSet = new Set(
            suggestedNames.map((name) => normalizeCollectionName(name)),
        );
        const sortedSuggestedNames = allNames
            .filter((name) => {
                const normalizedName = normalizeCollectionName(name);
                return suggestedNameSet.has(normalizedName);
            })
            .sort((a, b) =>
                a.localeCompare(b, undefined, { sensitivity: "base" }),
            );
        const sortedRemainingNames = allNames
            .filter((name) => {
                const normalizedName = normalizeCollectionName(name);
                return !suggestedNameSet.has(normalizedName);
            })
            .sort((a, b) =>
                a.localeCompare(b, undefined, { sensitivity: "base" }),
            );
        return [...sortedSuggestedNames, ...sortedRemainingNames];
    }, [availableNames, collections, selectedNames, suggestedNames]);

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
            <CollectionChipRow
                items={displayNames.map((name) => ({
                    key: name,
                    label: name,
                    selected: selectedNameMap.has(
                        normalizeCollectionName(name),
                    ),
                    onClick: () => onToggleName(name),
                }))}
                createOpen={createOpen}
                disabled={disabled}
                onCreateClick={() => setCreateOpen((open) => !open)}
            />
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
