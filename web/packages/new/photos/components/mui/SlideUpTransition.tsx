import Slide from "@mui/material/Slide";
import type { TransitionProps } from "@mui/material/transitions";
import React, { forwardRef } from "react";

/**
 * A React component that can be passed as the {@link slots.transition} prop to
 * a MUI {@link Dialog} to get it to use a slide transition (by default, the
 * dialog does a fade transition).
 */
export const SlideUpTransition = forwardRef(function Transition(
    props: TransitionProps & { children: React.ReactElement },
    ref: React.Ref<unknown>,
) {
    return <Slide direction="up" ref={ref} {...props} />;
});
