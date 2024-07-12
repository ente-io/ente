import { FlexWrapper } from "@ente/shared/components/Container";
import ArrowBack from "@mui/icons-material/ArrowBack";
import Close from "@mui/icons-material/Close";
import { Box, IconButton, Typography } from "@mui/material";
import React from "react";

interface TitlebarProps {
    title: string;
    caption?: string;
    onClose: () => void;
    backIsClose?: boolean;
    onRootClose?: () => void;
    actionButton?: JSX.Element;
}

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
                    {backIsClose ? <Close /> : <ArrowBack />}
                </IconButton>
                <Box display={"flex"} gap="4px">
                    {actionButton && actionButton}
                    {!backIsClose && (
                        <IconButton onClick={onRootClose} color={"secondary"}>
                            <Close />
                        </IconButton>
                    )}
                </Box>
            </FlexWrapper>
            <Box py={0.5} px={2}>
                <Typography variant="h3" fontWeight={"bold"}>
                    {title}
                </Typography>
                <Typography
                    variant="small"
                    color="text.muted"
                    sx={{ wordBreak: "break-all", minHeight: "17px" }}
                >
                    {caption}
                </Typography>
            </Box>
        </>
    );
};
