import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    DialogTitle,
    Paper,
    Snackbar,
    Stack,
    Typography,
} from "@mui/material";
import { FilledIconButton } from "ente-base/components/mui";
import { t } from "i18next";
import React from "react";

export type AddToAlbumPhase = "processing" | "done" | "failed";

interface AlbumAddedNotificationProps {
    open: boolean;
    onClose: () => void;
    phase: AddToAlbumPhase;
    /** The file name to show as subtitle (truncated). */
    fileName?: string;
    /** Called when the arrow CTA is clicked to navigate to the album. */
    onArrowClick?: () => void;
}

/**
 * Success notification shown after files are added to an album.
 * Provides navigation to the album via an arrow button.
 */
export const AlbumAddedNotification: React.FC<AlbumAddedNotificationProps> = ({
    open,
    onClose,
    phase,
    fileName,
    onArrowClick,
}) => {
    // Only show the toast once the operation completes successfully.
    const shouldShow = open && phase === "done";

    return (
        <Snackbar
            open={shouldShow}
            anchorOrigin={{ horizontal: "right", vertical: "bottom" }}
        >
            <Paper sx={{ width: "min(360px, 100svw)" }}>
                <DialogTitle>
                    <Stack
                        direction="row"
                        sx={{
                            justifyContent: "space-between",
                            alignItems: "center",
                        }}
                    >
                        <Box>
                            <Typography variant="h3">
                                {/* Intentionally using a simple title for clarity */}
                                {t("add_to_album")}
                            </Typography>
                            {fileName && (
                                <Typography
                                    variant="body"
                                    sx={{
                                        fontWeight: "regular",
                                        color: "text.muted",
                                        marginTop: "4px",
                                    }}
                                >
                                    {truncate(fileName, 15)}
                                </Typography>
                            )}
                        </Box>
                        <Stack direction="row" sx={{ gap: 1 }}>
                            {onArrowClick && (
                                <FilledIconButton
                                    onClick={() => {
                                        onArrowClick();
                                        onClose();
                                    }}
                                >
                                    <ArrowForwardIcon />
                                </FilledIconButton>
                            )}
                            <FilledIconButton
                                onClick={onClose}
                                aria-label={t("close")}
                            >
                                <CloseIcon />
                            </FilledIconButton>
                        </Stack>
                    </Stack>
                </DialogTitle>
            </Paper>
        </Snackbar>
    );
};

const truncate = (s: string, max: number) =>
    s.length > max ? `${s.substring(0, max)}...` : s;
