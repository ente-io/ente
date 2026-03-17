import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    Drawer,
    IconButton,
    Stack,
    styled,
    Typography,
    type DrawerProps,
} from "@mui/material";
import { isDesktop } from "ente-base/app";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import React from "react";

export const LockerSidebarDrawer: React.FC<DrawerProps> = ({
    slotProps,
    children,
    ...rest
}) => {
    const paperSlotProps =
        typeof slotProps?.paper === "function" ? undefined : slotProps?.paper;

    return (
        <Drawer
            {...rest}
            slotProps={{
                ...(slotProps ?? {}),
                paper: {
                    ...(paperSlotProps ?? {}),
                    sx: [
                        {
                            maxWidth: "375px",
                            width: "100%",
                            scrollbarWidth: "thin",
                            backgroundColor: "background.default",
                            "&&": { padding: 0 },
                        },
                        (theme) =>
                            theme.applyStyles("dark", {
                                backgroundColor:
                                    theme.vars.palette.background.paper,
                            }),
                        paperSlotProps?.sx as never,
                    ],
                },
            }}
        >
            {isDesktop && <LockerTitlebarBackdrop />}
            <Box sx={{ p: 1 }}>{children}</Box>
        </Drawer>
    );
};

const LockerTitlebarBackdrop = styled("div")(({ theme }) => ({
    position: "sticky",
    top: 0,
    left: 0,
    width: "100%",
    minHeight: "env(titlebar-area-height, 30px)",
    zIndex: 1,
    backgroundColor: theme.vars.palette.backdrop.muted,
    backdropFilter: "blur(12px)",
}));

export type LockerNestedSidebarDrawerVisibilityProps = ModalVisibilityProps & {
    onRootClose: () => void;
};

export const LockerNestedSidebarDrawer: React.FC<
    LockerNestedSidebarDrawerVisibilityProps & DrawerProps
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
        <LockerSidebarDrawer
            transitionDuration={0}
            slotProps={{
                backdrop: { sx: { "&&&": { backgroundColor: "transparent" } } },
            }}
            onClose={handleClose}
            {...rest}
        />
    );
};

type LockerSidebarTitlebarProps = Pick<
    LockerNestedSidebarDrawerVisibilityProps,
    "onClose" | "onRootClose"
> & {
    title: string;
    caption?: string;
    actionButton?: React.ReactNode;
    hideRootCloseButton?: boolean;
};

const LockerSidebarTitlebar: React.FC<LockerSidebarTitlebarProps> = ({
    title,
    caption,
    onClose,
    onRootClose,
    actionButton,
    hideRootCloseButton,
}) => (
    <Stack sx={{ gap: "4px" }}>
        <Stack direction="row" sx={{ justifyContent: "space-between" }}>
            <IconButton onClick={onClose} color="primary">
                <ArrowBackIcon />
            </IconButton>
            <Stack direction="row" sx={{ gap: "4px" }}>
                {actionButton && actionButton}
                {!hideRootCloseButton && (
                    <IconButton onClick={onRootClose} color="secondary">
                        <CloseIcon />
                    </IconButton>
                )}
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

type LockerTitledNestedSidebarDrawerProps = React.PropsWithChildren<
    LockerNestedSidebarDrawerVisibilityProps &
        Pick<DrawerProps, "anchor" | "slotProps"> &
        LockerSidebarTitlebarProps
>;

export const LockerTitledNestedSidebarDrawer: React.FC<
    LockerTitledNestedSidebarDrawerProps
> = ({ open, onClose, onRootClose, anchor, slotProps, children, ...rest }) => (
    <LockerNestedSidebarDrawer
        {...{ open, onClose, onRootClose, anchor, slotProps }}
    >
        <Stack sx={{ gap: "4px", py: "12px" }}>
            <LockerSidebarTitlebar {...{ onClose, onRootClose }} {...rest} />
            {children}
        </Stack>
    </LockerNestedSidebarDrawer>
);
