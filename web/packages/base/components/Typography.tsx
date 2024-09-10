import { styled, Typography } from "@mui/material";

/**
 * A variant of {@link Typography} that inserts ellipsis instead of wrapping the
 * text over multiple lines, or letting it overflow.
 *
 * Refs:
 * - https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_text/Wrapping_breaking_text
 * - https://developer.mozilla.org/en-US/docs/Web/CSS/white-space
 */
export const EllipsizedTypography = styled(Typography)`
    /* Initial value of overflow is visible. Set overflow (the handling of
      content that is too small for the container in the inline direction) to
      hidden instead. */
    overflow: hidden;
    /* Specify handling of text when it overflows, asking the browser to insert
       ellipsis instead of clipping. */
    text-overflow: ellipsis;
    /* Don't automatically wrap the text by inserting line breaks. */
    white-space: nowrap;
`;
