import { EnteSwitch } from "@/base/components/EnteSwitch";
import {
    SpaceBetweenFlex,
    VerticallyCenteredFlex,
} from "@ente/shared/components/Container";
import {
    Box,
    MenuItem,
    Typography,
    type ButtonProps,
    type TypographyProps,
} from "@mui/material";
import React from "react";

interface EnteMenuItemProps {
    onClick: () => void;
    color?: ButtonProps["color"];
    variant?: "primary" | "captioned" | "toggle" | "secondary" | "mini";
    fontWeight?: TypographyProps["fontWeight"];
    startIcon?: React.ReactNode;
    endIcon?: React.ReactNode;
    /**
     * One of {@link label} or {@link labelComponent} must be specified.
     * TODO: Try and reflect this is the type.
     */
    label?: string;
    subText?: string;
    subIcon?: React.ReactNode;
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
    subText,
    subIcon,
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
                                subText={subText}
                                subIcon={subIcon}
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
    subText?: string;
    subIcon?: React.ReactNode;
    color?: ButtonProps["color"];
}

const CaptionedText: React.FC<CaptionedTextProps> = ({
    mainText,
    subText,
    subIcon,
    color,
}) => {
    const subTextColor = color == "critical" ? "critical.main" : "text.faint";
    return (
        <VerticallyCenteredFlex gap={"4px"}>
            <Typography>{mainText}</Typography>
            <Typography variant="small" sx={{ color: subTextColor }}>
                {"•"}
            </Typography>
            {subText ? (
                <Typography variant="small" sx={{ color: subTextColor }}>
                    {subText}
                </Typography>
            ) : (
                <Typography variant="small" sx={{ color: subTextColor }}>
                    {subIcon}
                </Typography>
            )}
        </VerticallyCenteredFlex>
    );
};
