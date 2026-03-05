import CheckIcon from "@mui/icons-material/Check";
import CloseIcon from "@mui/icons-material/Close";
import ContentCopyOutlinedIcon from "@mui/icons-material/ContentCopyOutlined";
import { DialogTitle, Paper, Snackbar, Stack, Typography } from "@mui/material";
import { FilledIconButton } from "ente-base/components/mui";
import { t } from "i18next";
import React, { useEffect, useRef, useState } from "react";

interface QuickLinkCreatedNotificationProps {
    open: boolean;
    onClose: () => void;
    onCopy: () => void;
}

export const QuickLinkCreatedNotification: React.FC<
    QuickLinkCreatedNotificationProps
> = ({ open, onClose, onCopy }) => {
    const [copied, setCopied] = useState(false);
    const closeTimerRef = useRef<number | undefined>(undefined);

    useEffect(() => {
        if (open) {
            // Reset only when opening so the check icon does not flicker back
            // to copy during the close animation.
            setCopied(false);
            return;
        }
        if (closeTimerRef.current) {
            window.clearTimeout(closeTimerRef.current);
            closeTimerRef.current = undefined;
        }
    }, [open]);

    useEffect(
        () => () => {
            if (closeTimerRef.current) {
                window.clearTimeout(closeTimerRef.current);
            }
        },
        [],
    );

    const handleCopy = () => {
        onCopy();
        setCopied(true);
        if (closeTimerRef.current) {
            window.clearTimeout(closeTimerRef.current);
        }
        closeTimerRef.current = window.setTimeout(() => {
            onClose();
            closeTimerRef.current = undefined;
        }, 2500);
    };

    return (
        <Snackbar
            open={open}
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
                        <Typography variant="h3">
                            {t("link_created")}
                        </Typography>
                        <Stack direction="row" sx={{ gap: 1 }}>
                            <FilledIconButton
                                aria-label={t("copy_link")}
                                onClick={handleCopy}
                            >
                                {copied ? (
                                    <CheckIcon sx={{ color: "success.main" }} />
                                ) : (
                                    <ContentCopyOutlinedIcon />
                                )}
                            </FilledIconButton>
                            <FilledIconButton
                                aria-label={t("close")}
                                onClick={onClose}
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
