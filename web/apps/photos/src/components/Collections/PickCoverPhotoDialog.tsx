import { fileTimelineDateString, type SelectedState } from "@/utils/file";
import { ArrowLeft02Icon, Cancel01Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import {
    Box,
    Dialog,
    IconButton,
    Stack,
    Typography,
    type Theme,
} from "@mui/material";
import type { LocalUser } from "ente-accounts/services/user";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import {
    v2CancelButtonSx,
    v2CloseButtonSx,
    v2PaperSx,
    v2SubmitButtonSx,
    v2TitleSx,
} from "ente-base/components/SingleInput.styles";
import { isSxArray } from "ente-base/components/utils/sx";
import {
    uploadSheetMediaQuery,
    uploadSheetPaperSx,
    useIsUploadSheet,
} from "ente-gallery/components/upload-progress/bottom-sheet";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { FileType } from "ente-media/file-type";
import { SlideUpTransition } from "ente-new/photos/components/mui/SlideUpTransition";
import { t } from "i18next";
import React, { useCallback, useEffect, useId, useMemo, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { FileList, type FileListAnnotatedFile } from "../FileList";

interface PickCoverPhotoDialogProps {
    open: boolean;
    onClose: () => void;
    collection: Collection;
    files: EnteFile[];
    user: LocalUser;
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
    user,
    canResetToDefault,
    onUseSelectedPhoto,
    onResetToDefault,
}) => {
    const isSheet = useIsUploadSheet();
    const titleID = useId();
    const [submittingAction, setSubmittingAction] = useState<
        SubmittingAction | undefined
    >();
    const [selected, setSelected] = useState<SelectedState>(
        createEmptySelection(collection.id),
    );
    const isSubmitting = Boolean(submittingAction);

    useEffect(() => {
        if (open) {
            setSelected(createEmptySelection(collection.id));
            setSubmittingAction(undefined);
        }
    }, [open, collection.id]);

    const annotatedFiles = useMemo((): FileListAnnotatedFile[] => {
        if (!open) return [];

        return files
            .filter((file) => file.metadata.fileType !== FileType.video)
            .map((file) => ({
                file,
                timelineDateString: fileTimelineDateString(file),
            }));
    }, [open, files]);

    const selectedFile = useMemo(() => {
        if (!open) return undefined;

        for (const [key, value] of Object.entries(selected)) {
            if (typeof value !== "boolean" || !value) continue;
            const selectedFileID = Number(key);
            return files.find(({ id }) => id === selectedFileID);
        }
        return undefined;
    }, [open, selected, files]);

    const handleItemClick = useCallback(
        (index: number) => {
            const file = annotatedFiles[index]?.file;
            if (!file) return;
            setSelected(createSingleSelection(file, collection.id, user.id));
        },
        [annotatedFiles, collection.id, user.id],
    );

    const handleUseSelectedPhoto = useCallback(async () => {
        if (!selectedFile) return;

        setSubmittingAction("use-selected-photo");
        try {
            const didUpdate = await onUseSelectedPhoto(selectedFile);
            if (didUpdate) onClose();
        } finally {
            setSubmittingAction(undefined);
        }
    }, [onUseSelectedPhoto, onClose, selectedFile]);

    const handleResetToDefault = useCallback(async () => {
        setSubmittingAction("reset-to-default");
        try {
            const didReset = await onResetToDefault();
            if (didReset) onClose();
        } finally {
            setSubmittingAction(undefined);
        }
    }, [onResetToDefault, onClose]);

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
                        {annotatedFiles.length ? (
                            <AutoSizer>
                                {({ width, height }) =>
                                    width > 0 && height > 0 ? (
                                        <FileList
                                            {...{
                                                width,
                                                height,
                                                user,
                                                annotatedFiles,
                                                selected,
                                                setSelected,
                                            }}
                                            mode="albums"
                                            enableSelect={false}
                                            activeCollectionID={collection.id}
                                            onItemClick={handleItemClick}
                                            disableGrouping
                                        />
                                    ) : (
                                        <></>
                                    )
                                }
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
                            disabled={
                                !selectedFile ||
                                (isSubmitting &&
                                    submittingAction !== "use-selected-photo")
                            }
                            autoFocus={Boolean(selectedFile)}
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
                                disabled={
                                    isSubmitting &&
                                    submittingAction !== "reset-to-default"
                                }
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

const createEmptySelection = (collectionID: number): SelectedState => ({
    ownCount: 0,
    count: 0,
    collectionID,
    context: { mode: "albums", collectionID },
});

const createSingleSelection = (
    file: EnteFile,
    collectionID: number,
    userID: number,
): SelectedState => ({
    [file.id]: true,
    ownCount: file.ownerID === userID ? 1 : 0,
    count: 1,
    collectionID,
    context: { mode: "albums", collectionID },
});

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
