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
    type ButtonProps,
    type TypographyProps,
} from "@mui/material";
import React from "react";

interface EnteMenuItemProps {
    onClick: () => void;
    color?: ButtonProps["color"];
    /**
     * - Variant "captioned": The {@link caption}) is shown alongside the main
     *   {@link label}, separated from it by a bullet.
     */
    variant?: "primary" | "captioned" | "toggle" | "secondary" | "mini";
    fontWeight?: TypographyProps["fontWeight"];
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
    checked?: boolean;
    labelComponent?: React.ReactNode;
    disabled?: boolean;
}

export const EnteMenuItem: React.FC<EnteMenuItemProps> = ({
    onClick,
    color = "primary",
    startIcon,
    endIcon,
    label,
    caption,
    checked,
    variant = "primary",
    fontWeight = "medium",
    labelComponent,
    disabled = false,
}) => {
    const handleButtonClick = () => {
        if (variant === "toggle") {
            return;
        }
        onClick();
    };

    const handleIconClick = () => {
        if (variant !== "toggle") {
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
                        backgroundColor: theme.colors.fill.faintPressed,
                    },
                    "& .MuiSvgIcon-root": {
                        fontSize: "20px",
                    },
                    p: 0,
                    borderRadius: "4px",
                }),
                variant !== "captioned" &&
                    ((theme) => ({
                        color: theme.palette[color].main,
                    })),
                variant !== "secondary" &&
                    variant !== "mini" &&
                    ((theme) => ({
                        backgroundColor: theme.colors.fill.faint,
                    })),
            ]}
        >
            <SpaceBetweenFlex sx={{ pl: "16px", pr: "12px" }}>
                <VerticallyCenteredFlex sx={{ py: "14px" }} gap={"10px"}>
                    {startIcon && startIcon}
                    <Box px={"2px"}>
                        {labelComponent ? (
                            labelComponent
                        ) : variant === "captioned" ? (
                            <CaptionedText
                                color={color}
                                mainText={labelOrDefault}
                                caption={caption}
                            />
                        ) : variant === "mini" ? (
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
                    {variant === "toggle" && (
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

interface CaptionedTextProps {
    mainText: string;
    caption?: React.ReactNode;
    color?: ButtonProps["color"];
}

const CaptionedText: React.FC<CaptionedTextProps> = ({
    mainText,
    caption,
    color,
}) => (
    <Stack direction="row" sx={{ gap: "4px", alignItems: "center" }}>
        <Typography>{mainText}</Typography>
        <CaptionTypography color={color}>{"•"}</CaptionTypography>
        <CaptionTypography color={color}>{caption}</CaptionTypography>
    </Stack>
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
