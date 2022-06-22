import { IconButton } from '@mui/material';
import React from 'react';
import CloseIcon from '@mui/icons-material/Close';
import { SpaceBetweenFlex } from 'components/Container';
import { EnteLogo } from 'components/EnteLogo';

interface IProps {
    closeSidebar: () => void;
}

export default function HeaderSection({ closeSidebar }: IProps) {
    return (
        <SpaceBetweenFlex>
            <EnteLogo />
            <IconButton
                aria-label="close"
                onClick={closeSidebar}
                sx={{ color: 'stroke.secondary' }}>
                <CloseIcon fontSize="small" />
            </IconButton>
        </SpaceBetweenFlex>
    );
}
