import React, { useState } from 'react';
import { Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import { SpaceBetweenFlex } from 'components/Container';
import SubscriptionDetails from './SubscriptionDetails';
import ThemeToggler from './ThemeToggler';
import { DividerWithMargin } from './styledComponents';
import { UserDetails } from 'types/user';

interface IProps {
    userDetails: UserDetails;
}

export enum THEMES {
    LIGHT,
    DARK,
}

export default function InfoSection({ userDetails }: IProps) {
    const [theme, setTheme] = useState<THEMES>(THEMES.DARK);

    return (
        <>
            <Typography variant="h6" component={'strong'}>
                {constants.ENTE}
            </Typography>

            <DividerWithMargin />

            <SpaceBetweenFlex style={{ marginBottom: '20px' }}>
                <Typography pl="5px">{userDetails?.email}</Typography>
                <ThemeToggler theme={theme} setTheme={setTheme} />
            </SpaceBetweenFlex>

            <SubscriptionDetails userDetails={userDetails} />
        </>
    );
}
