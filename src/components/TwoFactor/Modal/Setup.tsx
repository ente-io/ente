import React from 'react';
import LockIcon from '@mui/icons-material/Lock';
import { PAGES } from 'constants/pages';
import { useRouter } from 'next/router';
import constants from 'utils/strings/constants';
import Container from 'components/Container';
import { Button, Typography } from '@mui/material';

interface Iprops {
    closeSidebar: () => void;
}

export default function TwoFactorModalSetupSection({ closeSidebar }: Iprops) {
    const router = useRouter();
    const redirectToTwoFactorSetup = () => {
        closeSidebar();
        router.push(PAGES.TWO_FACTOR_SETUP);
    };

    return (
        <Container disableGutters sx={{ mb: 2 }}>
            <LockIcon sx={{ fontSize: (theme) => theme.spacing(5), mb: 2 }} />
            <Typography mb={2}>{constants.TWO_FACTOR_INFO}</Typography>
            <Button
                variant="contained"
                color="success"
                onClick={redirectToTwoFactorSetup}>
                {constants.ENABLE_TWO_FACTOR}
            </Button>
        </Container>
    );
}
