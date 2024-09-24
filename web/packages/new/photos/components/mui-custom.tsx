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

    /* Button should do this for us (I think), but it isn't working for some
       reason I don't yet know (maybe something we customized in the theme?) */
    cursor: pointer;
`;
