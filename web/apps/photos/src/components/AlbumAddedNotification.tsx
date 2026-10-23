import { Cancel01Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import {
    DialogTitle,
    IconButton,
    Paper,
    Snackbar,
    Stack,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import React from "react";

export type AddToAlbumPhase = "processing" | "done" | "failed";

interface AlbumAddedNotificationProps {
    open: boolean;
    onClose: () => void;
    phase: AddToAlbumPhase;
    albumName?: string;
}

export const AlbumAddedNotification: React.FC<AlbumAddedNotificationProps> = ({
    open,
    onClose,
    phase,
    albumName,
}) => {
    const shouldShow = open && phase === "done";

    return (
        <Snackbar
            open={shouldShow}
            anchorOrigin={{ horizontal: "right", vertical: "bottom" }}
            sx={{
                bottom: { xs: 16, sm: 24 },
                right: { xs: 16, sm: 24 },
                left: { xs: 16, sm: "auto" },
            }}
        >
            <Paper
                sx={(theme) => ({
                    width: "min(340px, calc(100svw - 32px))",
                    borderRadius: "24px",
                    border: "1px solid",
                    borderColor: "rgba(0, 0, 0, 0.06)",
                    backgroundImage: "none",
                    boxShadow: "0 8px 32px rgba(0, 0, 0, 0.24)",
                    ...theme.applyStyles("dark", {
                        borderColor: "rgba(255, 255, 255, 0.06)",
                    }),
                })}
            >
                <DialogTitle sx={{ px: 2.5, py: 2 }}>
                    <Stack
                        direction="row"
                        sx={{
                            alignItems: "center",
                            justifyContent: "space-between",
                            gap: 2,
                        }}
                    >
                        <Stack
                            role="status"
                            sx={{ flex: 1, minWidth: 0, gap: 0.5 }}
                        >
                            <Typography
                                variant="h3"
                                sx={{
                                    fontFamily: '"Outfit Variable", sans-serif',
                                    fontSize: 18,
                                    lineHeight: "24px",
                                }}
                            >
                                {t("added_to_album")}
                            </Typography>
                            {albumName && (
                                <Typography
                                    variant="body"
                                    noWrap
                                    title={albumName}
                                    sx={{
                                        fontFamily:
                                            '"Outfit Variable", sans-serif',
                                        fontWeight: "regular",
                                        fontSize: 14,
                                        lineHeight: "20px",
                                        color: "text.muted",
                                    }}
                                >
                                    {albumName}
                                </Typography>
                            )}
                        </Stack>
                        <IconButton
                            onClick={onClose}
                            aria-label={t("close")}
                            sx={{
                                width: 38,
                                height: 38,
                                flexShrink: 0,
                                borderRadius: "50%",
                                color: "text.muted",
                                bgcolor: "fill.fainter",
                                "&:hover": {
                                    bgcolor: "fill.faintHover",
                                    color: "text.base",
                                },
                                "&.Mui-focusVisible": {
                                    outline: "1px solid",
                                    outlineColor: "stroke.base",
                                    outlineOffset: 2,
                                },
                            }}
                        >
                            <HugeiconsIcon
                                icon={Cancel01Icon}
                                size={22}
                                strokeWidth={1.8}
                            />
                        </IconButton>
                    </Stack>
                </DialogTitle>
            </Paper>
        </Snackbar>
    );
};
