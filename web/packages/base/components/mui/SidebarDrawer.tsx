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
> = (props) => (
    // MUI doesn't (currently, AFAIK) have support for nested drawers, so we
    // emulate that by showing a drawer atop another. To make it fit, we need to
    // modify two knobs:
    //
    // 1. Disable the transition (otherwise our nested drawer visibly slides in
    //    from the wrong direction).
    //
    // 2. Disable the backdrop (otherwise we'd end up with two of them - one
    //    from the original drawer, and one from this nested one).
    //
    <SidebarDrawer transitionDuration={0} hideBackdrop {...props} />
);
