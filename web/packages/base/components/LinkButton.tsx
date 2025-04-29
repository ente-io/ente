import { Link, type ButtonProps } from "@mui/material";
import React from "react";

/**
 * A button that looks like a link.
 *
 * The use of this component is not encouraged. It is only useful in uncommon
 * cases where we do not have sufficient space to include a proper button.
 */
export const LinkButton: React.FC<
    React.PropsWithChildren<Pick<ButtonProps, "onClick">>
> = ({ onClick, children }) => (
    <Link
        component="button"
        sx={(theme) => ({
            color: "text.base",
            textDecoration: "underline",
            // The shortcut "text.faint" does not work with textDecorationColor
            // (as of MUI v6).
            textDecorationColor: theme.vars.palette.text.faint,
            "&:hover": {
                color: "accent.main",
                textDecoration: "underline",
                textDecorationColor: "accent.main",
            },
        })}
        {...{ onClick }}
    >
        {children}
    </Link>
);

/**
 * A variant of {@link LinkButton} that does not show an underline, and instead
 * uses a bolder font weight to indicate clickability.
 *
 * Similar caveats as {@link LinkButton} apply.
 */
export const LinkButtonUndecorated: React.FC<
    React.PropsWithChildren<Pick<ButtonProps, "onClick">>
> = ({ onClick, children }) => (
    <Link
        component="button"
        sx={{
            textDecoration: "none",
            color: "text.muted",
            fontWeight: "medium",
            "&:hover": { color: "accent.main" },
        }}
        {...{ onClick }}
    >
        {children}
    </Link>
);
