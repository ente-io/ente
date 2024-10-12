import ErrorOutline from "@mui/icons-material/ErrorOutline";
import {
    CircularProgress,
    Stack,
    Typography,
    type CircularProgressProps,
} from "@mui/material";
import { t } from "i18next";
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
            <Typography color="text.muted">{children}</Typography>
        </Stack>
    ) : (
        <CircularProgress color="accent" size={32} {...rest} />
    );

/**
 * An error message indicator, styled to complement {@link ActivityIndicator}.
 *
 * If a child is provided, it is used as the error message to show (after being
 * wrapped in a suitable {@link Typography}). Otherwise the default generic
 * error message is shown.
 */
export const ErrorIndicator: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <Stack sx={{ gap: 2, alignItems: "center" }}>
        <ErrorOutline color="secondary" sx={{ color: "critical" }} />
        <Typography color="text.muted">
            {children ?? t("generic_error")}
        </Typography>
    </Stack>
);
