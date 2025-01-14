import { Typography, useTheme } from "@mui/material";
import { t } from "i18next";
import React, { useMemo } from "react";
import { estimatePasswordStrength } from "../utils/password";

interface PasswordStrengthHintProps {
    password: string;
}

export const PasswordStrengthHint: React.FC<PasswordStrengthHintProps> = ({
    password,
}) => {
    const passwordStrength = useMemo(
        () => estimatePasswordStrength(password),
        [password],
    );

    const theme = useTheme();
    const color =
        passwordStrength == "weak"
            ? theme.colors.danger.A700
            : passwordStrength == "moderate"
              ? theme.colors.warning.A500
              : theme.colors.accent.A500;

    return (
        <Typography
            variant="small"
            sx={{
                mt: "8px",
                alignSelf: "flex-start",
                whiteSpace: "pre",
                color: "var(--color)",
            }}
            style={{ "--color": color } as React.CSSProperties}
        >
            {password
                ? t("passphrase_strength", { context: passwordStrength })
                : /* empty space + white-space: pre to prevent layout shift. */
                  " "}
        </Typography>
    );
};
