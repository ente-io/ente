import { Drawer, styled, type DrawerProps } from "@mui/material";
import type { ModalVisibilityProps } from "../utils/modal";

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

import { FlexWrapper } from "@ente/shared/components/Container";
import ArrowBack from "@mui/icons-material/ArrowBack";
import Close from "@mui/icons-material/Close";
import { Box, IconButton, Typography } from "@mui/material";
import React from "react";

type NestedSidebarDrawerTitlebarProps = Pick<
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
 * tandem with a {@link SidebarDrawer}.
 */
export const NestedSidebarDrawerTitlebar: React.FC<
    NestedSidebarDrawerTitlebarProps
> = ({ title, caption, onClose, onRootClose, actionButton }) => {
    return (
        <>
            <FlexWrapper
                height={48}
                alignItems={"center"}
                justifyContent="space-between"
            >
                <IconButton onClick={onClose} color={"primary"}>
                    <ArrowBack />
                </IconButton>
                <Box display={"flex"} gap="4px">
                    {actionButton && actionButton}
                    <IconButton onClick={onRootClose} color={"secondary"}>
                        <Close />
                    </IconButton>
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
