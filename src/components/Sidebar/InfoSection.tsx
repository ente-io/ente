import React, { useState } from 'react';
import { Typography } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import ThemeToggler from './ThemeToggler';
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
        <SpaceBetweenFlex style={{ marginBottom: '20px' }}>
            <Typography pl="5px">{userDetails?.email}</Typography>
            <ThemeToggler theme={theme} setTheme={setTheme} />
        </SpaceBetweenFlex>
    );
}
