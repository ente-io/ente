import { IconButton, styled } from "@mui/material";

/** Convenience typed props for a component that acts like a push button. */
export interface ButtonishProps {
    onClick: () => void;
}

/**
 * A MUI {@link IconButton} filled in with at faint background.
 */
export const FilledIconButton = styled(IconButton)(({ theme }) => ({
    backgroundColor: theme.colors.fill.faint,
}));
