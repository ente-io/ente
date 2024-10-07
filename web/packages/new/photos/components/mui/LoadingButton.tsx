import { CircularProgress, type ButtonProps } from "@mui/material";
import React from "react";
import { FocusVisibleButton } from "./FocusVisibleButton";

/**
 * A button that shows a indeterminate progress indicator if the {@link loading}
 * prop is set.
 *
 * The button is also disabled when in the loading state.
 *
 * TODO: This duplicates the existing SubmitButton and EnteButton. Merge these
 * three gradually (didn't want to break existing layouts, so will do it
 * piecewise).
 */
export const LoadingButton: React.FC<ButtonProps & { loading?: boolean }> = ({
    loading,
    disabled,
    color,
    sx,
    children,
    ...rest
}) => (
    <FocusVisibleButton
        {...{ color }}
        disabled={loading ?? disabled}
        sx={{
            "&.Mui-disabled": {
                backgroundColor: `${color}.main`,
                color: `${color}.contrastText`,
            },
            ...sx,
        }}
        {...rest}
    >
        {loading ? <CircularProgress size={20} /> : children}
    </FocusVisibleButton>
);
