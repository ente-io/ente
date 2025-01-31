import { FlexWrapper } from "@ente/shared/components/Container";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import CloseIcon from "@mui/icons-material/Close";
import { Box, IconButton, Stack, Typography } from "@mui/material";
import React from "react";

interface TitlebarProps {
    title: string;
    caption?: string;
    onClose: () => void;
    backIsClose?: boolean;
    onRootClose?: () => void;
    actionButton?: React.JSX.Element;
}

// TODO: Deprecated in favor of SidebarDrawerTitlebarProps where possible (will
// revisit the remaining use cases once those have migrated).
export const Titlebar: React.FC<TitlebarProps> = ({
    title,
    caption,
    onClose,
    backIsClose,
    actionButton,
    onRootClose,
}) => {
    return (
        <>
            <FlexWrapper
                height={48}
                alignItems={"center"}
                justifyContent="space-between"
            >
                <IconButton
                    onClick={onClose}
                    color={backIsClose ? "secondary" : "primary"}
                >
                    {backIsClose ? <CloseIcon /> : <ArrowBackIcon />}
                </IconButton>
                <Stack direction="row" sx={{ gap: "4px" }}>
                    {actionButton && actionButton}
                    {!backIsClose && (
                        <IconButton onClick={onRootClose} color="secondary">
                            <CloseIcon />
                        </IconButton>
                    )}
                </Stack>
            </FlexWrapper>
            <Box sx={{ py: 0.5, px: 2 }}>
                <Typography variant="h3">{title}</Typography>
                <Typography
                    variant="small"
                    sx={{
                        color: "text.muted",
                        wordBreak: "break-all",
                        minHeight: "17px",
                    }}
                >
                    {caption}
                </Typography>
            </Box>
        </>
    );
};
