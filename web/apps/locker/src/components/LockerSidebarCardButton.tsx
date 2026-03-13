import { HugeiconsIcon } from "@hugeicons/react";
import { Box, Stack, Typography } from "@mui/material";
import React from "react";

interface LockerSidebarCardButtonProps {
    icon?: React.ComponentProps<typeof HugeiconsIcon>["icon"];
    iconNode?: React.ReactNode;
    label: React.ReactNode;
    onClick: () => void;
    caption?: string;
    endIcon?: React.ReactNode;
    selected?: boolean;
    color?: string;
}

export const LockerSidebarCardButton: React.FC<
    LockerSidebarCardButtonProps
> = ({
    icon,
    iconNode,
    label,
    onClick,
    caption,
    endIcon,
    selected = false,
    color,
}) => (
    <Box
        component="button"
        type="button"
        onClick={onClick}
        sx={{
            width: "100%",
            p: 0,
            m: 0,
            border: 0,
            background: "transparent",
            textAlign: "inherit",
            cursor: "pointer",
            borderRadius: "20px",
        }}
    >
        <Stack
            direction="row"
            sx={(theme) => ({
                minHeight: 56,
                px: 2,
                gap: 1.5,
                alignItems: "center",
                borderRadius: "20px",
                backgroundColor: "backdrop.base",
                color: color ?? "text.base",
                transition: theme.transitions.create(
                    ["background-color", "border-color", "color"],
                    { duration: theme.transitions.duration.shorter },
                ),
                border: "1px solid transparent",
                ...(selected && {
                    boxShadow: `inset 0 0 0 1px ${theme.vars.palette.accent.main}`,
                    color: "accent.main",
                }),
                "&:hover": {
                    backgroundColor: "fill.faint",
                },
            })}
        >
            {iconNode ? (
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "inherit",
                    }}
                >
                    {iconNode}
                </Box>
            ) : icon ? (
                <HugeiconsIcon
                    icon={icon}
                    size={24}
                    color="currentColor"
                    strokeWidth={1.9}
                />
            ) : null}
            <Box sx={{ flex: 1, minWidth: 0 }}>
                {typeof label === "string" ? (
                    <Typography
                        variant="small"
                        sx={{
                            color: "inherit",
                            fontWeight: selected ? 700 : 500,
                        }}
                    >
                        {label}
                    </Typography>
                ) : (
                    label
                )}
            </Box>
            {caption && (
                <Typography
                    variant="mini"
                    sx={{
                        color: selected ? "accent.main" : "text.muted",
                        flexShrink: 0,
                    }}
                >
                    {caption}
                </Typography>
            )}
            {endIcon && (
                <Box sx={{ color: selected ? "accent.main" : "text.muted" }}>
                    {endIcon}
                </Box>
            )}
        </Stack>
    </Box>
);
