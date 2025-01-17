import { Link, type ButtonProps, type LinkProps } from "@mui/material";
import React from "react";

export type LinkButtonProps = React.PropsWithChildren<{
    onClick: () => void;
    variant?: string;
    style?: React.CSSProperties;
}>;

const LinkButton: React.FC<
    LinkProps<"button", { color?: ButtonProps["color"] }>
> = ({ children, sx, color, ...props }) => {
    return (
        <Link
            component="button"
            sx={{
                color: "text.base",
                textDecoration: "underline rgba(255, 255, 255, 0.4)",
                "&:hover": {
                    color: `${color}.main`,
                    textDecoration: `underline `,
                    textDecorationColor: `${color}.main`,
                },
                ...sx,
            }}
            {...props}
        >
            {children}
        </Link>
    );
};

export default LinkButton;
