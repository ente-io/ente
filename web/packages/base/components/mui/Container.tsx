import { styled } from "@mui/material";

/**
 * A flex child that fills the entire flex direction, and shows its children
 * after centering them both vertically and horizontally.
 */
export const CenteredBox = styled("div")`
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
`;
