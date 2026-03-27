import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    Drawer,
    IconButton,
    Stack,
    Typography,
    type DrawerProps,
} from "@mui/material";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import React from "react";

export const SidebarDrawer: React.FC<DrawerProps> = ({
    slotProps,
    children,
    ...rest
}) => (
    <Drawer
        {...rest}
        slotProps={{
            ...(slotProps ?? {}),
            paper: {
                sx: {
                    maxWidth: "375px",
                    width: "100%",
                    scrollbarWidth: "thin",
                    "&&": { padding: 0 },
                },
            },
        }}
    >
        <Box sx={{ p: 1 }}>{children}</Box>
    </Drawer>
);

export type NestedSidebarDrawerVisibilityProps = ModalVisibilityProps & {
    onRootClose: () => void;
};

export const NestedSidebarDrawer: React.FC<
    NestedSidebarDrawerVisibilityProps & DrawerProps
> = ({ onClose, onRootClose, ...rest }) => {
    const handleClose: DrawerProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") {
            onClose();
            onRootClose();
        } else {
            onClose();
        }
    };

    return (
        <SidebarDrawer
            transitionDuration={0}
            slotProps={{
                backdrop: { sx: { "&&&": { backgroundColor: "transparent" } } },
            }}
            onClose={handleClose}
            {...rest}
        />
    );
};

type SidebarDrawerTitlebarProps = Pick<
    NestedSidebarDrawerVisibilityProps,
    "onClose" | "onRootClose"
> & {
    title: string;
    caption?: string;
    actionButton?: React.ReactNode;
};

export const SidebarDrawerTitlebar: React.FC<SidebarDrawerTitlebarProps> = ({
    title,
    caption,
    onClose,
    onRootClose,
    actionButton,
}) => (
    <Stack sx={{ gap: "4px" }}>
        <Stack direction="row" sx={{ justifyContent: "space-between" }}>
            <IconButton onClick={onClose} color="primary">
                <ArrowBackIcon />
            </IconButton>
            <Stack direction="row" sx={{ gap: "4px" }}>
                {actionButton && actionButton}
                <IconButton onClick={onRootClose} color="secondary">
                    <CloseIcon />
                </IconButton>
            </Stack>
        </Stack>
        <Stack sx={{ px: "16px", gap: "4px" }}>
            <Typography variant="h3">{title}</Typography>
            <Typography
                variant="small"
                sx={{
                    color: "text.muted",
                    wordBreak: "break-all",
                    px: "1px",
                    minHeight: "17px",
                }}
            >
                {caption}
            </Typography>
        </Stack>
    </Stack>
);

export const TitledNestedSidebarDrawer: React.FC<
    React.PropsWithChildren<
        NestedSidebarDrawerVisibilityProps &
            Pick<DrawerProps, "anchor"> &
            SidebarDrawerTitlebarProps
    >
> = ({ open, onClose, onRootClose, anchor, children, ...rest }) => (
    <NestedSidebarDrawer {...{ open, onClose, onRootClose, anchor }}>
        <Stack sx={{ gap: "4px", py: "12px" }}>
            <SidebarDrawerTitlebar {...{ onClose, onRootClose }} {...rest} />
            {children}
        </Stack>
    </NestedSidebarDrawer>
);
