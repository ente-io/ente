import Slide from "@mui/material/Slide";
import type { TransitionProps } from "@mui/material/transitions";
import React from "react";

/**
 * A React component that can be passed as the `TransitionComponent` props to a
 * MUI {@link Dialog} to get it to use a slide transition (default is fade).
 */
export const SlideTransition = React.forwardRef(function Transition(
    props: TransitionProps & {
        children: React.ReactElement;
    },
    ref: React.Ref<unknown>,
) {
    return <Slide direction="up" ref={ref} {...props} />;
});
