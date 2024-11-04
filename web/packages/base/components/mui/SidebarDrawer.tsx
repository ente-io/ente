import { Drawer, styled } from "@mui/material";

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
