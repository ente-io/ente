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
 * A flexbox with justify content set to space-between and center alignment.
 *
 * There is also another SpaceBetweenFlex in the old shared package, but that
 * one also sets width: 100%. As such, that one should be considered deprecated
 * and its uses moved to this one when possible (so that we can then see where
 * the width: 100% is essential).
 */
export const SpaceBetweenFlex = styled("div")`
    display: flex;
    justify-content: space-between;
    align-items: center;
`;

/**
 * A flex child that fills the entire flex direction, and shows its children
 * after centering them both vertically and horizontally.
 */
export const CenteredFill = styled("div")`
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
`;

/**
 * An absolute positioned div that fills the entire nearest relatively
 * positioned ancestor.
 */
export const Overlay = styled("div")`
    position: absolute;
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
`;
