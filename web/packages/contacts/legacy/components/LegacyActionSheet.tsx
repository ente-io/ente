import CloseIcon from "@mui/icons-material/Close";
import {
    Dialog,
    IconButton,
    Stack,
    Typography,
    type DialogProps,
} from "@mui/material";
import React from "react";

interface LegacyActionSheetProps {
    open: boolean;
    title: string;
    subtitle?: React.ReactNode;
    onClose: () => void;
    children: React.ReactNode;
}

export const LegacyActionSheet: React.FC<LegacyActionSheetProps> = ({
    open,
    title,
    subtitle,
    onClose,
    children,
}) => {
    const handleClose: DialogProps["onClose"] = () => {
        onClose();
    };

    return (
        <Dialog
            open={open}
            onClose={handleClose}
            fullWidth
            maxWidth={false}
            slotProps={{
                backdrop: { sx: { backgroundColor: "rgba(0, 0, 0, 0.48)" } },
                paper: {
                    sx: {
                        m: 0,
                        position: "fixed",
                        left: "50%",
                        top: "50%",
                        transform: "translate(-50%, -50%)",
                        width: "min(100%, 375px)",
                        maxHeight: "calc(100vh - 48px)",
                        borderRadius: "24px",
                        backgroundColor: "background.paper",
                        px: 2,
                        pt: 2,
                        pb: 2,
                        overflowY: "auto",
                    },
                },
            }}
        >
            <Stack sx={{ gap: 2.5 }}>
                <Stack direction="row" sx={{ justifyContent: "flex-end" }}>
                    <IconButton onClick={onClose} color="secondary">
                        <CloseIcon />
                    </IconButton>
                </Stack>
                <Stack sx={{ gap: 2 }}>
                    <Typography variant="h4" sx={{ wordBreak: "break-word" }}>
                        {title}
                    </Typography>
                    {subtitle && (
                        <Typography
                            variant="body"
                            sx={{
                                color: "text.muted",
                                wordBreak: "break-word",
                            }}
                        >
                            {subtitle}
                        </Typography>
                    )}
                </Stack>
                {children}
            </Stack>
        </Dialog>
    );
};
