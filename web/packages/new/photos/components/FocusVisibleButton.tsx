import { Button, styled } from "@mui/material";

/** A MUI {@link Button} that shows a keyboard focus indicator. */
export const FocusVisibleButton = styled(Button)`
    /* Show an outline when the button gains keyboard focus, e.g. when the user
       tabs to it. */
    &.Mui-focusVisible {
        outline: 1px solid #aaa;
    }
`;
