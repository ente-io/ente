import React from 'react';
import LockIcon from '@mui/icons-material/Lock';
import { PAGES } from 'constants/pages';
import { useRouter } from 'next/router';
import constants from 'utils/strings/constants';
import VerticallyCentered from 'components/Container';
import { Button, Typography } from '@mui/material';

interface Iprops {
    closeDialog: () => void;
}

export default function TwoFactorModalSetupSection({ closeDialog }: Iprops) {
    const router = useRouter();
    const redirectToTwoFactorSetup = () => {
        closeDialog();
        router.push(PAGES.TWO_FACTOR_SETUP);
    };

    return (
        <VerticallyCentered sx={{ mb: 2 }}>
            <LockIcon sx={{ fontSize: (theme) => theme.spacing(5), mb: 2 }} />
            <Typography mb={4}>{constants.TWO_FACTOR_INFO}</Typography>
            <Button
                variant="contained"
                color="accent"
                size="large"
                onClick={redirectToTwoFactorSetup}>
                {constants.ENABLE_TWO_FACTOR}
            </Button>
        </VerticallyCentered>
    );
}
