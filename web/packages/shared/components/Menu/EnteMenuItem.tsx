import { EnteSwitch } from "@/base/components/EnteSwitch";
import {
    SpaceBetweenFlex,
    VerticallyCenteredFlex,
} from "@ente/shared/components/Container";
import {
    Box,
    MenuItem,
    Stack,
    Typography,
    type TypographyProps,
} from "@mui/material";
import React from "react";

interface EnteMenuItemProps {
    /**
     * Variants:
     *
     * - "primary" (default): A menu item with a filled in background color.
     *
     * - "captioned": A variant of primary with an associated {@link caption})
     *   shown alongside the main {@link label}, separated from it by a bullet.
     *
     * - "toggle": A variant of primary that shows a toggle button (an
     *   {@link EnteSwitch}) at the trailing edge of the menu item.
     *
     * - "secondary": A menu item without a fill.
     *
     * - "mini": A variant of secondary with a smaller font.
     */
    variant?: "primary" | "captioned" | "toggle" | "secondary";
    /**
     * Color of the menu item.
     *
     * Semantically, this is similar to the "color" props for a MUI button,
     * except we only support two cases for this menu item component:
     *
     * - "primary" (default): A menu item that uses "text.base" as the color of
     *   the text (and an approprite background color, if needed, based on the
     *   value of the "variant").
     *
     * - "critical": A menu item that uses "critical.main" as the color of the
     *   text. The background fill, if any, will be the same as color "primary".
     */
    color?: "primary" | "critical";
    fontWeight?: TypographyProps["fontWeight"];
    /**
     * Called when the menu item, or the switch it contains, is clicked.
     *
     * - For menu items with variant "toggle", this will be called if the user
     *   toggles the value of the {@link EnteSwitch}.
     *
     * - For all other variants, this will be called when the user activates
     *   (e.g. clicks) the menu item itself.
     */
    onClick: () => void;
    /**
     * The state of the toggle associated with the menu item.
     *
     * Only valid for menu items with variant "toggle".
     */
    checked?: boolean;
    /**
     * Optional icon shown at the leading edge of the menu item.
     *
     * This is usually an icon like an {@link SvgIcon}, but it can be any
     * arbitrary component, the menu item does not make any assumptions as to
     * what this is.
     *
     * If it is an {@link SvgIcon}, the menu item will size it appropriately.
     */
    startIcon?: React.ReactNode;
    /**
     * Optional icon shown at the trailing edge of the menu item.
     *
     * Similar to {@link startIcon} this can be any arbitrary component, though
     * usually it is an {@link SvgIcon} whose size the menu item will set.
     */
    endIcon?: React.ReactNode;
    /**
     * The label for the component.
     *
     * Usually this is expected to be a string, in which case it is wrapped up
     * in an appropriate {@link Typography} and shown on the menu item. But it
     * can be an arbitrary react component too, to allow customizing its
     * appearance or otherwise modifying it in one off cases (it will be used as
     * it is and not wrapped in a {@link Typography} if it is not a string).
     */
    label: React.ReactNode;
    /**
     * The text (or icon) to show alongside the {@link label} when the variant
     * is "captioned".
     *
     * This is usually expected to be a string, in which case it is wrapped in a
     * {@link Typography} component before being rendered. However, it can also
     * be an {@link SvgIcon} (or any an arbitrary component), though in terms of
     * styling, only an {@link SvgIcon} usually makes sense.
     *
     * Similar to {@link label}, it will not be wrapped in a  {@link Typography}
     * if it is not a string.
     */
    caption?: React.ReactNode;
    /**
     * If true, then the menu item will be disabled.
     */
    disabled?: boolean;
}

/**
 * A MUI {@link MenuItem} customized as per our designs and use cases.
 */
export const EnteMenuItem: React.FC<EnteMenuItemProps> = ({
    onClick,
    variant = "primary",
    color = "primary",
    fontWeight = "medium",
    checked,
    startIcon,
    endIcon,
    label,
    caption,
    disabled = false,
}) => (
    <MenuItem
        disabled={disabled}
        onClick={() => {
            if (variant != "toggle") onClick();
        }}
        disableRipple={variant == "toggle"}
        sx={[
            {
                // width: "100%",
                "& .MuiSvgIcon-root": {
                    fontSize: "20px",
                },
                p: 0,
                borderRadius: "4px",
            },
            variant != "captioned" &&
                ((theme) => ({
                    color: theme.vars.palette[color].main,
                })),
            variant == "secondary" &&
                ((theme) => ({
                    "&:hover": {
                        backgroundColor: theme.vars.palette.fill.faintHover,
                    },
                })),
            variant != "secondary" &&
                ((theme) => ({
                    backgroundColor: theme.vars.palette.fill.faint,
                    "&:hover": {
                        backgroundColor: theme.vars.palette.fill.muted,
                    },
                })),
        ]}
    >
        <SpaceBetweenFlex sx={{ pl: "16px", pr: "12px" }}>
            <VerticallyCenteredFlex sx={{ py: "14px" }} gap={"10px"}>
                {startIcon && startIcon}
                <Box px={"2px"}>
                    {typeof label !== "string" ? (
                        label
                    ) : variant == "captioned" ? (
                        <Stack
                            direction="row"
                            sx={{ gap: "4px", alignItems: "center" }}
                        >
                            <Typography>{label}</Typography>
                            <CaptionTypography color={color}>
                                {"•"}
                            </CaptionTypography>
                            <CaptionTypography color={color}>
                                {caption}
                            </CaptionTypography>
                        </Stack>
                    ) : (
                        <Typography fontWeight={fontWeight}>{label}</Typography>
                    )}
                </Box>
            </VerticallyCenteredFlex>
            <VerticallyCenteredFlex gap={"4px"}>
                {endIcon && endIcon}
                {variant == "toggle" && (
                    <EnteSwitch {...{ checked, onClick }} />
                )}
            </VerticallyCenteredFlex>
        </SpaceBetweenFlex>
    </MenuItem>
);

const CaptionTypography: React.FC<
    React.PropsWithChildren<{ color: EnteMenuItemProps["color"] }>
> = ({ color, children }) => (
    <Typography
        variant="small"
        sx={[
            color == "critical"
                ? { color: "critical.main" }
                : { color: "text.faint" },
        ]}
    >
        {children}
    </Typography>
);
