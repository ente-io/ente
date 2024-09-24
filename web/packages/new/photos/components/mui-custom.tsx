import { IconButton, styled } from "@mui/material";

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
