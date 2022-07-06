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
        <SpaceBetweenFlex mt={0.5} mb={1} pl={1.5}>
            <EnteLogo />
            <IconButton
                aria-label="close"
                onClick={closeSidebar}
                color="secondary">
                <CloseIcon fontSize="small" />
            </IconButton>
        </SpaceBetweenFlex>
    );
}
