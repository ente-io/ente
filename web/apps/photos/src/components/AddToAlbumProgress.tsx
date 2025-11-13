// TODO: Review AddToAlbumProgress for accessibility and consistent UI patterns.
import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    DialogTitle,
    Divider,
    LinearProgress,
    Paper,
    Snackbar,
    Stack,
    Typography,
} from "@mui/material";
import { SpacedRow } from "ente-base/components/containers";
import { FilledIconButton } from "ente-base/components/mui";
import { t } from "i18next";
import React from "react";

export type AddToAlbumPhase = "processing" | "done" | "failed";

interface AddToAlbumProgressProps {
    open: boolean;
    onClose: () => void;
    phase: AddToAlbumPhase;
}

/**
 * Minimal progress UI for add-to-album operations.
 */
export const AddToAlbumProgress: React.FC<AddToAlbumProgressProps> = ({
    open,
    onClose,
    phase,
}) => {
    return (
        <Snackbar
            open={open}
            anchorOrigin={{ horizontal: "right", vertical: "bottom" }}
        >
            <Paper sx={{ width: "min(360px, 100svw)" }}>
                <AddToAlbumHeader phase={phase} onClose={onClose} />
            </Paper>
        </Snackbar>
    );
};

const AddToAlbumHeader: React.FC<{
    phase: AddToAlbumPhase;
    onClose: () => void;
}> = ({ phase, onClose }) => (
    <>
        <DialogTitle>
            <SpacedRow>
                <Box>
                    <Typography variant="h3">{t("add_to_album")}</Typography>
                    <Typography
                        variant="body"
                        sx={{
                            fontWeight: "regular",
                            color: "text.muted",
                            marginTop: "4px",
                        }}
                    >
                        {subtitleText(phase)}
                    </Typography>
                </Box>
                <Stack direction="row" sx={{ gap: 1 }}>
                    <FilledIconButton onClick={onClose}>
                        <CloseIcon />
                    </FilledIconButton>
                </Stack>
            </SpacedRow>
        </DialogTitle>
        <Box>
            <LinearProgress
                sx={{ height: "2px", backgroundColor: "transparent" }}
                variant={
                    phase === "processing" ? "indeterminate" : "determinate"
                }
                value={phase === "processing" ? undefined : 100}
            />
            <Divider />
        </Box>
    </>
);

const subtitleText = (phase: AddToAlbumPhase) => {
    switch (phase) {
        case "processing":
            return t("preparing");
        case "done":
            return t("added", { count: 1 });
        case "failed":
            return t("error");
    }
};
