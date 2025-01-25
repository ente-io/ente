import { Switch, styled, type SwitchProps } from "@mui/material";
import React from "react";

/**
 * A custom variant of the MUI {@link Switch}, styled per our designs.
 */
export const EnteSwitch: React.FC<SwitchProps> = styled((props) => (
    <Switch disableRipple {...props} />
))(({ theme }) => ({
    width: 40,
    height: 24,
    padding: 0,
    "& .MuiSwitch-switchBase": {
        padding: 0,
        margin: 2,
        transitionDuration: "300ms",
        "&.Mui-checked": {
            transform: "translateX(16px)",
            color: theme.vars.palette.fixed.white,
            "& + .MuiSwitch-track": {
                opacity: 1,
                border: 0,
                // TODO(LM):
                // backgroundColor: "#65C466",
                // ...theme.applyStyles("dark", {
                //     backgroundColor: "#2ECA45",
                // }),
                backgroundColor: theme.vars.palette.fixed.switchOn,
            },
            "&.Mui-disabled + .MuiSwitch-track": {
                opacity: 0.5,
            },
        },
        "&.Mui-disabled .MuiSwitch-thumb": {
            color: theme.palette.grey[600],
            // TODO(LM):
            // ...theme.applyStyles("light", {
            //     color: theme.palette.grey[100],
            // }),
        },
        "&.Mui-disabled + .MuiSwitch-track": {
            opacity: 0.3,
            // TODO(LM):
            // ...theme.applyStyles("light", {
            //     opacity: 0.7,
            // }),
        },
    },
    "& .MuiSwitch-thumb": {
        boxSizing: "border-box",
        width: 20,
        height: 20,
    },
    "& .MuiSwitch-track": {
        borderRadius: 22 / 2,
        backgroundColor: theme.vars.palette.fill.muted,
        opacity: 1,
        transition: theme.transitions.create(["background-color"], {
            duration: 500,
        }),
        // TODO(LM):
        // ...theme.applyStyles("light", {
        //     backgroundColor: "#E9E9EA",
        // }),
    },
    // Use an alternative affordance to indicate focusVisible as the ripple
    // effect is disabled.
    ".MuiSwitch-switchBase.Mui-focusVisible + .MuiSwitch-track": {
        outline: `2px solid ${theme.vars.palette.stroke.muted}`,
        outlineOffset: "-2px",
    },
    // Same for when the switch is actived.
    ".MuiSwitch-switchBase:active + .MuiSwitch-track": {
        outline: `1px solid ${theme.vars.palette.stroke.faint}`,
        outlineOffset: "-1px",
    },
}));
