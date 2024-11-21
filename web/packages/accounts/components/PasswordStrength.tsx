import { Typography } from "@mui/material";
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

    return (
        <Typography
            variant="small"
            sx={(theme) => ({
                mt: "8px",
                alignSelf: "flex-start",
                whiteSpace: "pre",
                color:
                    passwordStrength == "weak"
                        ? theme.colors.danger.A700
                        : passwordStrength == "moderate"
                          ? theme.colors.warning.A500
                          : theme.colors.accent.A500,
            })}
        >
            {password
                ? t("passphrase_strength", { context: passwordStrength })
                : /* empty space + white-space: pre to prevent layout shift. */
                  " "}
        </Typography>
    );
};
