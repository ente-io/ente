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
    variant?: "primary" | "captioned" | "toggle" | "secondary" | "mini";
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
    startIcon?: React.ReactNode;
    endIcon?: React.ReactNode;
    /**
     * One of {@link label} or {@link labelComponent} must be specified.
     * TODO: Try and reflect this is the type.
     */
    label?: string;
    /**
     * The text (or icon) to show alongside the {@link label} when the variant
     * is "captioned".
     *
     * This is usually expected to be a string and is wrapped in a Typography
     * component before being rendered. However, it can also be an SvgIcon (or
     * any an arbitrary component, though in terms of styling, only an SvgIcon
     * usually makes sense).
     */
    caption?: React.ReactNode;
    labelComponent?: React.ReactNode;
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
    labelComponent,
    disabled = false,
}) => {
    const handleButtonClick = () => {
        if (variant == "toggle") {
            return;
        }
        onClick();
    };

    const handleIconClick = () => {
        if (variant != "toggle") {
            return;
        }
        onClick();
    };

    const labelOrDefault = label ?? "";

    return (
        <MenuItem
            disabled={disabled}
            onClick={handleButtonClick}
            disableRipple={variant == "toggle"}
            sx={[
                (theme) => ({
                    width: "100%",
                    "&:hover": {
                        backgroundColor: theme.vars.palette.fill.faintHover,
                    },
                    "& .MuiSvgIcon-root": {
                        fontSize: "20px",
                    },
                    p: 0,
                    borderRadius: "4px",
                }),
                variant != "captioned" &&
                    ((theme) => ({
                        color: theme.vars.palette[color].main,
                    })),
                variant != "secondary" &&
                    variant != "mini" &&
                    ((theme) => ({
                        backgroundColor: theme.vars.palette.fill.faint,
                    })),
            ]}
        >
            <SpaceBetweenFlex sx={{ pl: "16px", pr: "12px" }}>
                <VerticallyCenteredFlex sx={{ py: "14px" }} gap={"10px"}>
                    {startIcon && startIcon}
                    <Box px={"2px"}>
                        {labelComponent ? (
                            labelComponent
                        ) : variant == "captioned" ? (
                            <Stack
                                direction="row"
                                sx={{ gap: "4px", alignItems: "center" }}
                            >
                                <Typography>{labelOrDefault}</Typography>
                                <CaptionTypography color={color}>
                                    {"•"}
                                </CaptionTypography>
                                <CaptionTypography color={color}>
                                    {caption}
                                </CaptionTypography>
                            </Stack>
                        ) : variant == "mini" ? (
                            <Typography variant="mini" color="text.muted">
                                {labelOrDefault}
                            </Typography>
                        ) : (
                            <Typography fontWeight={fontWeight}>
                                {labelOrDefault}
                            </Typography>
                        )}
                    </Box>
                </VerticallyCenteredFlex>
                <VerticallyCenteredFlex gap={"4px"}>
                    {endIcon && endIcon}
                    {variant == "toggle" && (
                        <EnteSwitch
                            checked={checked}
                            onClick={handleIconClick}
                        />
                    )}
                </VerticallyCenteredFlex>
            </SpaceBetweenFlex>
        </MenuItem>
    );
};

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
