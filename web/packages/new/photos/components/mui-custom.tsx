import { Box, IconButton, styled } from "@mui/material";

/**
 * Common props to control the display of a dialog-like component.
 */
export interface DialogVisiblityProps {
    /** If `true`, the dialog is shown. */
    open: boolean;
    /** Callback fired when the dialog wants to be closed. */
    onClose: () => void;
}

/**
 * A MUI {@link IconButton} filled in with at faint background.
 */
export const FilledIconButton = styled(IconButton)(({ theme }) => ({
    backgroundColor: theme.colors.fill.faint,
}));

/**
 * An "unstyled" button.
 *
 * There are cases where we semantically (and functionally) want a button, but
 * don't want the browser's default styling. This component is meant to act as a
 * base for such cases.
 *
 * Contrary to its name, it does add a bit of styling, to make these buttons fit
 * in with the rest of our theme.
 */
export const UnstyledButton = styled("button")`
    /* Reset some button defaults that are affecting us */
    background: transparent;
    border: 0;
    padding: 0;

    font: inherit;
    /* We customized the letter spacing in the theme. Need to tell the button to
       inherit that customization also. */
    letter-spacing: inherit;

    /* The button default is to show an flipped arrow. Show a hand instead. */
    cursor: pointer;
`;

/**
 * A flexbox with justify content set to space-between and center alignment.
 *
 * There is also another SpaceBetweenFlex in the old shared package, but that
 * one also sets width: 100%. As such, that one should be considered deprecated
 * and its uses moved to this one when possible (so that we can then see where
 * the width: 100% is essential).
 */
export const SpaceBetweenFlex = styled(Box)`
    display: flex;
    justify-content: space-between;
    align-items: center;
`;
