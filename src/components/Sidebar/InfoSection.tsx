import React, { useState } from 'react';
import { IconButton, Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import { SpaceBetweenFlex } from 'components/Container';
import SubscriptionDetails from './SubscriptionDetails';
import ThemeToggler from './ThemeToggler';
import { DividerWithMargin } from './styledComponents';
import { UserDetails } from 'types/user';
import CloseIcon from '@mui/icons-material/Close';

interface IProps {
    userDetails: UserDetails;
    closeSidebar: () => void;
}

export enum THEMES {
    LIGHT,
    DARK,
}

export default function InfoSection({ userDetails, closeSidebar }: IProps) {
    const [theme, setTheme] = useState<THEMES>(THEMES.DARK);

    return (
        <>
            <Typography variant="h6">
                <strong>{constants.ENTE}</strong>
            </Typography>
            <IconButton
                aria-label="close"
                onClick={closeSidebar}
                sx={{
                    position: 'absolute',
                    right: 16,
                    top: 16,
                    color: (theme) => theme.palette.grey[400],
                }}>
                <CloseIcon />
            </IconButton>
            <DividerWithMargin />

            <SpaceBetweenFlex style={{ marginBottom: '20px' }}>
                <Typography pl="5px">{userDetails?.email}</Typography>
                <ThemeToggler theme={theme} setTheme={setTheme} />
            </SpaceBetweenFlex>

            <SubscriptionDetails userDetails={userDetails} />
        </>
    );
}
