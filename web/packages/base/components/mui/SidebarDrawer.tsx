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
import React from "react";
import type { ModalVisibilityProps } from "../utils/modal";
import { SpaceBetweenFlex } from "./Container";

/**
 * A MUI {@link Drawer} with a standard set of styling that we use for our left
 * and right sidebar panels.
 *
 * It is width limited to 375px, and always at full width. It also has a default
 * padding.
 */
export const SidebarDrawer = styled(Drawer)(({ theme }) => ({
    "& .MuiPaper-root": {
        maxWidth: "375px",
        width: "100%",
        scrollbarWidth: "thin",
        padding: theme.spacing(1),
    },
}));

/**
 * Common props for a {@link NestedSidebarDrawer} component. In addition to the
 * regular modal visibility controls for opening and closing itself, these also
 * surface an option to close the entire drawer.
 */
export type NestedSidebarDrawerVisibilityProps = ModalVisibilityProps & {
    /**
     * Called when the user wants to close the entire stack of drawers.
     *
     * Note that this does not automatically imply onClose. Each step in the
     * nesting will have to chain their own onCloses to construct a new
     * `onRootClose` suitable for passing to its children.
     */
    onRootClose: () => void;
};

/**
 * A variant of {@link SidebarDrawer} for second level, nested drawers that are
 * shown atop an already visible {@link SidebarDrawer}.
 */
export const NestedSidebarDrawer: React.FC<
    NestedSidebarDrawerVisibilityProps & DrawerProps
> = ({ onClose, onRootClose, ...rest }) => {
    // Intercept backdrop taps and repurpose them to close the entire stack.
    const handleClose: DrawerProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") {
            onClose();
            onRootClose();
        } else {
            onClose();
        }
    };

    // MUI doesn't (currently, AFAIK) have support for nested drawers, so we
    // emulate that by showing a drawer atop another. To make it fit, we need to
    // modify a few knobs.

    return (
        <SidebarDrawer
            // Disable the transition (otherwise our nested drawer visibly
            // slides in from the wrong direction).
            transitionDuration={0}
            // Make the backdrop transparent (otherwise we end up with two of
            // them - one from the original drawer, and one from this nested
            // one).
            //
            // Note that there is an easy way to hide the backdrop (using the
            // `hideBackdrop` attribute), but that takes away our ability to
            // intercept backdrop clicks to close it.
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
    /** Title for the drawer. */
    title: string;
    /** An optional secondary caption shown below the title. */
    caption?: string;
    /**
     * An optional action button shown alongwith the close button at the
     * trailing edge of the sidebar.
     */
    actionButton?: React.ReactNode;
};

/**
 * A bar with a title and back / close buttons, suitable for being used in
 * tandem with a {@link NestedSidebarDrawer}.
 */
export const SidebarDrawerTitlebar: React.FC<SidebarDrawerTitlebarProps> = ({
    title,
    caption,
    onClose,
    onRootClose,
    actionButton,
}) => (
    <Stack sx={{ gap: "4px" }}>
        <SpaceBetweenFlex sx={{ minHeight: "48px" }}>
            <IconButton onClick={onClose} color={"primary"}>
                <ArrowBackIcon />
            </IconButton>
            <Stack direction="row" sx={{ gap: "4px" }}>
                {actionButton && actionButton}
                <IconButton onClick={onRootClose} color={"secondary"}>
                    <CloseIcon />
                </IconButton>
            </Stack>
        </SpaceBetweenFlex>
        <Box sx={{ px: "16px", py: "4px" }}>
            <Typography variant="h3" sx={{ fontWeight: "medium" }}>
                {title}
            </Typography>
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
    </Stack>
);
