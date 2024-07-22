import { useMediaQuery, useTheme } from "@mui/material";

/**
 * Return true if the screen width is classified as a "mobile" size.
 *
 * We use the MUI "sm" (small, 600px) breakpoint as the cutoff. This hook will
 * return true if the size of the window's width is less than 600px.
 */
export const useIsMobileWidth = () =>
    useMediaQuery(useTheme().breakpoints.down("sm"));
