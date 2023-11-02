import { Typography } from '@mui/material';
import { PasswordStrength } from '@ente/accounts/constants';
import { useMemo } from 'react';
import { t } from 'i18next';
import { estimatePasswordStrength } from '@ente/accounts/utils';
import { FlexWrapper } from '@ente/shared/components/Container';

export const PasswordStrengthHint = ({
    password,
}: {
    password: string;
}): JSX.Element => {
    const passwordStrength = useMemo(
        () => estimatePasswordStrength(password),
        [password]
    );
    return (
        <FlexWrapper mt={'8px'} mb={'4px'}>
            <Typography
                variant="small"
                sx={(theme) => ({
                    color:
                        passwordStrength === PasswordStrength.WEAK
                            ? theme.colors.danger.A700
                            : passwordStrength === PasswordStrength.MODERATE
                            ? theme.colors.warning.A500
                            : theme.colors.accent.A500,
                })}
                textAlign={'left'}
                flex={1}>
                {password
                    ? t('PASSPHRASE_STRENGTH', { context: passwordStrength })
                    : ''}
            </Typography>
        </FlexWrapper>
    );
};
