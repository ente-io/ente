import { estimatePasswordStrength } from "@/accounts/utils";
import { FlexWrapper } from "@ente/shared/components/Container";
import { Typography } from "@mui/material";
import { t } from "i18next";
import React, { useMemo } from "react";

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
        <FlexWrapper mt={"8px"} mb={"4px"}>
            <Typography
                variant="small"
                sx={(theme) => ({
                    color:
                        passwordStrength == "weak"
                            ? theme.colors.danger.A700
                            : passwordStrength == "moderate"
                              ? theme.colors.warning.A500
                              : theme.colors.accent.A500,
                })}
                textAlign={"left"}
                flex={1}
            >
                {password
                    ? t("passphrase_strength", { context: passwordStrength })
                    : ""}
            </Typography>
        </FlexWrapper>
    );
};
