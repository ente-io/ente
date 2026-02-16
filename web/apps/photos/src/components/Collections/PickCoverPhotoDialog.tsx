import {
    Box,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    Stack,
    Typography,
} from "@mui/material";
import type { LocalUser } from "ente-accounts/services/user";
import { DialogCloseIconButton } from "ente-base/components/mui/DialogCloseIconButton";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import { isSameDay } from "ente-base/date";
import { formattedDate } from "ente-base/i18n-date";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { fileCreationTime } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { t } from "i18next";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { type SelectedState } from "utils/file";
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

/**
 * Picker dialog for selecting a single file to use as an album cover.
 */
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
    const isFullScreen = useIsSmallWidth();
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [selected, setSelected] = useState<SelectedState>(
        createEmptySelection(collection.id),
    );

    useEffect(() => {
        if (open) {
            setSelected(createEmptySelection(collection.id));
        }
    }, [open, collection.id]);

    const annotatedFiles = useMemo(
        (): FileListAnnotatedFile[] =>
            files
                .filter((file) => file.metadata.fileType !== FileType.video)
                .map((file) => ({
                    file,
                    timelineDateString: fileTimelineDateString(file),
                })),
        [files],
    );

    const selectedFile = useMemo(() => {
        for (const [key, value] of Object.entries(selected)) {
            if (typeof value !== "boolean" || !value) continue;
            const selectedFileID = Number(key);
            return files.find(({ id }) => id === selectedFileID);
        }
        return undefined;
    }, [selected, files]);

    const handleItemClick = useCallback(
        (index: number) => {
            const file = annotatedFiles[index]?.file;
            if (!file) return;
            setSelected(createSingleSelection(file, collection.id));
        },
        [annotatedFiles, collection.id],
    );

    const handleUseSelectedPhoto = useCallback(async () => {
        if (!selectedFile) return;

        setIsSubmitting(true);
        try {
            const didUpdate = await onUseSelectedPhoto(selectedFile);
            if (didUpdate) onClose();
        } finally {
            setIsSubmitting(false);
        }
    }, [onUseSelectedPhoto, onClose, selectedFile]);

    const handleResetToDefault = useCallback(async () => {
        setIsSubmitting(true);
        try {
            const didReset = await onResetToDefault();
            if (didReset) onClose();
        } finally {
            setIsSubmitting(false);
        }
    }, [onResetToDefault, onClose]);

    return (
        <Dialog
            open={open}
            onClose={isSubmitting ? undefined : onClose}
            fullWidth
            fullScreen={isFullScreen}
            slotProps={{
                paper: {
                    sx: !isFullScreen
                        ? {
                              width: "min(980px, calc(100vw - 64px))",
                              height: "min(760px, calc(100vh - 64px))",
                          }
                        : undefined,
                },
            }}
        >
            <Stack sx={{ width: "100%", height: "100%" }}>
                <Stack
                    direction="row"
                    sx={{
                        alignItems: "center",
                        gap: 1,
                        px: 2,
                        pt: 2,
                        pb: 1,
                    }}
                >
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                        <Typography variant="h5">
                            {t("select_cover_photo")}
                        </Typography>
                        <Typography
                            variant="small"
                            sx={{
                                color: "text.muted",
                                fontWeight: "regular",
                            }}
                            noWrap
                        >
                            {collection.name}
                        </Typography>
                    </Box>
                    {!isSubmitting && (
                        <DialogCloseIconButton onClose={onClose} />
                    )}
                </Stack>

                <DialogContent
                    sx={{ px: 2, py: 0, flex: 1, minHeight: 0, display: "flex" }}
                >
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
                                />
                            ) : (
                                <></>
                            )
                        }
                    </AutoSizer>
                </DialogContent>

                <DialogActions
                    sx={{
                        px: 2,
                        pt: 1,
                        pb: 2,
                        gap: 1,
                        justifyContent: "flex-end",
                    }}
                >
                    <Button
                        color={canResetToDefault ? "secondary" : "inherit"}
                        onClick={
                            canResetToDefault ? handleResetToDefault : onClose
                        }
                        disabled={isSubmitting}
                        sx={isFullScreen ? { flex: 1 } : undefined}
                    >
                        {canResetToDefault
                            ? t("reset_to_default")
                            : t("cancel")}
                    </Button>
                    <Button
                        variant="contained"
                        color="primary"
                        onClick={handleUseSelectedPhoto}
                        disabled={isSubmitting || !selectedFile}
                        sx={isFullScreen ? { flex: 1 } : undefined}
                    >
                        {t("use_selected_photo")}
                    </Button>
                </DialogActions>
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
): SelectedState =>
    ({
        [file.id]: true,
        ownCount: 0,
        count: 0,
        collectionID,
        context: { mode: "albums", collectionID },
    }) as SelectedState;

const fileTimelineDateString = (file: EnteFile) => {
    const date = new Date(fileCreationTime(file) / 1000);
    return isSameDay(date, new Date())
        ? t("today")
        : isSameDay(date, new Date(Date.now() - 24 * 60 * 60 * 1000))
          ? t("yesterday")
          : formattedDate(date);
};
