import { Stack, styled } from "@mui/material";

/**
 * A {@link Stack} that takes up at least the height of the entire viewport, and
 * centers its children both vertically and horizontally.
 */
export const Stack100vhCenter = styled(Stack)`
    min-height: 100vh;
    justify-content: center;
    align-items: center;
`;

/**
 * A flexbox with justify content set to space-between and item alignment set to
 * center.
 *
 * There is also another SpaceBetweenFlex in the old shared package, but that
 * one also sets width: 100%. As such, that one should be considered deprecated
 * and its uses moved to this one when possible (so that we can then see where
 * the width: 100% is essential).
 */
export const SpacedRow = styled("div")`
    display: flex;
    justify-content: space-between;
    align-items: center;
`;

/**
 * A flexbox that shows its children after centering them both vertically and
 * horizontally.
 */
export const CenteredRow = styled("div")`
    display: flex;
    justify-content: center;
    align-items: center;
`;

/**
 * A flexbox that fills the entire flex direction, and shows its children after
 * centering them both vertically and horizontally.
 */
export const CenteredFill = styled("div")`
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
`;

/**
 * An empty overlay on top of the nearest relative positioned ancestor.
 *
 * {@link Overlay} is an an absolute positioned div that fills the entire
 * nearest relatively positioned ancestor. It is usually used in tandem with a
 * derivate of {@link BaseTile} or {@link BaseTileButton} to show various
 * indicators on top of thumbnails; but it can be used in any context where we
 * want to overlay (usually) transparent content on top of a component.
 *
 * For filling much larger areas (e.g. showing a translucent overlay on top of
 * the entire screen), use the MUI {@link Backdrop} instead.
 */
export const Overlay = styled("div")`
    position: absolute;
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
`;
