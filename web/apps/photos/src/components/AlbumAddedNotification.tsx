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
    /** The destination album name to show as subtitle (truncated). */
    albumName?: string;
}

/**
 * Success notification shown after files are added to an album.
 */
export const AlbumAddedNotification: React.FC<AlbumAddedNotificationProps> = ({
    open,
    onClose,
    phase,
    albumName,
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
                                {t("added_to_album")}
                            </Typography>
                            {albumName && (
                                <Typography
                                    variant="body"
                                    sx={{
                                        fontWeight: "regular",
                                        color: "text.muted",
                                        marginTop: "4px",
                                    }}
                                >
                                    {truncate(albumName, 20)}
                                </Typography>
                            )}
                        </Box>
                        <Stack direction="row" sx={{ gap: 1 }}>
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
