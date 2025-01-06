import {
    CircularProgress,
    Stack,
    Typography,
    type CircularProgressProps,
} from "@mui/material";
import type React from "react";

/**
 * A standard {@link CircularProgress} for use in our code.
 *
 * If a child is specified, it is wrapped in a Typography and shown as a caption
 * below the {@link CircularProgress}.
 *
 * While it does take and forward props to the the underlying
 * {@link CircularProgress}, if you find yourself needing to customize it too
 * much, consider directly using a {@link CircularProgress} instead.
 */
export const ActivityIndicator: React.FC<
    React.PropsWithChildren<CircularProgressProps>
> = ({ children, ...rest }) =>
    children ? (
        <Stack sx={{ gap: 2, alignItems: "center" }}>
            <CircularProgress color="accent" size={24} {...rest} />
            <Typography sx={{ color: "text.muted" }}>{children}</Typography>
        </Stack>
    ) : (
        <CircularProgress color="accent" size={32} {...rest} />
    );
