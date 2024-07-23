import { EnteSwitch } from "@/base/components/EnteSwitch";
import { CaptionedText } from "@ente/shared/components/CaptionedText";
import ChangeDirectoryOption from "@ente/shared/components/ChangeDirectoryOption";
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
    variant?:
        | "primary"
        | "captioned"
        | "toggle"
        | "secondary"
        | "mini"
        | "path";
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
    fontWeight = "bold",
    labelComponent,
    disabled = false,
}) => {
    const handleButtonClick = () => {
        if (variant === "path" || variant === "toggle") {
            return;
        }
        onClick();
    };

    const handleIconClick = () => {
        if (variant !== "path" && variant !== "toggle") {
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
            sx={{
                width: "100%",
                color: (theme) =>
                    variant !== "captioned"
                        ? theme.palette[color].main
                        : "inherit",
                backgroundColor: (theme) =>
                    variant !== "secondary" && variant !== "mini"
                        ? theme.colors.fill.faint
                        : "inherit",
                "&:hover": {
                    backgroundColor: (theme) => theme.colors.fill.faintPressed,
                },
                "& .MuiSvgIcon-root": {
                    fontSize: "20px",
                },
                p: 0,
                borderRadius: "4px",
            }}
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
                    {variant === "path" && (
                        <ChangeDirectoryOption onClick={handleIconClick} />
                    )}
                </VerticallyCenteredFlex>
            </SpaceBetweenFlex>
        </MenuItem>
    );
};
