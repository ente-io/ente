import { CircularProgress, type CircularProgressProps } from "@mui/material";
import type React from "react";

/**
 * A standard {@link CircularProgress} for use in our code.
 *
 * While it does take and forward props to the the underlying
 * {@link CircularProgress}, if you find yourself needing to customize it too
 * much, consider directly using a {@link CircularProgress} instead.
 */
export const ActivityIndicator: React.FC<CircularProgressProps> = (props) => (
    <CircularProgress color="accent" size={32} {...props} />
);
