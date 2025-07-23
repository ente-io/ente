import { useTheme } from "@mui/material";
import React from "react";
import LoadingBar, { type LoadingBarRef } from "react-top-loading-bar";

interface ThemedLoadingBarProps {
    ref: React.Ref<LoadingBarRef>;
}
/**
 * A wrapper over the {@link LoadingBar} library component that sets it to use
 * the main accent color from the theme.
 */
export const ThemedLoadingBar: React.FC<ThemedLoadingBarProps> = ({ ref }) => {
    const theme = useTheme();

    return <LoadingBar color={theme.vars.palette.accent.main} ref={ref} />;
};
