import { CircularProgress, type ButtonProps } from "@mui/material";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { isSxArray } from "ente-base/components/utils/sx";
import React from "react";

/**
 * A button that shows a indeterminate progress indicator if the {@link loading}
 * prop is set.
 *
 * The button is also disabled when in the loading state.
 */
export const LoadingButton: React.FC<ButtonProps & { loading?: boolean }> = ({
    loading,
    disabled,
    color,
    sx,
    children,
    ...rest
}) =>
    loading ? (
        <FocusVisibleButton
            {...{ color }}
            disabled
            sx={[
                {
                    "&.Mui-disabled": {
                        backgroundColor: `${color}.main`,
                        color: `${color}.contrastText`,
                    },
                },
                ...(sx ? (isSxArray(sx) ? sx : [sx]) : []),
            ]}
            {...rest}
        >
            <CircularProgress size={20} sx={{ color: "inherit" }} />
        </FocusVisibleButton>
    ) : (
        <FocusVisibleButton {...{ color, disabled, sx }} {...rest}>
            {children}
        </FocusVisibleButton>
    );
