import {
    ArrowLeft02Icon,
    Cancel01Icon,
    Tick02Icon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import {
    Box,
    Dialog,
    IconButton,
    Stack,
    Typography,
    styled,
    type Theme,
} from "@mui/material";
import {
    v2CancelButtonSx,
    v2CloseButtonSx,
    v2PaperSx,
    v2SubmitButtonSx,
    v2TitleSx,
} from "ente-base/components/SingleInput.styles";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { isSxArray } from "ente-base/components/utils/sx";
import {
    uploadSheetMediaQuery,
    uploadSheetPaperSx,
    useIsUploadSheet,
} from "ente-gallery/components/upload-progress/bottom-sheet";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { FileType } from "ente-media/file-type";
import { ItemCard } from "ente-new/photos/components/Tiles";
import { FocusVisibleUnstyledButton } from "ente-new/photos/components/UnstyledButton";
import { SlideUpTransition } from "ente-new/photos/components/mui/SlideUpTransition";
import { t } from "i18next";
import React, { useCallback, useEffect, useId, useMemo, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { FixedSizeList, type ListChildComponentProps } from "react-window";

interface PickCoverPhotoDialogProps {
    open: boolean;
    onClose: () => void;
    collection: Collection;
    files: EnteFile[];
    currentCoverID: number | undefined;
    canResetToDefault: boolean;
    onUseSelectedPhoto: (file: EnteFile) => Promise<boolean>;
    onResetToDefault: () => Promise<boolean>;
}

type SubmittingAction = "use-selected-photo" | "reset-to-default";

export const PickCoverPhotoDialog: React.FC<PickCoverPhotoDialogProps> = ({
    open,
    onClose,
    collection,
    files,
    currentCoverID,
    canResetToDefault,
    onUseSelectedPhoto,
    onResetToDefault,
}) => {
    const isSheet = useIsUploadSheet();
    const titleID = useId();
    const [submittingAction, setSubmittingAction] =
        useState<SubmittingAction>();
    const [selectedID, setSelectedID] = useState<number>();
    const isSubmitting = Boolean(submittingAction);
    const coverFiles = useMemo(
        () =>
            open
                ? files.filter(
                      (file) => file.metadata.fileType !== FileType.video,
                  )
                : [],
        [open, files],
    );
    const selectedFile = coverFiles.find(({ id }) => id === selectedID);

    useEffect(() => {
        if (open) {
            setSelectedID(currentCoverID);
            setSubmittingAction(undefined);
        }
    }, [open, collection.id, currentCoverID]);

    const handleUseSelectedPhoto = useCallback(async () => {
        if (!selectedFile || isSubmitting) return;
        setSubmittingAction("use-selected-photo");
        try {
            if (await onUseSelectedPhoto(selectedFile)) onClose();
        } finally {
            setSubmittingAction(undefined);
        }
    }, [onUseSelectedPhoto, onClose, selectedFile, isSubmitting]);

    const handleResetToDefault = useCallback(async () => {
        if (isSubmitting) return;
        setSubmittingAction("reset-to-default");
        try {
            if (await onResetToDefault()) onClose();
        } finally {
            setSubmittingAction(undefined);
        }
    }, [onResetToDefault, onClose, isSubmitting]);

    return (
        <Dialog
            open={open}
            onClose={isSubmitting ? undefined : onClose}
            aria-labelledby={titleID}
            maxWidth={false}
            slots={isSheet ? { transition: SlideUpTransition } : undefined}
            slotProps={{
                paper: {
                    sx: [
                        ...(isSxArray(v2PaperSx) ? v2PaperSx : [v2PaperSx]),
                        paperSx,
                        uploadSheetPaperSx,
                    ],
                },
            }}
        >
            <Stack sx={contentSx} aria-busy={isSubmitting}>
                <Stack
                    direction="row"
                    sx={{ alignItems: "center", gap: "8px" }}
                >
                    <IconButton
                        aria-label={t("go_back")}
                        onClick={onClose}
                        disabled={isSubmitting}
                        sx={backButtonSx}
                    >
                        <HugeiconsIcon icon={ArrowLeft02Icon} size={24} />
                    </IconButton>
                    <Typography id={titleID} sx={[v2TitleSx, titleSx]}>
                        {t("choose_cover")}
                    </Typography>
                    <IconButton
                        aria-label={t("close")}
                        onClick={onClose}
                        disabled={isSubmitting}
                        sx={v2CloseButtonSx}
                    >
                        <HugeiconsIcon icon={Cancel01Icon} size={18} />
                    </IconButton>
                </Stack>
                <Stack sx={{ flex: 1, minHeight: 0, gap: "24px" }}>
                    <Box sx={{ flex: 1, minHeight: 0 }}>
                        {coverFiles.length ? (
                            <AutoSizer>
                                {({ width, height }) => {
                                    if (width <= 0 || height <= 0) return <></>;
                                    const columns = width < 400 ? 3 : 4;
                                    const itemSize =
                                        (width - (columns - 1) * 10) / columns;
                                    return (
                                        <FixedSizeList<CoverRowData>
                                            key={collection.id}
                                            width={width}
                                            height={height}
                                            itemCount={Math.ceil(
                                                coverFiles.length / columns,
                                            )}
                                            itemSize={itemSize + 10}
                                            itemData={{
                                                files: coverFiles,
                                                columns,
                                                itemSize,
                                                selectedID,
                                                setSelectedID,
                                                disabled: isSubmitting,
                                            }}
                                            overscanCount={2}
                                            useIsScrolling
                                        >
                                            {CoverRow}
                                        </FixedSizeList>
                                    );
                                }}
                            </AutoSizer>
                        ) : (
                            <Typography sx={{ color: "text.muted" }}>
                                {t("no_photos_found_here")}
                            </Typography>
                        )}
                    </Box>
                    <Stack sx={{ gap: "12px", flexShrink: 0 }}>
                        <LoadingButton
                            fullWidth
                            color="accent"
                            onClick={handleUseSelectedPhoto}
                            loading={submittingAction === "use-selected-photo"}
                            disabled={!selectedFile || isSubmitting}
                            sx={[
                                v2SubmitButtonSx,
                                actionButtonSx,
                                ...(submittingAction === "use-selected-photo"
                                    ? []
                                    : [primaryButtonDisabledSx]),
                            ]}
                        >
                            {t("set_as_cover")}
                        </LoadingButton>
                        {canResetToDefault && (
                            <LoadingButton
                                fullWidth
                                color="secondary"
                                onClick={handleResetToDefault}
                                loading={
                                    submittingAction === "reset-to-default"
                                }
                                disabled={isSubmitting}
                                sx={[
                                    v2CancelButtonSx,
                                    actionButtonSx,
                                    secondaryButtonSx,
                                ]}
                            >
                                {t("reset_to_default")}
                            </LoadingButton>
                        )}
                    </Stack>
                </Stack>
            </Stack>
        </Dialog>
    );
};

interface CoverRowData {
    files: EnteFile[];
    columns: number;
    itemSize: number;
    selectedID: number | undefined;
    setSelectedID: (id: number) => void;
    disabled: boolean;
}

const CoverRow = ({
    index,
    style,
    data,
    isScrolling,
}: ListChildComponentProps<CoverRowData>) => (
    <Box style={style} sx={{ display: "flex", gap: "10px" }}>
        {data.files
            .slice(index * data.columns, (index + 1) * data.columns)
            .map((file) => {
                const isSelected = file.id === data.selectedID;
                return (
                    <FocusVisibleUnstyledButton
                        key={file.id}
                        type="button"
                        aria-label={file.metadata.title}
                        aria-pressed={isSelected}
                        disabled={data.disabled}
                        onClick={() => data.setSelectedID(file.id)}
                        sx={{
                            position: "relative",
                            width: data.itemSize,
                            height: data.itemSize,
                            borderRadius: "12px",
                            overflow: "hidden",
                            flexShrink: 0,
                            "&:focus-visible, &:active": {
                                borderRadius: "12px",
                            },
                            "&:disabled": { cursor: "default" },
                        }}
                    >
                        <ItemCard
                            TileComponent={CoverTile}
                            coverFile={file}
                            isScrolling={isScrolling}
                        />
                        {isSelected && (
                            <Box sx={selectionSx}>
                                <Box sx={checkSx}>
                                    <HugeiconsIcon
                                        icon={Tick02Icon}
                                        size={13}
                                    />
                                </Box>
                            </Box>
                        )}
                    </FocusVisibleUnstyledButton>
                );
            })}
    </Box>
);

const CoverTile = styled("div")({
    display: "flex",
    width: "100%",
    height: "100%",
    overflow: "hidden",
    "& > img": {
        width: "100%",
        height: "100%",
        objectFit: "cover",
        pointerEvents: "none",
    },
});

const green = v2SubmitButtonSx.backgroundColor;
const paperSx = {
    width: "min(714px, calc(100svw - 32px))",
    maxWidth: "714px",
    height: "656px",
    maxHeight: "calc(100dvh - 32px)",
    boxSizing: "border-box",
};
const contentSx = {
    p: "20px",
    gap: "36px",
    height: "100%",
    minHeight: 0,
    [uploadSheetMediaQuery]: {
        p: "12px 16px",
        pb: "calc(20px + env(safe-area-inset-bottom, 0px))",
    },
};
const titleSx = {
    flex: 1,
    minWidth: 0,
    fontFamily: "'Outfit Variable', sans-serif",
    overflowWrap: "anywhere",
};
const backButtonSx = {
    width: 38,
    height: 38,
    p: 0,
    flexShrink: 0,
    color: "text.base",
};
const selectionSx = {
    position: "absolute",
    inset: 0,
    border: `3px solid ${green}`,
    borderRadius: "12px",
    pointerEvents: "none",
};
const checkSx = {
    position: "absolute",
    top: 9,
    right: 9,
    width: 26,
    height: 26,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    borderRadius: "50%",
    border: "2px solid #fff",
    backgroundColor: green,
    color: "#fff",
};
// Shared actions normally share a row; keep these stacked at their full height.
const actionButtonSx = {
    flex: "none",
    minHeight: 52,
    px: "24px",
    py: "14px",
    textTransform: "none",
    boxShadow: "none",
    "&:hover": { boxShadow: "none" },
};
const primaryButtonDisabledSx = (theme: Theme) => ({
    "&.Mui-disabled": {
        opacity: 1,
        color: "#d6d6d6",
        backgroundColor: "#eaeaea",
        ...theme.applyStyles("dark", {
            color: "rgba(255 255 255 / 0.3)",
            backgroundColor: "rgba(255 255 255 / 0.12)",
        }),
    },
});
const secondaryButtonSx = (theme: Theme) => ({
    "&:hover": { backgroundColor: "#e0e0e0" },
    "&.Mui-disabled": { opacity: 1 },
    ...theme.applyStyles("dark", {
        backgroundColor: "#282828",
        "&:hover": { backgroundColor: "#333" },
    }),
});
