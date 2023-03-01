import { Typography } from '@mui/material';
import { PasswordStrength } from 'constants/crypto';
import { useMemo } from 'react';
import { estimatePasswordStrength } from 'utils/crypto';
import constants from 'utils/strings/constants';
import { FlexWrapper } from './Container';

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
                variant="body2"
                sx={(theme) => ({
                    color:
                        passwordStrength === PasswordStrength.WEAK
                            ? theme.palette.danger.main
                            : passwordStrength === PasswordStrength.MODERATE
                            ? theme.palette.warning.main
                            : theme.palette.accent.main,
                })}
                textAlign={'left'}
                flex={1}>
                {password
                    ? constants.PASSPHRASE_STRENGTH(passwordStrength)
                    : ''}
            </Typography>
        </FlexWrapper>
    );
};
