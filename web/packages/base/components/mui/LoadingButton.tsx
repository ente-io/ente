import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { CircularProgress, type ButtonProps } from "@mui/material";
import React from "react";

/**
 * A button that shows a indeterminate progress indicator if the {@link loading}
 * prop is set.
 *
 * The button is also disabled when in the loading state.
 *
 * TODO: This duplicates the existing SubmitButton. Merge these two gradually
 * (didn't want to break existing layouts, so will do it piecewise).
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
        // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
        disabled={loading || disabled}
        sx={{
            ...(loading
                ? {
                      "&.Mui-disabled": {
                          backgroundColor: `${color}.main`,
                          color: `${color}.contrastText`,
                      },
                  }
                : {}),
            ...sx,
        }}
        {...rest}
    >
        {loading ? <CircularProgress size={20} /> : children}
    </FocusVisibleButton>
);
